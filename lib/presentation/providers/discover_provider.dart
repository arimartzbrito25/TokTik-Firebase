import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';

class DiscoverProvider extends ChangeNotifier {
  bool initialLoading = true;
  List<VideoPost> _remoteVideos = [];
  final List<VideoPost> _localVideos = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<VideoPost> get videos => [..._localVideos, ..._remoteVideos];

  Future<void> loadNextPage() async {
    await _subscription?.cancel();

    initialLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('videos')
        .snapshots()
        .listen(
      (snapshot) {
        _remoteVideos = snapshot.docs.map((doc) {
          final data = doc.data();

          return VideoPost(
            id: doc.id,
            caption: data['description'] ?? 'Sin descripción',
            videoUrl: data['videoUrl'] ?? '',
            mediaType: data['mediaType'] ?? 'video',
            filterName: data['filterName'] ?? 'original',
            views: (data['views'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        initialLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error al cargar videos: $error');
        initialLoading = false;
        if (videos.isEmpty) {
          seedLocalDemoVideos();
        } else {
          notifyListeners();
        }
      },
    );
  }

  /// Publica en el feed de esta sesión (no necesita Storage ni write en Firestore).
  void addLocalPost({
    required String mediaUrl,
    required String description,
    required bool isVideo,
    String filterName = 'original',
    String? userId,
  }) {
    final post = VideoPost(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      caption: description.trim().isEmpty ? 'Sin descripción' : description.trim(),
      videoUrl: mediaUrl,
      mediaType: isVideo ? 'video' : 'image',
      filterName: filterName,
      views: 0,
    );
    _localVideos.insert(0, post);
    initialLoading = false;
    notifyListeners();
  }

  int seedLocalDemoVideos() {
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
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        description: 'Demo · Escapes',
      ),
    ];

    for (final sample in samples) {
      addLocalPost(
        mediaUrl: sample.url,
        description: sample.description,
        isVideo: true,
      );
    }
    return samples.length;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
