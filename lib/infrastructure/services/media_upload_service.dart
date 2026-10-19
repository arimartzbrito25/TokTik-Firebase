import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Sube fotos/videos a Firebase Storage y registra el post en Firestore.
class MediaUploadService {
  MediaUploadService({
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<String> uploadMedia({
    required XFile file,
    required String description,
    required bool isVideo,
    String filterName = 'original',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesión para publicar.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('El archivo seleccionado está vacío.');
    }

    final originalName = file.name;
    final extension = _extensionOf(originalName, file.path, isVideo);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.$extension';
    final storagePath = 'uploads/${user.uid}/$fileName';

    final ref = _storage.ref(storagePath);
    final contentType = isVideo
        ? (extension == 'mov' ? 'video/quicktime' : 'video/mp4')
        : (extension == 'png' ? 'image/png' : 'image/jpeg');

    try {
      await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
    } on FirebaseException catch (e) {
      throw StateError(
        'No se pudo subir a Storage (${e.code}). '
        'Sin plan Blaze o sin rules, usa "Publicar con enlace" en Crear.',
      );
    }

    final downloadUrl = await ref.getDownloadURL();
    await savePostToFirestore(
      mediaUrl: downloadUrl,
      description: description,
      isVideo: isVideo,
      filterName: filterName,
    );
    return downloadUrl;
  }

  /// Publica solo con URL (no necesita Firebase Storage).
  Future<void> publishFromUrl({
    required String mediaUrl,
    required String description,
    required bool isVideo,
    String filterName = 'original',
  }) async {
    final url = mediaUrl.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      throw StateError('Pega una URL válida que empiece con https://');
    }

    await savePostToFirestore(
      mediaUrl: url,
      description: description,
      isVideo: isVideo,
      filterName: filterName,
    );
  }

  /// Carga videos de ejemplo públicos en Firestore (para demo sin Storage).
  Future<int> seedSampleVideos() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesión.');
    }

    const samples = [
      (
        url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        description: 'Demo · Abeja',
      ),
      (
        url:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        description: 'Demo · Mariposa',
      ),
      (
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        description: 'Demo · Escapes',
      ),
    ];

    for (final sample in samples) {
      await savePostToFirestore(
        mediaUrl: sample.url,
        description: sample.description,
        isVideo: true,
        filterName: 'original',
      );
    }
    return samples.length;
  }

  Future<void> savePostToFirestore({
    required String mediaUrl,
    required String description,
    required bool isVideo,
    String filterName = 'original',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesión para publicar.');
    }

    await _firestore.collection('videos').add({
      'description': description.trim().isEmpty
          ? 'Sin descripción'
          : description.trim(),
      'videoUrl': mediaUrl,
      'mediaType': isVideo ? 'video' : 'image',
      'filterName': filterName,
      'views': 0,
      'userId': user.uid,
      'userEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _extensionOf(String name, String path, bool isVideo) {
    String from(String value) {
      final dot = value.lastIndexOf('.');
      if (dot == -1 || dot == value.length - 1) return '';
      return value.substring(dot + 1).toLowerCase().split('?').first;
    }

    final fromName = from(name);
    if (fromName.isNotEmpty && fromName.length <= 5) return fromName;

    final fromPath = from(path);
    if (fromPath.isNotEmpty && fromPath.length <= 5) return fromPath;

    return isVideo ? 'mp4' : 'jpg';
  }
}
