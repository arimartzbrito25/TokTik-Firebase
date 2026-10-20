import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> writeTempImageBytes(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
