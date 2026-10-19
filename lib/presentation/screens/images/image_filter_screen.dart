import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum _ImageFilterPreset {
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
  halloween('Halloween', Icons.nights_stay_outlined, [
    1.12,
    0.02,
    0.04,
    0,
    4,
    0.02,
    0.91,
    0.04,
    0,
    0,
    0.08,
    0.02,
    1.13,
    0,
    8,
    0,
    0,
    0,
    1,
    0,
  ]),
  christmas('Navidad', Icons.ac_unit, [
    1.04,
    0.02,
    0.02,
    0,
    4,
    0.02,
    1.08,
    0.03,
    0,
    5,
    0.03,
    0.06,
    1.16,
    0,
    10,
    0,
    0,
    0,
    1,
    0,
  ]);

  final String label;
  final IconData icon;
  final List<double>? matrix;

  const _ImageFilterPreset(this.label, this.icon, this.matrix);
}

class ImageFilterScreen extends StatefulWidget {
  const ImageFilterScreen({super.key, this.previewMode = false});

  final bool previewMode;

  @override
  State<ImageFilterScreen> createState() => _ImageFilterScreenState();
}

class _ImageFilterScreenState extends State<ImageFilterScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  _ImageFilterPreset _selectedFilter = _ImageFilterPreset.original;
  bool _isPicking = false;

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
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _selectedFilter = _ImageFilterPreset.original;
      });
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

  Widget _filteredImage({required BoxFit fit}) {
    final image = _imageBytes == null
        ? const _DemoLandscape()
        : Image.memory(_imageBytes!, fit: fit);
    final matrix = _selectedFilter.matrix;
    final filteredImage = matrix == null
        ? image
        : ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix),
            child: image,
          );

    if (_selectedFilter == _ImageFilterPreset.halloween ||
        _selectedFilter == _ImageFilterPreset.christmas) {
      final isHalloween = _selectedFilter == _ImageFilterPreset.halloween;
      return Stack(
        fit: StackFit.passthrough,
        children: [
          filteredImage,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isHalloween
                        ? [
                            const Color(0x44220A35),
                            Colors.transparent,
                            const Color(0x55220A35),
                          ]
                        : [
                            const Color(0x332A6E54),
                            Colors.transparent,
                            const Color(0x44305B75),
                          ],
                  ),
                ),
                child: Stack(
                  children: isHalloween
                      ? [
                          const Positioned(
                            top: 14,
                            left: 14,
                            child: Icon(Icons.nights_stay,
                                color: Color(0xFFFF9A3D), size: 30),
                          ),
                          const Positioned(
                            top: 18,
                            right: 18,
                            child: Icon(Icons.auto_awesome,
                                color: Color(0xFFFFC857), size: 20),
                          ),
                          const Positioned(
                            bottom: 16,
                            left: 18,
                            child: Icon(Icons.auto_awesome,
                                color: Color(0xFFFF9A3D), size: 17),
                          ),
                          const Positioned(
                            bottom: 14,
                            right: 14,
                            child: Icon(Icons.local_fire_department,
                                color: Color(0xFFFF9A3D), size: 28),
                          ),
                        ]
                      : [
                          const Positioned(
                            top: 14,
                            left: 14,
                            child: Icon(Icons.ac_unit,
                                color: Color(0xFFE7F7FF), size: 25),
                          ),
                          const Positioned(
                            top: 18,
                            right: 18,
                            child: Icon(Icons.auto_awesome,
                                color: Color(0xFFFFD166), size: 20),
                          ),
                          const Positioned(
                            bottom: 14,
                            left: 16,
                            child: Icon(Icons.park,
                                color: Color(0xFF6FC28A), size: 27),
                          ),
                          const Positioned(
                            bottom: 14,
                            right: 14,
                            child: Icon(Icons.card_giftcard,
                                color: Color(0xFFFF7474), size: 25),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return filteredImage;
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _imageBytes;
    final hasImage = imageBytes != null || widget.previewMode;

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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                                        Icons.photo_library_outlined),
                                    label: const Text('Elegir una foto'),
                                  ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: _filteredImage(fit: BoxFit.contain),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (hasImage) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'FILTROS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedFilter.label,
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
                  itemCount: _ImageFilterPreset.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = _ImageFilterPreset.values[index];
                    final selected = preset == _selectedFilter;
                    final matrix = preset.matrix;
                    return SizedBox(
                      width: 74,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _selectedFilter = preset),
                        child: Column(
                          children: [
                            Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFFC857)
                                      : Colors.white24,
                                  width: selected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: matrix == null
                                    ? imageBytes == null
                                        ? const _DemoLandscape()
                                        : Image.memory(
                                            imageBytes,
                                            fit: BoxFit.cover,
                                          )
                                    : ColorFiltered(
                                        colorFilter: ColorFilter.matrix(matrix),
                                        child: imageBytes == null
                                            ? const _DemoLandscape()
                                            : Image.memory(
                                                imageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              preset.label,
                              maxLines: 1,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFFFC857)
                                    : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
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
