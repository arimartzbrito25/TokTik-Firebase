import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/presentation/screens/create/media_filter_screen.dart';
import 'package:toktok/shared/media/media_helpers.dart';
import 'package:video_player/video_player.dart';

/// Selección de imagen/video desde la galería.
class GalleryUploadScreen extends StatefulWidget {
  const GalleryUploadScreen({super.key});

  @override
  State<GalleryUploadScreen> createState() => _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selected;
  Uint8List? _imageBytes;
  bool _isVideo = false;
  bool _isPicking = false;
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  Future<void> _pick({required bool video}) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final file = video
          ? await _picker.pickVideo(source: ImageSource.gallery)
          : await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 90,
            );

      if (file == null) return;

      await _videoController?.dispose();
      _videoController = null;

      setState(() {
        _selected = file;
        _isVideo = video;
        _imageBytes = null;
        _videoReady = false;
      });

      if (video) {
        final controller = buildLocalVideoController(file.path);
        _videoController = controller;
        await controller.initialize();
        await controller.setLooping(true);
        await controller.play();
        if (!mounted) return;
        setState(() => _videoReady = true);
      } else {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la galería: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _continueToFilters() async {
    final selected = _selected;
    if (selected == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaFilterScreen(
          file: selected,
          isVideo: _isVideo,
          previewBytes: _imageBytes,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111512),
        foregroundColor: Colors.white,
        title: const Text('Subir desde galería'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPicking ? null : () => _pick(video: false),
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Imagen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPicking ? null : () => _pick(video: true),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Video'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B201D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isPicking
                        ? const CircularProgressIndicator()
                        : selected == null
                            ? const Text(
                                'Elige una imagen o un video\nde tu galería',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              )
                            : _isVideo
                                ? _buildVideoPreview()
                                : InteractiveViewer(
                                    child: LocalImage(
                                      bytes: _imageBytes,
                                      path: selected.path,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected == null ? null : _continueToFilters,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continuar a filtros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = _videoController;
    if (!_videoReady || controller == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
