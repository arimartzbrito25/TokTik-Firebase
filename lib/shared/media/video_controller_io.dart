import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createLocalVideoController(String path) {
  if (path.startsWith('blob:') ||
      path.startsWith('http://') ||
      path.startsWith('https://')) {
    return VideoPlayerController.networkUrl(Uri.parse(path));
  }
  return VideoPlayerController.file(File(path));
}
