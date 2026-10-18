import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const MediaPreviewScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(File(widget.filePath));
    _videoController = controller;
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) return;
    setState(() => _isVideoReady = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isVideo ? 'Vista previa del video' : 'Vista previa de la foto'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: widget.isVideo ? _buildVideoPreview() : _buildPhotoPreview(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  Text(
                    widget.filePath,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Volver a capturar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.isVideo
                                      ? 'Video guardado correctamente'
                                      : 'Foto guardada correctamente',
                                ),
                              ),
                            );
                            Navigator.of(context).pop();
                            Navigator.of(context).pop(widget.filePath);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Usar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return InteractiveViewer(
      child: Image.file(
        File(widget.filePath),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoReady || _videoController == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          Positioned(
            bottom: 12,
            child: IconButton(
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              icon: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
