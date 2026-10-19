import 'package:video_player/video_player.dart';

VideoPlayerController createLocalVideoController(String path) {
  return VideoPlayerController.networkUrl(Uri.parse(path));
}
