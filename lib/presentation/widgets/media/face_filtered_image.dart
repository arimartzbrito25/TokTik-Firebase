import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toktok/presentation/screens/images/face_accessory.dart';
import 'package:toktok/shared/media/media_filter_presets.dart';
import 'package:toktok/shared/media/media_helpers.dart';
import 'package:toktok/shared/media/temp_file_stub.dart'
    if (dart.library.io) 'package:toktok/shared/media/temp_file_io.dart'
    as temp_file;

/// Imagen con filtro de color + accesorios de rostro bien ubicados.
///
/// - En Android/iOS detecta el rostro con ML Kit y ancla cada accesorio a
///   los landmarks (ojos, nariz, boca). Sin detección (web/escritorio o foto
///   sin rostro) usa un rostro estimado centrado.
/// - En modo interactivo el usuario puede arrastrar para mover los
///   accesorios y pellizcar para escalarlos, y ese ajuste fino se reporta
///   con [onAdjustmentChanged] para persistirlo en `filterName`.
class FaceFilteredImage extends StatefulWidget {
  const FaceFilteredImage({
    super.key,
    this.bytes,
    this.sourcePath,
    this.look,
    this.colorMatrix,
    this.fit = BoxFit.contain,
    this.interactive = false,
    this.initialShift = Offset.zero,
    this.initialScale = 1,
    this.onAdjustmentChanged,
    this.onFaceStatusChanged,
  });

  final Uint8List? bytes;

  /// Ruta local, URL http(s) o blob: (para feed / imágenes remotas).
  final String? sourcePath;
  final FaceLook? look;
  final List<double>? colorMatrix;
  final BoxFit fit;
  final bool interactive;
  final Offset initialShift;
  final double initialScale;
  final void Function(Offset shift, double scale)? onAdjustmentChanged;
  final ValueChanged<String?>? onFaceStatusChanged;

  @override
  State<FaceFilteredImage> createState() => _FaceFilteredImageState();
}

class _FaceFilteredImageState extends State<FaceFilteredImage> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Uint8List? _bytes;
  Size? _imageSize;
  List<Face> _faces = const [];
  Map<String, ui.Image> _overlayImages = {};
  bool _detecting = false;

  late Offset _shift = widget.initialShift;
  late double _scale = widget.initialScale;
  double _gestureStartScale = 1;

  @override
  void initState() {
    super.initState();
    _shift = widget.initialShift;
    _scale = widget.initialScale;
    _loadOverlayImages();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant FaceFilteredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes ||
        oldWidget.sourcePath != widget.sourcePath) {
      _faces = const [];
      _shift = widget.initialShift;
      _scale = widget.initialScale;
      _resolveImage();
    } else if (oldWidget.look?.id != widget.look?.id) {
      // Al cambiar de look se conserva el ajuste, pero si aún no hay rostro
      // detectado intentamos detectar de nuevo.
      if (_faces.isEmpty && _bytes != null) _detectFaces();
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    for (final image in _overlayImages.values) {
      image.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOverlayImages() async {
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
        // Asset faltante: ese accesorio simplemente no se dibuja.
      }
    }
    if (!mounted) return;
    setState(() => _overlayImages = loaded);
  }

  Future<void> _resolveImage() async {
    Uint8List? bytes = widget.bytes;

    if (bytes == null && widget.sourcePath != null) {
      final path = widget.sourcePath!;
      if (path.startsWith('http')) {
        try {
          final data = await NetworkAssetBundle(Uri.parse(path)).load(path);
          bytes = data.buffer.asUint8List();
        } catch (_) {
          bytes = null; // Se muestra con Image.network y overlay estimado.
        }
      }
    }

    if (bytes != null) {
      try {
        final decoded = await decodeImageFromList(bytes);
        if (!mounted) return;
        setState(() {
          _bytes = bytes;
          _imageSize =
              Size(decoded.width.toDouble(), decoded.height.toDouble());
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _bytes = bytes);
      }
      await _detectFaces();
      return;
    }

    // Sin bytes (p. ej. URL que no se pudo descargar): resolvemos el tamaño
    // con el ImageProvider para poder posicionar el overlay estimado.
    final path = widget.sourcePath;
    if (path != null && path.isNotEmpty) {
      final provider = NetworkImage(path);
      provider.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener(
              (info, _) {
                if (!mounted) return;
                setState(() {
                  _imageSize = Size(
                    info.image.width.toDouble(),
                    info.image.height.toDouble(),
                  );
                });
              },
              onError: (_, __) {},
            ),
          );
    }
  }

  Future<void> _detectFaces() async {
    if (widget.look == null) return;
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _reportStatus(
          'Detección automática solo en Android/iOS: arrastra los filtros para ubicarlos en el rostro.');
      return;
    }

    final bytes = _bytes;
    final localPath = widget.sourcePath;
    setState(() => _detecting = true);
    _reportStatus('Buscando rostros…');

    try {
      String? filePath;
      if (localPath != null &&
          !localPath.startsWith('http') &&
          !localPath.startsWith('blob:')) {
        filePath = localPath;
      } else if (bytes != null) {
        filePath = await temp_file.writeTempImageBytes(
          bytes,
          'face_detect_${bytes.hashCode}.jpg',
        );
      }
      if (filePath == null) return;

      final faces =
          await _faceDetector.processImage(InputImage.fromFilePath(filePath));
      if (!mounted) return;
      setState(() => _faces = faces);
      _reportStatus(
        faces.isEmpty
            ? 'No se detectó rostro: arrastra los filtros para ubicarlos.'
            : '${faces.length} rostro${faces.length == 1 ? '' : 's'} detectado${faces.length == 1 ? '' : 's'}',
      );
    } catch (_) {
      if (!mounted) return;
      _reportStatus(
          'No se pudo detectar el rostro: ajusta los filtros a mano.');
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  void _reportStatus(String? status) {
    final callback = widget.onFaceStatusChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(status);
    });
  }

  List<FaceOverlayLayout> _layouts() {
    final look = widget.look;
    final imageSize = _imageSize;
    if (look == null || imageSize == null) return const [];

    if (_faces.isNotEmpty) {
      return [
        for (final face in _faces)
          ...layoutsForFace(
            face,
            look.accessories,
            shiftFactor: _shift,
            scaleFactor: _scale,
          ),
      ];
    }
    return layoutsForFace(
      syntheticFaceFor(imageSize),
      look.accessories,
      shiftFactor: _shift,
      scaleFactor: _scale,
    );
  }

  void _notifyAdjustment() {
    widget.onAdjustmentChanged?.call(_shift, _scale);
  }

  @override
  Widget build(BuildContext context) {
    final base = _bytes != null
        ? Image.memory(_bytes!, fit: widget.fit)
        : LocalImage(bytes: null, path: widget.sourcePath, fit: widget.fit);

    final filtered = widget.colorMatrix == null
        ? base
        : ColorFiltered(
            colorFilter: ColorFilter.matrix(widget.colorMatrix!),
            child: base,
          );

    if (widget.look == null || _imageSize == null) return filtered;

    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        final fitted =
            fittedImageRect(_imageSize!, widgetSize, fit: widget.fit);
        final stack = Stack(
          fit: StackFit.expand,
          children: [
            filtered,
            CustomPaint(
              painter: FaceAccessoriesPainter(
                layouts: _layouts(),
                images: _overlayImages,
                imageSize: _imageSize!,
                widgetSize: widgetSize,
                fit: widget.fit,
              ),
            ),
            if (_detecting)
              const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ),
            if (widget.interactive)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Restablecer posición',
                    iconSize: 18,
                    icon: const Icon(Icons.center_focus_strong,
                        color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _shift = Offset.zero;
                        _scale = 1;
                      });
                      _notifyAdjustment();
                    },
                  ),
                ),
              ),
          ],
        );

        if (!widget.interactive) return stack;

        return GestureDetector(
          onScaleStart: (details) {
            _gestureStartScale = _scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (fitted.width > 0 && fitted.height > 0) {
                // focalPointDelta es el delta desde el último evento:
                // se acumula (x2.5 ≈ paso de coords. de imagen a rostro).
                _shift = Offset(
                  _shift.dx + details.focalPointDelta.dx / fitted.width * 2.5,
                  _shift.dy + details.focalPointDelta.dy / fitted.height * 2.5,
                );
              }
              _scale = (_gestureStartScale * details.scale).clamp(0.4, 2.5);
            });
            _notifyAdjustment();
          },
          child: stack,
        );
      },
    );
  }
}

/// Codifica la selección para guardarla en `filterName`.
String encodeAppliedFilter(AppliedFilter filter) => filter.encode();
