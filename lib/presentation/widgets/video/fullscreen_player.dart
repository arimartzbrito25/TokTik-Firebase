import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:toktok/shared/media/media_filter_presets.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String caption;
  final String filterName;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
    this.filterName = 'original',
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late VideoPlayerController controller;
  late MediaFilterPreset selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = MediaFilterPreset.fromId(widget.filterName);

    controller = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.asset(widget.videoUrl);

    controller.initialize().then((_) async {
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final frame = selectedFilter.frameAsset;

    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
          return;
        }
        controller.play();
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.matrix(selectedFilter.matrix),
              child: VideoPlayer(controller),
            ),
            if (frame != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(frame, fit: BoxFit.fill),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final preset in MediaFilterPreset.values) ...[
                        _FilterOption(
                          label: preset.label,
                          icon: preset.icon,
                          selected: selectedFilter == preset,
                          onTap: () => setState(() => selectedFilter = preset),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            VideoBackground(stops: const [0.8, 1.0]),
            Positioned(
              bottom: 50,
              left: 20,
              child: _VideoCaption(caption: widget.caption),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;

    return Material(
      color: selected ? const Color(0xD9202020) : const Color(0x99202020),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCaption extends StatelessWidget {
  final String caption;

  const _VideoCaption({required this.caption});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SizedBox(
      width: size.width * 0.6,
      child: Text(caption, maxLines: 2, style: titleStyle),
    );
  }
}
