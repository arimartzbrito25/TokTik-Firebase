import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Where an accessory should sit relative to face landmarks.
enum FaceAnchor {
  eyes,
  noseMouth,
  lowerFace,
  forehead,
  topOfHead,
}

class FaceAccessory {
  const FaceAccessory({
    required this.asset,
    required this.anchor,
    this.widthFactor = 1.0,
    this.heightFactor,
    this.offsetYFactor = 0,
    this.offsetXFactor = 0,
  });

  final String asset;
  final FaceAnchor anchor;

  /// Width relative to face bounding-box width.
  final double widthFactor;

  /// Height relative to face height. Si es null, se conserva el aspecto
  /// natural de la imagen (el pelo necesita altura propia: su PNG es casi
  /// cuadrado y cubriría media cara).
  final double? heightFactor;

  /// Extra vertical shift as a fraction of face height (positive = down).
  final double offsetYFactor;

  /// Extra horizontal shift as a fraction of face width (positive = right).
  final double offsetXFactor;
}

/// Presets that place one or more accessories on a detected face.
class FaceLook {
  const FaceLook({
    required this.id,
    required this.label,
    required this.icon,
    required this.accessories,
    this.matrix,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<FaceAccessory> accessories;
  final List<double>? matrix;
}

class FaceLooks {
  static const glasses = FaceAccessory(
    asset: 'assets/filters/glasses.png',
    anchor: FaceAnchor.eyes,
    widthFactor: 1.02,
    offsetYFactor: 0,
  );

  static const sportGlasses = FaceAccessory(
    asset: 'assets/filters/sport_glasses.png',
    anchor: FaceAnchor.eyes,
    widthFactor: 1.08,
    offsetYFactor: 0,
  );

  static const mustache = FaceAccessory(
    asset: 'assets/filters/mustache.png',
    anchor: FaceAnchor.noseMouth,
    widthFactor: 0.52,
    offsetYFactor: 0,
  );

  static const beard = FaceAccessory(
    asset: 'assets/filters/beard.png',
    anchor: FaceAnchor.lowerFace,
    widthFactor: 0.88,
    offsetYFactor: 0,
  );

  static const hair = FaceAccessory(
    asset: 'assets/filters/hair.png',
    anchor: FaceAnchor.forehead,
    widthFactor: 1.14,
    heightFactor: 0.62,
    offsetYFactor: 0,
  );

  static const sunHat = FaceAccessory(
    asset: 'assets/filters/sun_hat.png',
    anchor: FaceAnchor.topOfHead,
    widthFactor: 1.5,
    offsetYFactor: 0,
  );

  static const santaHat = FaceAccessory(
    asset: 'assets/filters/santa_hat.png',
    anchor: FaceAnchor.topOfHead,
    widthFactor: 1.35,
    offsetYFactor: 0,
  );

  static const List<FaceLook> all = [
    FaceLook(
      id: 'glasses',
      label: 'Lentes',
      icon: Icons.visibility_outlined,
      accessories: [glasses],
    ),
    FaceLook(
      id: 'sport',
      label: 'Sport',
      icon: Icons.sports_motorsports_outlined,
      accessories: [sportGlasses],
    ),
    FaceLook(
      id: 'mustache',
      label: 'Bigote',
      icon: Icons.face_retouching_natural,
      accessories: [mustache],
    ),
    FaceLook(
      id: 'beard',
      label: 'Barba',
      icon: Icons.face_6_outlined,
      accessories: [beard],
    ),
    FaceLook(
      id: 'hair',
      label: 'Peinado',
      icon: Icons.content_cut,
      accessories: [hair],
    ),
    FaceLook(
      id: 'sun_hat',
      label: 'Sombrero',
      icon: Icons.beach_access_outlined,
      accessories: [sunHat],
    ),
    FaceLook(
      id: 'santa',
      label: 'Santa',
      icon: Icons.celebration_outlined,
      accessories: [santaHat],
      matrix: [
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
      ],
    ),
    FaceLook(
      id: 'full_look',
      label: 'Look',
      icon: Icons.auto_awesome,
      accessories: [hair, glasses, mustache],
    ),
    FaceLook(
      id: 'party',
      label: 'Fiesta',
      icon: Icons.nightlife,
      accessories: [santaHat, sportGlasses, mustache],
    ),
  ];

  static FaceLook? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final look in all) {
      if (look.id == id) return look;
    }
    return null;
  }
}

class FaceOverlayLayout {
  const FaceOverlayLayout({
    required this.center,
    required this.width,
    this.height,
    required this.rotation,
    required this.asset,
  });

  final Offset center;
  final double width;

  /// Alto en coords. de imagen; null = conservar aspecto natural.
  final double? height;
  final double rotation;
  final String asset;
}

Offset? _landmark(Face face, FaceLandmarkType type) {
  final point = face.landmarks[type]?.position;
  if (point == null) return null;
  return Offset(point.x.toDouble(), point.y.toDouble());
}

double _rotationRadians(Face face) {
  final z = face.headEulerAngleZ ?? 0;
  return z * math.pi / 180;
}

/// Rostro estimado cuando ML Kit no está disponible (web/escritorio).
/// Retrato típico: rostro centrado, ojos cerca del 38 % del alto de la foto.
/// El usuario puede afinarlo arrastrando/pellizcando en el editor.
Face syntheticFaceFor(Size imageSize) {
  final faceW = imageSize.width * 0.36;
  final faceH = faceW * 1.32;
  final center = Offset(imageSize.width / 2, imageSize.height * 0.40);
  return Face(
    boundingBox: Rect.fromCenter(center: center, width: faceW, height: faceH),
    landmarks: const {},
    contours: const {},
    headEulerAngleZ: 0,
  );
}

List<FaceOverlayLayout> layoutsForFace(
  Face face,
  List<FaceAccessory> accessories, {
  Offset shiftFactor = Offset.zero,
  double scaleFactor = 1,
}) {
  final box = face.boundingBox;
  final faceW = box.width;
  final faceH = box.height;
  final rotation = _rotationRadians(face);

  final leftEye = _landmark(face, FaceLandmarkType.leftEye);
  final rightEye = _landmark(face, FaceLandmarkType.rightEye);
  final nose = _landmark(face, FaceLandmarkType.noseBase);
  final leftMouth = _landmark(face, FaceLandmarkType.leftMouth);
  final rightMouth = _landmark(face, FaceLandmarkType.rightMouth);

  // Ojos: centro entre ambos ojos (sin landmarks, ~38 % desde arriba del rostro).
  Offset eyesCenter;
  double? eyeDistance;
  if (leftEye != null && rightEye != null) {
    eyesCenter = Offset(
      (leftEye.dx + rightEye.dx) / 2,
      (leftEye.dy + rightEye.dy) / 2,
    );
    eyeDistance = (leftEye - rightEye).distance;
  } else {
    eyesCenter = Offset(box.center.dx, box.top + faceH * 0.38);
  }

  // Boca: centro entre las comisuras (no el labio inferior).
  Offset mouthCenter;
  if (leftMouth != null && rightMouth != null) {
    mouthCenter = Offset(
      (leftMouth.dx + rightMouth.dx) / 2,
      (leftMouth.dy + rightMouth.dy) / 2,
    );
  } else {
    mouthCenter = Offset(box.center.dx, box.top + faceH * 0.76);
  }

  final nosePoint = nose ?? Offset(box.center.dx, box.top + faceH * 0.58);

  // Bigote: pegado sobre el labio superior, entre la nariz y la boca.
  final mustacheCenter = Offset(
    nosePoint.dx * 0.30 + mouthCenter.dx * 0.70,
    nosePoint.dy * 0.30 + mouthCenter.dy * 0.70 - faceH * 0.015,
  );

  // Barba: su centro va en la mandíbula, debajo de la boca.
  final beardCenter = Offset(mouthCenter.dx, mouthCenter.dy + faceH * 0.17);

  // Pelo: la pieza ya trae el copete arriba; su centro queda casi en la
  // línea superior del rostro (antes quedaba media cara por encima).
  final hairCenter = Offset(box.center.dx, box.top + faceH * 0.10);

  // Sombreros: la visera/gorro se apoya justo sobre la frente.
  final hatCenter = Offset(box.center.dx, box.top - faceH * 0.10);
  final santaCenter = Offset(box.center.dx, box.top - faceH * 0.16);

  return accessories.map((accessory) {
    late Offset center;
    var width = faceW * accessory.widthFactor;
    switch (accessory.anchor) {
      case FaceAnchor.eyes:
        center = eyesCenter;
        // Con landmarks, el ancho sale de la distancia entre ojos (más fiel
        // que el bounding box, que varía según el detector).
        if (eyeDistance != null && eyeDistance > 0) {
          width = eyeDistance * 2.55 * (accessory.widthFactor / 1.02);
        }
      case FaceAnchor.noseMouth:
        center = mustacheCenter;
      case FaceAnchor.lowerFace:
        center = beardCenter;
      case FaceAnchor.forehead:
        center = hairCenter;
      case FaceAnchor.topOfHead:
        center = accessory.asset.contains('santa') ? santaCenter : hatCenter;
    }

    center = Offset(
      center.dx + faceW * accessory.offsetXFactor + shiftFactor.dx * faceW,
      center.dy + faceH * accessory.offsetYFactor + shiftFactor.dy * faceH,
    );

    return FaceOverlayLayout(
      center: center,
      width: width * scaleFactor,
      height: accessory.heightFactor == null
          ? null
          : faceH * accessory.heightFactor! * scaleFactor,
      rotation: rotation,
      asset: accessory.asset,
    );
  }).toList();
}

/// Rect de la imagen ya aplicada [fit] dentro del widget (centrada).
Rect fittedImageRect(Size imageSize, Size widgetSize,
    {BoxFit fit = BoxFit.contain}) {
  final fitted = applyBoxFit(fit, imageSize, widgetSize);
  final dest = fitted.destination;
  final dx = (widgetSize.width - dest.width) / 2;
  final dy = (widgetSize.height - dest.height) / 2;
  return Rect.fromLTWH(dx, dy, dest.width, dest.height);
}

Offset imageToWidget(Offset imagePoint, Size imageSize, Rect fitted) {
  final sx = fitted.width / imageSize.width;
  final sy = fitted.height / imageSize.height;
  return Offset(
    fitted.left + imagePoint.dx * sx,
    fitted.top + imagePoint.dy * sy,
  );
}

class FaceAccessoriesPainter extends CustomPainter {
  FaceAccessoriesPainter({
    required this.layouts,
    required this.images,
    required this.imageSize,
    required this.widgetSize,
    this.fit = BoxFit.contain,
  });

  final List<FaceOverlayLayout> layouts;
  final Map<String, ui.Image> images;
  final Size imageSize;
  final Size widgetSize;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty || widgetSize.isEmpty) return;
    final fitted = fittedImageRect(imageSize, widgetSize, fit: fit);
    final sx = fitted.width / imageSize.width;

    for (final layout in layouts) {
      final image = images[layout.asset];
      if (image == null) continue;

      final center = imageToWidget(layout.center, imageSize, fitted);
      final w = layout.width * sx;
      final aspect = image.height / image.width;
      final h = layout.height == null ? w * aspect : layout.height! * sx;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(layout.rotation);
      final dest = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      paintImage(
        canvas: canvas,
        rect: dest,
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FaceAccessoriesPainter oldDelegate) {
    return oldDelegate.layouts != layouts ||
        oldDelegate.images != images ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.widgetSize != widgetSize ||
        oldDelegate.fit != fit;
  }
}
