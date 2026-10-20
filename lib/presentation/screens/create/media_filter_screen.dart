import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/presentation/screens/create/publish_screen.dart';
import 'package:toktok/presentation/screens/images/face_accessory.dart';
import 'package:toktok/presentation/widgets/media/face_filtered_image.dart';
import 'package:toktok/shared/media/media_filter_presets.dart';
import 'package:toktok/shared/media/media_helpers.dart';
import 'package:video_player/video_player.dart';

/// Elige filtros (rostro + color) antes de publicar.
/// La usan Cámara y Galería, así ambas tienen los mismos filtros
/// que la pantalla de Filtros de imagen.
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
  FaceLook? _look;
  Offset _faceShift = Offset.zero;
  double _faceScale = 1;
  String? _faceStatus;
  VideoPlayerController? _videoController;
  Uint8List? _imageBytes;
  bool _ready = false;

  List<double>? get _effectiveMatrix {
    if (_filter != MediaFilterPreset.original) return _filter.matrix;
    return _look?.matrix ?? _filter.matrix;
  }

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
    final applied = AppliedFilter(
      preset: _filter,
      faceLookId: widget.isVideo ? null : _look?.id,
      shiftX: _faceShift.dx,
      shiftY: _faceShift.dy,
      scale: _faceScale,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublishScreen(
          file: widget.file,
          remoteUrl: widget.remoteUrl,
          isVideo: widget.isVideo,
          previewBytes: _imageBytes ?? widget.previewBytes,
          filterName: applied.encode(),
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
        title: Text(widget.isVideo ? 'Filtros de video' : 'Filtros'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_ready
                  ? const Center(child: CircularProgressIndicator())
                  : Center(child: _buildPreview()),
            ),
            if (!widget.isVideo && _look != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.face_retouching_natural,
                        size: 15, color: Color(0xFFFFC857)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _faceStatus ??
                            'Arrastra para mover · pellizca para ajustar el tamaño',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!widget.isVideo) ...[
              _sectionLabel('ROSTRO'),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: FaceLooks.all.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _chip(
                        label: 'Ninguno',
                        selected: _look == null,
                        onTap: () => setState(() => _look = null),
                        child: const Icon(Icons.block,
                            color: Colors.white70, size: 26),
                      );
                    }
                    final look = FaceLooks.all[index - 1];
                    final selected = _look?.id == look.id;
                    return _chip(
                      label: look.label,
                      selected: selected,
                      onTap: () => setState(() => _look = look),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Icon(look.icon, color: Colors.white24, size: 22),
                          Padding(
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              look.accessories.first.asset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Los filtros de rostro se aplican a fotos (en video no hay seguimiento facial).',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            _sectionLabel('COLOR'),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: MediaFilterPreset.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final preset = MediaFilterPreset.values[index];
                  final selected = preset == _filter;
                  return _chip(
                    label: preset.label,
                    selected: selected,
                    onTap: () => setState(() => _filter = preset),
                    child: Icon(
                      preset.icon,
                      color:
                          selected ? const Color(0xFFFFC857) : Colors.white70,
                      size: 26,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFFFFC857) : Colors.white24,
                width: selected ? 2 : 1,
              ),
              color: const Color(0xFF1B201D),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: child,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFFFFC857) : Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.isVideo) {
      final filtered = ColorFiltered(
        colorFilter: ColorFilter.matrix(_filter.matrix),
        child: _videoLayer(),
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

    final preview = FaceFilteredImage(
      bytes: _imageBytes,
      sourcePath: widget.file?.path ?? widget.remoteUrl,
      look: _look,
      colorMatrix: _effectiveMatrix,
      fit: BoxFit.contain,
      interactive: _look != null,
      initialShift: _faceShift,
      initialScale: _faceScale,
      onAdjustmentChanged: (shift, scale) {
        _faceShift = shift;
        _faceScale = scale;
      },
      onFaceStatusChanged: (status) {
        if (mounted && status != _faceStatus) {
          setState(() => _faceStatus = status);
        }
      },
    );

    final frame = _filter.frameAsset;
    if (frame == null) return preview;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        preview,
        Positioned.fill(
          child: IgnorePointer(child: Image.asset(frame, fit: BoxFit.fill)),
        ),
      ],
    );
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
