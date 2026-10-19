import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String caption;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

enum _VideoFilter { original, halloween, christmas }

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late VideoPlayerController controller;
  _VideoFilter selectedFilter = _VideoFilter.original;

  @override
  void initState() {
    super.initState();

    controller = widget.videoUrl.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        : VideoPlayerController.asset(widget.videoUrl);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

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
                  colorFilter: ColorFilter.matrix(_filterMatrix),
                  child: VideoPlayer(controller),
                ),

                if (selectedFilter != _VideoFilter.original)
                  _SeasonalArtwork(filter: selectedFilter),

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: SafeArea(
                    bottom: false,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        _FilterOption(
                          label: 'Original',
                          icon: Icons.tune,
                          selected: selectedFilter == _VideoFilter.original,
                          onTap: () => _selectFilter(_VideoFilter.original),
                        ),
                        _FilterOption(
                          label: 'Halloween',
                          icon: Icons.nights_stay,
                          selected: selectedFilter == _VideoFilter.halloween,
                          onTap: () => _selectFilter(_VideoFilter.halloween),
                        ),
                        _FilterOption(
                          label: 'Navidad',
                          icon: Icons.ac_unit,
                          selected: selectedFilter == _VideoFilter.christmas,
                          onTap: () => _selectFilter(_VideoFilter.christmas),
                        ),
                      ],
                    ),
                  ),
                ),

                // Gradiente
                VideoBackground(stops: const [0.8, 1.0]),

                // Texto
                Positioned(
                  bottom: 50,
                  left: 20,
                  child: _VideoCaption(caption: widget.caption),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<double> get _filterMatrix {
    switch (selectedFilter) {
      case _VideoFilter.halloween:
        return const [
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
        ];
      case _VideoFilter.christmas:
        return const [
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
        ];
      case _VideoFilter.original:
        return const [
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
        ];
    }
  }

  void _selectFilter(_VideoFilter filter) {
    setState(() => selectedFilter = filter);
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

class _SeasonalArtwork extends StatelessWidget {
  final _VideoFilter filter;

  const _SeasonalArtwork({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isHalloween = filter == _VideoFilter.halloween;
    final accent = isHalloween
        ? const Color(0xFFFF8A24)
        : const Color(0xFFB8F4FF);
    final icons = isHalloween
        ? const [Icons.nights_stay, Icons.auto_awesome, Icons.cruelty_free]
        : const [Icons.ac_unit, Icons.forest, Icons.card_giftcard];

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.10),
                    Colors.transparent,
                    (isHalloween
                            ? const Color(0xFF5A1B7A)
                            : const Color(0xFF087C54))
                        .withValues(alpha: 0.12),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              top: 76,
              right: 18,
              child: Column(
                children: [
                  for (var index = 0; index < icons.length; index++) ...[
                    if (index != 0) const SizedBox(height: 18),
                    Icon(
                      icons[index],
                      size: index == 1 ? 22 : 28,
                      color: accent.withValues(alpha: index == 1 ? 0.82 : 0.95),
                      shadows: [
                        Shadow(
                          color: accent.withValues(alpha: 0.55),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 76,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.65)),
                ),
                child: Text(
                  isHalloween ? 'NOCHE DE HALLOWEEN' : 'MAGIA NAVIDENA',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCaption extends StatelessWidget {
  final String caption;

  const _VideoCaption({super.key, required this.caption});

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
