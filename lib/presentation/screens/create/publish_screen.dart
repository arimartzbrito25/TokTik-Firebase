import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toktok/infrastructure/services/media_upload_service.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/images/face_accessory.dart';
import 'package:toktok/presentation/widgets/media/face_filtered_image.dart';
import 'package:toktok/shared/media/media_filter_presets.dart';
import 'package:toktok/shared/media/media_helpers.dart';
import 'package:video_player/video_player.dart';

/// Pantalla final de publicación (descripción + upload / URL / local).
class PublishScreen extends StatefulWidget {
  final XFile? file;
  final String? remoteUrl;
  final bool isVideo;
  final Uint8List? previewBytes;
  final String filterName;

  const PublishScreen({
    super.key,
    this.file,
    this.remoteUrl,
    required this.isVideo,
    this.previewBytes,
    this.filterName = 'original',
  }) : assert(file != null || remoteUrl != null);

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _descriptionController = TextEditingController();
  final _uploadService = MediaUploadService();
  VideoPlayerController? _videoController;
  Uint8List? _imageBytes;
  bool _videoReady = false;
  bool _isUploading = false;
  double _progress = 0;

  MediaFilterPreset get _filter => MediaFilterPreset.fromId(widget.filterName);
  AppliedFilter get _applied => AppliedFilter.parse(widget.filterName);
  FaceLook? get _faceLook => FaceLooks.byId(_applied.faceLookId);

  bool get _isUrlOnly => widget.remoteUrl != null && widget.file == null;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _initVideo();
    } else {
      _initImage();
    }
  }

  Future<void> _initImage() async {
    if (widget.previewBytes != null) {
      setState(() => _imageBytes = widget.previewBytes);
      return;
    }
    if (widget.file != null) {
      final bytes = await widget.file!.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _initVideo() async {
    final path = widget.file?.path ?? widget.remoteUrl!;
    final controller = buildLocalVideoController(path);
    _videoController = controller;
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) return;
    setState(() => _videoReady = true);
  }

  void _publishLocal(String mediaUrl) {
    context.read<DiscoverProvider>().addLocalPost(
          mediaUrl: mediaUrl,
          description: _descriptionController.text,
          isVideo: widget.isVideo,
          filterName: widget.filterName,
        );
  }

  Future<void> _publish() async {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _progress = 0.15;
    });

    try {
      setState(() => _progress = 0.45);

      if (_isUrlOnly) {
        final url = widget.remoteUrl!;
        try {
          await _uploadService.publishFromUrl(
            mediaUrl: url,
            description: _descriptionController.text,
            isVideo: widget.isVideo,
            filterName: widget.filterName,
          );
        } catch (_) {
          if (!mounted) return;
          // Firestore bloqueado: igual sale en el feed de esta sesión.
          _publishLocal(url);
        }
      } else {
        try {
          await _uploadService.uploadMedia(
            file: widget.file!,
            description: _descriptionController.text,
            isVideo: widget.isVideo,
            filterName: widget.filterName,
          );
        } catch (e) {
          if (!mounted) return;
          // Sin Storage: publica en el feed local de la sesión.
          final localPath = widget.file!.path;
          if (localPath.startsWith('blob:') ||
              localPath.startsWith('http') ||
              !kIsWeb) {
            _publishLocal(localPath);
          } else {
            rethrow;
          }
        }
      }

      setState(() => _progress = 1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicado! Ya aparece en el feed.')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111512),
        foregroundColor: Colors.white,
        title: const Text('Publicar'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AspectRatio(
              aspectRatio: 9 / 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildPreview(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filtro: ${_filter.label}'
              '${_faceLook != null ? ' · Rostro: ${_faceLook!.label}' : ''}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 120,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Cuenta algo sobre tu post…',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
              ),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              const Text(
                'Publicando…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isUploading ? null : _publish,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_isUploading ? 'Publicando…' : 'Publicar en TokTik'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (!widget.isVideo && _faceLook != null) {
      final preview = FaceFilteredImage(
        bytes: _imageBytes,
        sourcePath: widget.file?.path ?? widget.remoteUrl,
        look: _faceLook,
        colorMatrix: _filter.matrix,
        fit: BoxFit.cover,
        initialShift: Offset(_applied.shiftX, _applied.shiftY),
        initialScale: _applied.scale,
      );
      final frame = _filter.frameAsset;
      if (frame == null) return preview;
      return Stack(
        fit: StackFit.expand,
        children: [
          preview,
          IgnorePointer(child: Image.asset(frame, fit: BoxFit.fill)),
        ],
      );
    }

    final child = widget.isVideo
        ? _buildVideo()
        : LocalImage(
            bytes: _imageBytes,
            path: widget.file?.path ?? widget.remoteUrl,
            fit: BoxFit.cover,
          );

    final filtered = ColorFiltered(
      colorFilter: ColorFilter.matrix(_filter.matrix),
      child: child,
    );

    final frame = _filter.frameAsset;
    if (frame == null) return filtered;

    return Stack(
      fit: StackFit.expand,
      children: [
        filtered,
        IgnorePointer(child: Image.asset(frame, fit: BoxFit.fill)),
      ],
    );
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (!_videoReady || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
