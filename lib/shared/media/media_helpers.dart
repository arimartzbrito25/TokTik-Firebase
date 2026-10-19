import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/shared/media/video_controller_stub.dart'
    if (dart.library.io) 'package:toktok/shared/media/video_controller_io.dart'
    as video_ctrl;
import 'package:video_player/video_player.dart';

export 'package:toktok/shared/media/video_controller_stub.dart'
    if (dart.library.io) 'package:toktok/shared/media/video_controller_io.dart'
    show createLocalVideoController;

VideoPlayerController buildLocalVideoController(String path) {
  return video_ctrl.createLocalVideoController(path);
}

/// Vista de imagen local que funciona en web y móvil.
class LocalImage extends StatelessWidget {
  final Uint8List? bytes;
  final String? path;
  final BoxFit fit;

  const LocalImage({
    super.key,
    this.bytes,
    this.path,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: fit);
    }

    final mediaPath = path;
    if (mediaPath == null || mediaPath.isEmpty) {
      return const Icon(Icons.broken_image, color: Colors.white54, size: 48);
    }

    if (kIsWeb ||
        mediaPath.startsWith('blob:') ||
        mediaPath.startsWith('http')) {
      return Image.network(mediaPath, fit: fit);
    }

    // En plataformas con File, Image.network con file:// suele fallar;
    // preferimos bytes. Si solo hay path, intentamos network file URI.
    return Image.network(Uri.file(mediaPath).toString(), fit: fit);
  }
}

Future<Uint8List> readXFileBytes(XFile file) => file.readAsBytes();
