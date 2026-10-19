import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/presentation/screens/create/publish_screen.dart';
import 'package:toktok/shared/media/media_filter_presets.dart';
import 'package:toktok/shared/media/media_helpers.dart';
import 'package:video_player/video_player.dart';

/// Elige filtro antes de publicar (imagen o video).
class MediaFilterScreen extends StatefulWidget {
  final XFile? file;
  final String? remoteUrl;
  final bool isVideo;
  final Uint8List? previewBytes;

  const MediaFilterScreen({
    super.key,
    this.file,
    this.remoteUrl,
    required this.isVideo,
    this.previewBytes,
  }) : assert(file != null || remoteUrl != null);

  @override
  State<MediaFilterScreen> createState() => _MediaFilterScreenState();
}

class _MediaFilterScreenState extends State<MediaFilterScreen> {
  MediaFilterPreset _filter = MediaFilterPreset.original;
  VideoPlayerController? _videoController;
  Uint8List? _imageBytes;
  bool _ready = false;

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
      setState(() {
        _imageBytes = widget.previewBytes;
        _ready = true;
      });
      return;
    }
    if (widget.file != null) {
      final bytes = await widget.file!.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _ready = true;
      });
    } else {
      setState(() => _ready = true);
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
    setState(() => _ready = true);
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishScreen(
          file: widget.file,
          remoteUrl: widget.remoteUrl,
          isVideo: widget.isVideo,
          previewBytes: _imageBytes ?? widget.previewBytes,
          filterName: _filter.id,
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isVideo ? 'Filtro de video' : 'Filtro de imagen'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_ready
                  ? const Center(child: CircularProgressIndicator())
                  : Center(child: _buildPreview()),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: MediaFilterPreset.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = MediaFilterPreset.values[index];
                  final selected = preset == _filter;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = preset),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFFFC857)
                                  : Colors.white24,
                              width: selected ? 2 : 1,
                            ),
                            color: Colors.white10,
                          ),
                          child: Icon(
                            preset.icon,
                            color: selected
                                ? const Color(0xFFFFC857)
                                : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          preset.label,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFFFC857)
                                : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continuar a publicar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final filtered = ColorFiltered(
      colorFilter: ColorFilter.matrix(_filter.matrix),
      child: widget.isVideo ? _videoLayer() : _imageLayer(),
    );

    final frame = _filter.frameAsset;
    if (frame == null) return filtered;

    return Stack(
      fit: StackFit.passthrough,
      alignment: Alignment.center,
      children: [
        filtered,
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(frame, fit: BoxFit.fill),
          ),
        ),
      ],
    );
  }

  Widget _imageLayer() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.contain);
    }
    if (widget.remoteUrl != null) {
      return Image.network(widget.remoteUrl!, fit: BoxFit.contain);
    }
    return const Icon(Icons.image, color: Colors.white54, size: 64);
  }

  Widget _videoLayer() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
