import 'package:flutter/material.dart';

/// Filtros compartidos para imagen y video (antes de publicar y en el feed).
enum MediaFilterPreset {
  original('original', 'Original', Icons.tune),
  warm('warm', 'Ámbar', Icons.wb_sunny_outlined),
  rose('rose', 'Rosa', Icons.local_florist_outlined),
  monochrome('monochrome', 'B/N', Icons.tonality_outlined),
  cool('cool', 'Frío', Icons.ac_unit),
  halloween('halloween', 'Halloween', Icons.nights_stay_outlined),
  christmas('christmas', 'Navidad', Icons.park_outlined);

  final String id;
  final String label;
  final IconData icon;

  const MediaFilterPreset(this.id, this.label, this.icon);

  static MediaFilterPreset fromId(String? id) {
    // Acepta el formato compuesto: "warm|face:full_look|adj:0.01,-0.02,1.0"
    final colorId = id?.split('|').first;
    return MediaFilterPreset.values.firstWhere(
      (f) => f.id == colorId,
      orElse: () => MediaFilterPreset.original,
    );
  }

  String? get frameAsset => switch (this) {
        halloween => 'assets/frames/IMG_5916.JPG.jpeg',
        christmas => 'assets/frames/IMG_5917.JPG.jpeg',
        _ => null,
      };

  List<double> get matrix => switch (this) {
        original => const [
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ],
        warm => const [
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
          ],
        rose => const [
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
          ],
        monochrome => const [
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
          ],
        cool => const [
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
          ],
        halloween => const [
            1.12,
            0,
            0,
            0,
            8,
            0,
            0.84,
            0,
            0,
            0,
            0,
            0,
            0.92,
            0,
            8,
            0,
            0,
            0,
            1,
            0,
          ],
        christmas => const [
            0.94,
            0,
            0,
            0,
            0,
            0,
            1.08,
            0,
            0,
            5,
            0,
            0,
            1.12,
            0,
            10,
            0,
            0,
            0,
            1,
            0,
          ],
      };
}

/// Selección completa de filtros (color + rostro + ajuste fino manual).
/// Se serializa en `filterName` como:
/// `warm|face:full_look|adj:<dx>,<dy>,<escala>` (dx/dy relativos al rostro).
class AppliedFilter {
  const AppliedFilter({
    this.preset = MediaFilterPreset.original,
    this.faceLookId,
    this.shiftX = 0,
    this.shiftY = 0,
    this.scale = 1,
  });

  final MediaFilterPreset preset;
  final String? faceLookId;
  final double shiftX;
  final double shiftY;
  final double scale;

  bool get hasFace => faceLookId != null && faceLookId!.isNotEmpty;

  String encode() {
    final buffer = StringBuffer(preset.id);
    if (hasFace) {
      buffer.write('|face:$faceLookId');
      if (shiftX != 0 || shiftY != 0 || scale != 1) {
        buffer.write(
          '|adj:${shiftX.toStringAsFixed(3)},'
          '${shiftY.toStringAsFixed(3)},${scale.toStringAsFixed(3)}',
        );
      }
    }
    return buffer.toString();
  }

  static AppliedFilter parse(String? raw) {
    if (raw == null || raw.isEmpty) return const AppliedFilter();
    final parts = raw.split('|');
    String? faceId;
    var dx = 0.0, dy = 0.0, scale = 1.0;
    for (final part in parts.skip(1)) {
      if (part.startsWith('face:')) {
        faceId = part.substring(5);
      } else if (part.startsWith('adj:')) {
        final nums = part.substring(4).split(',');
        if (nums.length == 3) {
          dx = double.tryParse(nums[0]) ?? 0;
          dy = double.tryParse(nums[1]) ?? 0;
          scale = double.tryParse(nums[2]) ?? 1;
        }
      }
    }
    return AppliedFilter(
      preset: MediaFilterPreset.fromId(raw),
      faceLookId: (faceId == null || faceId.isEmpty) ? null : faceId,
      shiftX: dx,
      shiftY: dy,
      scale: scale.clamp(0.4, 2.5),
    );
  }
}
