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
    this.offsetYFactor = 0,
    this.offsetXFactor = 0,
  });

  final String asset;
  final FaceAnchor anchor;

  /// Width relative to face bounding-box width.
  final double widthFactor;

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
    widthFactor: 1.15,
    offsetYFactor: 0.02,
  );

  static const sportGlasses = FaceAccessory(
    asset: 'assets/filters/sport_glasses.png',
    anchor: FaceAnchor.eyes,
    widthFactor: 1.25,
    offsetYFactor: 0.0,
  );

  static const mustache = FaceAccessory(
    asset: 'assets/filters/mustache.png',
    anchor: FaceAnchor.noseMouth,
    widthFactor: 0.55,
    offsetYFactor: 0.02,
  );

  static const beard = FaceAccessory(
    asset: 'assets/filters/beard.png',
    anchor: FaceAnchor.lowerFace,
    widthFactor: 0.95,
    offsetYFactor: 0.12,
  );

  static const hair = FaceAccessory(
    asset: 'assets/filters/hair.png',
    anchor: FaceAnchor.forehead,
    widthFactor: 1.35,
    offsetYFactor: -0.55,
  );

  static const sunHat = FaceAccessory(
    asset: 'assets/filters/sun_hat.png',
    anchor: FaceAnchor.topOfHead,
    widthFactor: 1.7,
    offsetYFactor: -0.55,
  );

  static const santaHat = FaceAccessory(
    asset: 'assets/filters/santa_hat.png',
    anchor: FaceAnchor.topOfHead,
    widthFactor: 1.55,
    offsetYFactor: -0.72,
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
}

class FaceOverlayLayout {
  const FaceOverlayLayout({
    required this.center,
    required this.width,
    required this.rotation,
    required this.asset,
  });

  final Offset center;
  final double width;
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

List<FaceOverlayLayout> layoutsForFace(
  Face face,
  List<FaceAccessory> accessories,
) {
  final box = face.boundingBox;
  final faceW = box.width;
  final faceH = box.height;
  final rotation = _rotationRadians(face);

  final leftEye = _landmark(face, FaceLandmarkType.leftEye);
  final rightEye = _landmark(face, FaceLandmarkType.rightEye);
  final nose = _landmark(face, FaceLandmarkType.noseBase);
  final leftMouth = _landmark(face, FaceLandmarkType.leftMouth);
  final rightMouth = _landmark(face, FaceLandmarkType.rightMouth);
  final bottomMouth = _landmark(face, FaceLandmarkType.bottomMouth);

  Offset eyesCenter;
  if (leftEye != null && rightEye != null) {
    eyesCenter = Offset(
      (leftEye.dx + rightEye.dx) / 2,
      (leftEye.dy + rightEye.dy) / 2,
    );
  } else {
    eyesCenter = Offset(box.center.dx, box.top + faceH * 0.38);
  }

  Offset mouthCenter;
  if (leftMouth != null && rightMouth != null) {
    final midY = bottomMouth?.dy ??
        ((leftMouth.dy + rightMouth.dy) / 2 + faceH * 0.02);
    mouthCenter = Offset((leftMouth.dx + rightMouth.dx) / 2, midY);
  } else {
    mouthCenter = Offset(box.center.dx, box.top + faceH * 0.72);
  }

  final nosePoint = nose ?? Offset(box.center.dx, box.top + faceH * 0.55);
  final noseMouth = Offset(
    (nosePoint.dx + mouthCenter.dx) / 2,
    (nosePoint.dy + mouthCenter.dy) / 2,
  );

  final forehead = Offset(box.center.dx, box.top + faceH * 0.08);
  final topOfHead = Offset(box.center.dx, box.top - faceH * 0.15);

  return accessories.map((accessory) {
    late Offset center;
    switch (accessory.anchor) {
      case FaceAnchor.eyes:
        center = eyesCenter;
      case FaceAnchor.noseMouth:
        center = noseMouth;
      case FaceAnchor.lowerFace:
        center = mouthCenter;
      case FaceAnchor.forehead:
        center = forehead;
      case FaceAnchor.topOfHead:
        center = topOfHead;
    }

    center = Offset(
      center.dx + faceW * accessory.offsetXFactor,
      center.dy + faceH * accessory.offsetYFactor,
    );

    return FaceOverlayLayout(
      center: center,
      width: faceW * accessory.widthFactor,
      rotation: rotation,
      asset: accessory.asset,
    );
  }).toList();
}

/// Maps image-space rect into the widget rect produced by [BoxFit.contain].
Rect fittedImageRect(Size imageSize, Size widgetSize) {
  final fitted = applyBoxFit(BoxFit.contain, imageSize, widgetSize);
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
  });

  final List<FaceOverlayLayout> layouts;
  final Map<String, ui.Image> images;
  final Size imageSize;
  final Size widgetSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty || widgetSize.isEmpty) return;
    final fitted = fittedImageRect(imageSize, widgetSize);
    final sx = fitted.width / imageSize.width;

    for (final layout in layouts) {
      final image = images[layout.asset];
      if (image == null) continue;

      final center = imageToWidget(layout.center, imageSize, fitted);
      final w = layout.width * sx;
      final aspect = image.height / image.width;
      final h = w * aspect;

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
        oldDelegate.widgetSize != widgetSize;
  }
}
