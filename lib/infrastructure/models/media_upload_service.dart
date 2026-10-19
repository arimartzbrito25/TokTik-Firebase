import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MediaUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromGallery({required bool isVideo}) async {
    if (isVideo) {
      return await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      return await _picker.pickImage(source: ImageSource.gallery);
    }
  }

  Future<String?> uploadToStorage(File file, String folder) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference ref = _storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error al subir a Firebase Storage: $e');
      return null;
    }
  }

  Future<void> savePostToFirestore({
    required String mediaUrl,
    required String caption,
    required bool isVideo,
  }) async {
    await _firestore.collection('posts').add({
      'videoUrl': isVideo ? mediaUrl : '',
      'imageUrl': !isVideo ? mediaUrl : '',
      'caption': caption,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}