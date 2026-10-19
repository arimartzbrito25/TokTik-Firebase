import 'package:flutter/material.dart';
import 'package:toktok/presentation/screens/images/image_filter_screen.dart';

void main() {
  runApp(const ImageFilterPreviewApp());
}

class ImageFilterPreviewApp extends StatelessWidget {
  const ImageFilterPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ImageFilterScreen(previewMode: true),
    );
  }
}
