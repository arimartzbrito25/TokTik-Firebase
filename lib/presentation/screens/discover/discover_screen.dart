import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/camera/camera_screen.dart';
import 'package:toktok/presentation/screens/images/image_filter_screen.dart';
import 'package:toktok/presentation/widgets/shared/video_scrollable_view.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final discoverProvider = context.watch<DiscoverProvider>();

    return Scaffold(
      body: discoverProvider.initialLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Stack(
              children: [
                VideoScrollableView(videos: discoverProvider.videos),
                Positioned(
                  top: 8,
                  right: 12,
                  child: SafeArea(
                    child: Material(
                      color: const Color(0xAA171A18),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Filtros de imagen',
                        color: Colors.white,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ImageFilterScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CameraScreen(),
            ),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
