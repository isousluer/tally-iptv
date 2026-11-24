import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../l10n/strings.dart';
import '../state/providers.dart';
import 'theme.dart';

/// How subtitles look, from the viewer's settings, for a video area of
/// [height] logical pixels. Sizes are for a 1080p area; the subtitle view
/// scales them down for smaller players.
SubtitleViewConfiguration subtitleConfig(AppSettings s, double height) {
  final size = switch (s.subtitleSize) {
    SubtitleSize.small => 26.0,
    SubtitleSize.medium => 32.0,
    SubtitleSize.large => 42.0,
    SubtitleSize.huge => 54.0,
  };
  const outline = [
    Shadow(blurRadius: 3, color: Colors.black),
    Shadow(offset: Offset(1.5, 1.5), blurRadius: 2, color: Colors.black),
    Shadow(offset: Offset(-1.5, -1.5), blurRadius: 2, color: Colors.black),
  ];
  final style = TextStyle(
    height: 1.4,
    fontSize: size,
    color: Colors.white,
    fontWeight: s.subtitleBackground == SubtitleBackground.none ? FontWeight.w600 : FontWeight.normal,
    backgroundColor: switch (s.subtitleBackground) {
      SubtitleBackground.none => null,
      SubtitleBackground.box => const Color(0xaa000000),
      SubtitleBackground.solid => const Color(0xee000000),
    },
    shadows: s.subtitleBackground == SubtitleBackground.none ? outline : null,
  );
  final raise = switch (s.subtitlePosition) {
    SubtitlePosition.low => 0.03,
    SubtitlePosition.middle => 0.09,
    SubtitlePosition.high => 0.17,
  };
  return SubtitleViewConfiguration(style: style, padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + height * raise));
}

/// Size, background and position of subtitles, with a live sample.
Future<void> showSubtitleStyle(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SubtitleStyleSheet(),
  );
}

class _SubtitleStyleSheet extends ConsumerWidget {
  const _SubtitleStyleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: t.titleSmall!.copyWith(color: AppColors.muted)),
    );

    Widget choices<T>(List<T> values, T selected, String Function(T) label, ValueChanged<T> onTap) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              showCheckmark: false,
              onSelected: (_) => onTap(v),
              labelStyle: t.labelMedium!.copyWith(color: v == selected ? AppColors.onTally : AppColors.text),
            ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(l.subtitleStyle, style: t.titleLarge),
            ),
            // A sample on a dark "video" so the choices can be judged.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final config = subtitleConfig(s, box.maxHeight);
                    // Text at the size it has in full screen on this device,
                    // scaled the way the player's subtitle view does it.
                    final screen = MediaQuery.sizeOf(context);
                    final scale = sqrt((screen.width * screen.height / (1920 * 1080)).clamp(0.0, 1.0));
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF3A5A63), Color(0xFF9AA8A0)],
                        ),
                      ),
                      padding: config.padding,
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        l.subtitleSample,
                        textAlign: TextAlign.center,
                        style: config.style,
                        textScaler: TextScaler.linear(scale),
                      ),
                    );
                  },
                ),
              ),
            ),
            heading(l.subtitleSize),
            choices(
              SubtitleSize.values,
              s.subtitleSize,
              (v) => switch (v) {
                SubtitleSize.small => l.sizeSmall,
                SubtitleSize.medium => l.sizeMedium,
                SubtitleSize.large => l.sizeLarge,
                SubtitleSize.huge => l.sizeHuge,
              },
              n.setSubtitleSize,
            ),
            heading(l.subtitleBackground),
            choices(
              SubtitleBackground.values,
              s.subtitleBackground,
              (v) => switch (v) {
                SubtitleBackground.none => l.backgroundNone,
                SubtitleBackground.box => l.backgroundBox,
                SubtitleBackground.solid => l.backgroundSolid,
              },
              n.setSubtitleBackground,
            ),
            heading(l.subtitlePosition),
            choices(
              SubtitlePosition.values,
              s.subtitlePosition,
              (v) => switch (v) {
                SubtitlePosition.low => l.positionLow,
                SubtitlePosition.middle => l.positionMiddle,
                SubtitlePosition.high => l.positionHigh,
              },
              n.setSubtitlePosition,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
