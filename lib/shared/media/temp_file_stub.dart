import 'package:flutter/foundation.dart';

/// En web no hay sistema de archivos: la detección facial no se ejecuta.
Future<String?> writeTempImageBytes(Uint8List bytes, String name) async => null;
