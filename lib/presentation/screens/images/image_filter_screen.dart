import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/presentation/screens/images/face_accessory.dart';

enum _ColorFilterPreset {
  original('Original', Icons.image_outlined, null),
  warm('Ámbar', Icons.wb_sunny_outlined, [
    1.10,
    0.06,
    0,
    0,
    8,
    0.03,
    1.02,
    0,
    0,
    3,
    0,
    0.02,
    0.88,
    0,
    -5,
    0,
    0,
    0,
    1,
    0,
  ]),
  rose('Rosa', Icons.local_florist_outlined, [
    1.08,
    0.04,
    0.06,
    0,
    5,
    0.02,
    0.96,
    0.04,
    0,
    0,
    0.03,
    0.02,
    1.02,
    0,
    4,
    0,
    0,
    0,
    1,
    0,
  ]),
  monochrome('B/N', Icons.tonality_outlined, [
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]),
  cool('Frío', Icons.ac_unit, [
    0.92,
    0,
    0.04,
    0,
    0,
    0,
    1.02,
    0.03,
    0,
    2,
    0.02,
    0.06,
    1.12,
    0,
    8,
    0,
    0,
    0,
    1,
    0,
  ]),
  clarendon('Clarendon', Icons.contrast, [
    1.2,
    0,
    0,
    0,
    -30,
    0,
    1.2,
    0,
    0,
    -22,
    0,
    0,
    1.25,
    0,
    -15,
    0,
    0,
    0,
    1,
    0,
  ]),
  juno('Juno', Icons.local_fire_department_outlined, [
    1.2756,
    -0.2503,
    -0.0253,
    0,
    12,
    -0.0744,
    1.0997,
    -0.0253,
    0,
    4,
    -0.0744,
    -0.2503,
    1.3247,
    0,
    -10,
    0,
    0,
    0,
    1,
    0,
  ]),
  lark('Lark', Icons.light_mode_outlined, [
    0.8819,
    0.1073,
    0.0108,
    0,
    18,
    0.0319,
    0.9573,
    0.0108,
    0,
    20,
    0.0319,
    0.1073,
    0.8608,
    0,
    26,
    0,
    0,
    0,
    1,
    0,
  ]),
  vintage('Vintage', Icons.camera_roll_outlined, [
    0.393,
    0.769,
    0.189,
    0,
    10,
    0.349,
    0.686,
    0.168,
    0,
    8,
    0.272,
    0.534,
    0.131,
    0,
    4,
    0,
    0,
    0,
    1,
    0,
  ]),
  snap('Snap', Icons.face_retouching_natural, [
    1.1504,
    -0.143,
    -0.0144,
    0,
    6,
    -0.0425,
    1.057,
    -0.0144,
    0,
    6,
    -0.0425,
    -0.143,
    1.1856,
    0,
    6,
    0,
    0,
    0,
    1,
    0,
  ]),
  halloween('Halloween', Icons.nights_stay_outlined, null),
  christmas('Navidad', Icons.ac_unit, null);

  final String label;
  final IconData icon;
  final List<double>? matrix;

  const _ColorFilterPreset(this.label, this.icon, this.matrix);

  String? get frameAsset => switch (this) {
        halloween => 'assets/frames/IMG_5916.JPG.jpeg',
        christmas => 'assets/frames/IMG_5917.JPG.jpeg',
        _ => null,
      };
}

sealed class _SelectedFilter {
  const _SelectedFilter();
  String get label;
}

class _ColorSelected extends _SelectedFilter {
  const _ColorSelected(this.preset);
  final _ColorFilterPreset preset;
  @override
  String get label => preset.label;
}

class _FaceSelected extends _SelectedFilter {
  const _FaceSelected(this.look);
  final FaceLook look;
  @override
  String get label => look.label;
}

class ImageFilterScreen extends StatefulWidget {
  const ImageFilterScreen({super.key, this.previewMode = false});

  final bool previewMode;

  @override
  State<ImageFilterScreen> createState() => _ImageFilterScreenState();
}

class _ImageFilterScreenState extends State<ImageFilterScreen> {
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Uint8List? _imageBytes;
  String? _imagePath;
  Size? _imageSize;
  List<Face> _faces = const [];
  Map<String, ui.Image> _overlayImages = {};
  _SelectedFilter _selectedFilter =
      const _ColorSelected(_ColorFilterPreset.original);
  bool _isPicking = false;
  bool _isDetecting = false;
  String? _faceStatus;

  @override
  void initState() {
    super.initState();
    _preloadOverlayImages();
  }

  @override
  void dispose() {
    _faceDetector.close();
    for (final image in _overlayImages.values) {
      image.dispose();
    }
    super.dispose();
  }

  Future<void> _preloadOverlayImages() async {
    final assets = <String>{
      for (final look in FaceLooks.all)
        for (final accessory in look.accessories) accessory.asset,
    };
    final loaded = <String, ui.Image>{};
    for (final asset in assets) {
      try {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        loaded[asset] = frame.image;
      } catch (_) {
        // Missing asset — skip silently; overlay simply won't draw.
      }
    }
    if (!mounted) return;
    setState(() => _overlayImages = loaded);
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF202522),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || _isPicking) return;

    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 95);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imagePath = image.path;
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _selectedFilter = const _ColorSelected(_ColorFilterPreset.original);
        _faces = const [];
        _faceStatus = null;
      });
      await _detectFaces(image.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la imagen')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _detectFaces(String path) async {
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      setState(() {
        _faceStatus =
            'La detección de rostros funciona en Android/iOS. En escritorio se simula el centro.';
        _faces = const [];
      });
      return;
    }

    setState(() {
      _isDetecting = true;
      _faceStatus = 'Buscando rostros…';
    });

    try {
      final inputImage = InputImage.fromFilePath(path);
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      setState(() {
        _faces = faces;
        _faceStatus = faces.isEmpty
            ? 'No se detectó ningún rostro. Prueba con otra foto.'
            : '${faces.length} rostro${faces.length == 1 ? '' : 's'} detectado${faces.length == 1 ? '' : 's'}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _faces = const [];
        _faceStatus = 'No se pudo detectar rostros en esta foto.';
      });
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  List<FaceOverlayLayout> _currentLayouts() {
    final selected = _selectedFilter;
    if (selected is! _FaceSelected) return const [];

    final imageSize = _imageSize;
    if (imageSize == null) return const [];

    if (_faces.isNotEmpty) {
      return [
        for (final face in _faces)
          ...layoutsForFace(face, selected.look.accessories),
      ];
    }

    final synthetic = Face(
      boundingBox: Rect.fromCenter(
        center: Offset(imageSize.width / 2, imageSize.height * 0.45),
        width: imageSize.width * 0.42,
        height: imageSize.height * 0.52,
      ),
      landmarks: const {},
      contours: const {},
      headEulerAngleZ: 0,
    );
    return layoutsForFace(synthetic, selected.look.accessories);
  }

  List<double>? get _activeMatrix {
    final selected = _selectedFilter;
    if (selected is _ColorSelected) return selected.preset.matrix;
    if (selected is _FaceSelected) return selected.look.matrix;
    return null;
  }

  Widget _applyColorExtras(Widget filteredImage, _ColorFilterPreset preset) {
    final frameAsset = preset.frameAsset;
    if (frameAsset != null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          filteredImage,
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(frameAsset, fit: BoxFit.fill),
            ),
          ),
        ],
      );
    }

    if (preset == _ColorFilterPreset.vintage) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          filteredImage,
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    colors: [Colors.transparent, Color(0x99000000)],
                    stops: [0.55, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (preset == _ColorFilterPreset.snap) {
      final now = DateTime.now();
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      return Stack(
        fit: StackFit.passthrough,
        children: [
          filteredImage,
          Positioned(
            top: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFC00),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$hour:$minute',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'TokTik',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(color: Color(0xFFFF2D87), offset: Offset(2, 2)),
                      Shadow(color: Colors.black45, blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return filteredImage;
  }

  Widget _filteredImage({required BoxFit fit}) {
    final image = _imageBytes == null
        ? const _DemoLandscape()
        : Image.memory(_imageBytes!, fit: fit);
    final matrix = _activeMatrix;
    var filteredImage = matrix == null
        ? image
        : ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix),
            child: image,
          );

    final selected = _selectedFilter;
    if (selected is _ColorSelected) {
      filteredImage = _applyColorExtras(filteredImage, selected.preset);
    }

    final layouts = _currentLayouts();
    if (layouts.isEmpty || _imageSize == null) return filteredImage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            filteredImage,
            CustomPaint(
              painter: FaceAccessoriesPainter(
                layouts: layouts,
                images: _overlayImages,
                imageSize: _imageSize!,
                widgetSize: widgetSize,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes;
    final hasImage = imageBytes != null || widget.previewMode;
    final selected = _selectedFilter;

    return Scaffold(
      backgroundColor: const Color(0xFF111512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111512),
        foregroundColor: Colors.white,
        title: const Text('Filtros de imagen'),
        actions: [
          IconButton(
            tooltip: 'Elegir foto',
            onPressed: _isPicking ? null : _chooseImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B201D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox.expand(
                    child: !hasImage
                        ? Center(
                            child: _isPicking
                                ? const CircularProgressIndicator()
                                : FilledButton.icon(
                                    onPressed: _chooseImage,
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: const Text('Elegir una foto'),
                                  ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: _filteredImage(fit: BoxFit.contain),
                                ),
                                if (_isDetecting)
                                  const Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: LinearProgressIndicator(
                                        minHeight: 3,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (_faceStatus != null && hasImage)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      _faces.isEmpty
                          ? Icons.face_retouching_off
                          : Icons.face_retouching_natural,
                      size: 16,
                      color: _faces.isEmpty
                          ? Colors.orangeAccent
                          : const Color(0xFFFFC857),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _faceStatus!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (hasImage) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ROSTRO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 102,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: FaceLooks.all.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final look = FaceLooks.all[index];
                    final isSelected =
                        selected is _FaceSelected && selected.look.id == look.id;
                    return _FilterChipThumb(
                      label: look.label,
                      selected: isSelected,
                      onTap: () {
                        if (_imageBytes == null && !widget.previewMode) {
                          _chooseImage();
                          return;
                        }
                        setState(() => _selectedFilter = _FaceSelected(look));
                        if (_faces.isEmpty &&
                            _imagePath != null &&
                            !_isDetecting) {
                          _detectFaces(_imagePath!);
                        }
                      },
                      child: _FaceLookPreview(
                        look: look,
                        overlayImages: _overlayImages,
                        selected: isSelected,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    const Text(
                      'COLOR',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      selected.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _ColorFilterPreset.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = _ColorFilterPreset.values[index];
                    final isSelected = selected is _ColorSelected &&
                        selected.preset == preset;
                    final matrix = preset.matrix;
                    final frameAsset = preset.frameAsset;
                    final thumbnail = imageBytes == null
                        ? const _DemoLandscape()
                        : Image.memory(imageBytes, fit: BoxFit.cover);
                    final filteredThumbnail = matrix == null
                        ? thumbnail
                        : ColorFiltered(
                            colorFilter: ColorFilter.matrix(matrix),
                            child: thumbnail,
                          );

                    return _FilterChipThumb(
                      label: preset.label,
                      selected: isSelected,
                      onTap: () => setState(
                        () => _selectedFilter = _ColorSelected(preset),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          filteredThumbnail,
                          if (frameAsset != null)
                            Image.asset(frameAsset, fit: BoxFit.fill),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChipThumb extends StatelessWidget {
  const _FilterChipThumb({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? const Color(0xFFFFC857) : Colors.white24,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: child,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? const Color(0xFFFFC857) : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceLookPreview extends StatelessWidget {
  const _FaceLookPreview({
    required this.look,
    required this.overlayImages,
    required this.selected,
  });

  final FaceLook look;
  final Map<String, ui.Image> overlayImages;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final asset = look.accessories.first.asset;
    return ColoredBox(
      color: const Color(0xFF2A312D),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              look.icon,
              color: selected ? const Color(0xFFFFC857) : Colors.white38,
              size: 22,
            ),
          ),
          if (overlayImages.containsKey(asset))
            Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
        ],
      ),
    );
  }
}

class _DemoLandscape extends StatelessWidget {
  const _DemoLandscape();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF81C9D8), Color(0xFFE7B885)],
            ),
          ),
        ),
        const Positioned(
          top: 34,
          right: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFFFE4A1),
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 56, height: 56),
          ),
        ),
        CustomPaint(painter: _DemoLandscapePainter()),
        const Positioned(
          left: 20,
          top: 20,
          child: Text(
            '11:42 AM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final farHill = Path()
      ..moveTo(0, size.height * 0.60)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.32,
        size.width * 0.51,
        size.height * 0.59,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.39,
        size.width,
        size.height * 0.57,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = const Color(0xFF668F79);
    canvas.drawPath(farHill, paint);

    final nearHill = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.53,
        size.width * 0.57,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.91,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = const Color(0xFF355F4C);
    canvas.drawPath(nearHill, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
