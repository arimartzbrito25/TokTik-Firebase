import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/widgets/shared/video_buttons.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';
import 'package:toktok/presentation/screens/images/face_accessory.dart';
import 'package:toktok/presentation/widgets/media/face_filtered_image.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:toktok/shared/media/media_filter_presets.dart';

class VideoScrollableView extends StatelessWidget {
  final List<VideoPost> videos;

  const VideoScrollableView({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no hay publicaciones.\nVe a Crear y sube la primera.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final VideoPost videoPost = videos[index];

        return Stack(
          children: [
            SizedBox.expand(
              child: videoPost.videoUrl.trim().isEmpty
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          videoPost.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : videoPost.isImage
                      ? _ImagePostView(
                          imageUrl: videoPost.videoUrl,
                          caption: videoPost.caption,
                          filterName: videoPost.filterName,
                        )
                      : FullScreenPlayer(
                          caption: videoPost.caption,
                          videoUrl: videoPost.videoUrl,
                          filterName: videoPost.filterName,
                        ),
            ),
            Positioned(
              bottom: 40,
              right: 20,
              child: VideoButtons(video: videoPost),
            ),
          ],
        );
      },
    );
  }
}

class _ImagePostView extends StatelessWidget {
  final String imageUrl;
  final String caption;
  final String filterName;

  const _ImagePostView({
    required this.imageUrl,
    required this.caption,
    this.filterName = 'original',
  });

  @override
  Widget build(BuildContext context) {
    final filter = MediaFilterPreset.fromId(filterName);
    final applied = AppliedFilter.parse(filterName);
    final faceLook = FaceLooks.byId(applied.faceLookId);
    final frame = filter.frameAsset;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (faceLook != null)
          FaceFilteredImage(
            sourcePath: imageUrl,
            look: faceLook,
            colorMatrix: filter.matrix,
            fit: BoxFit.cover,
            initialShift: Offset(applied.shiftX, applied.shiftY),
            initialScale: applied.scale,
          )
        else
          ColorFiltered(
            colorFilter: ColorFilter.matrix(filter.matrix),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (_, __, ___) => const Center(
                child:
                    Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            ),
          ),
        if (frame != null)
          IgnorePointer(child: Image.asset(frame, fit: BoxFit.fill)),
        VideoBackground(stops: const [0.8, 1.0]),
        Positioned(
          bottom: 50,
          left: 20,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: Text(
              caption,
              maxLines: 2,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ],
    );
  }
}
