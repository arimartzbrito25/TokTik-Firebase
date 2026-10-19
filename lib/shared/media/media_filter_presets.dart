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
    return MediaFilterPreset.values.firstWhere(
      (f) => f.id == id,
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
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ],
        warm => const [
            1.10, 0.06, 0, 0, 8,
            0.03, 1.02, 0, 0, 3,
            0, 0.02, 0.88, 0, -5,
            0, 0, 0, 1, 0,
          ],
        rose => const [
            1.08, 0.04, 0.06, 0, 5,
            0.02, 0.96, 0.04, 0, 0,
            0.03, 0.02, 1.02, 0, 4,
            0, 0, 0, 1, 0,
          ],
        monochrome => const [
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ],
        cool => const [
            0.92, 0, 0.04, 0, 0,
            0, 1.02, 0.03, 0, 2,
            0.02, 0.06, 1.12, 0, 8,
            0, 0, 0, 1, 0,
          ],
        halloween => const [
            1.12, 0, 0, 0, 8,
            0, 0.84, 0, 0, 0,
            0, 0, 0.92, 0, 8,
            0, 0, 0, 1, 0,
          ],
        christmas => const [
            0.94, 0, 0, 0, 0,
            0, 1.08, 0, 0, 5,
            0, 0, 1.12, 0, 10,
            0, 0, 0, 1, 0,
          ],
      };
}
