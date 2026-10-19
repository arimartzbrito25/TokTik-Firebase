import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';

class DiscoverProvider extends ChangeNotifier {
  bool initialLoading = true;
  List<VideoPost> videos = <VideoPost>[];
  bool _didSeedLocalDemos = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  Future<void> loadNextPage() async {
    await _subscription?.cancel();

    initialLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('videos')
        .snapshots()
        .listen(
      (snapshot) {
        final remote = <VideoPost>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          remote.add(
            VideoPost(
              id: doc.id,
              caption: data['description'] ?? 'Sin descripción',
              videoUrl: data['videoUrl'] ?? '',
              mediaType: data['mediaType'] ?? 'video',
              filterName: data['filterName'] ?? 'original',
              views: (data['views'] as num?)?.toInt() ?? 0,
            ),
          );
        }

        final locals = <VideoPost>[];
        for (final post in videos) {
          if (post.id.startsWith('local_') || post.id.startsWith('demo_')) {
            locals.add(post);
          }
        }

        videos = <VideoPost>[];
        videos.addAll(locals);
        videos.addAll(remote);
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

  /// Publica en el feed de esta sesión (sin Storage / sin write en Firestore).
  void addLocalPost({
    required String mediaUrl,
    required String description,
    required bool isVideo,
    String filterName = 'original',
  }) {
    final post = VideoPost(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      caption:
          description.trim().isEmpty ? 'Sin descripción' : description.trim(),
      videoUrl: mediaUrl,
      mediaType: isVideo ? 'video' : 'image',
      filterName: filterName,
      views: 0,
    );
    final next = <VideoPost>[post];
    next.addAll(videos);
    videos = next;
    initialLoading = false;
    notifyListeners();
  }

  int seedLocalDemoVideos() {
    if (_didSeedLocalDemos && videos.isNotEmpty) {
      return videos.length;
    }

    final demos = <VideoPost>[
      VideoPost(
        id: 'demo_bee',
        caption: 'Demo · Abeja',
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      ),
      VideoPost(
        id: 'demo_butterfly',
        caption: 'Demo · Mariposa',
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      ),
      VideoPost(
        id: 'demo_blazes',
        caption: 'Demo · Blazes',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      ),
    ];

    videos = <VideoPost>[];
    videos.addAll(demos);
    _didSeedLocalDemos = true;
    initialLoading = false;
    notifyListeners();
    return demos.length;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
