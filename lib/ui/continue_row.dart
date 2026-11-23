import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'playback.dart';
import 'theme.dart';
import 'widgets.dart';

/// Horizontal "Continue watching" strip. Shows unfinished movies and episodes.
class ContinueRow extends ConsumerWidget {
  const ContinueRow({super.key, this.kind});

  /// Restrict to one kind, or null for movies and series together.
  final ContentKind? kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final entries = (ref.watch(historyProvider).value ?? const [])
        .where((e) => e.$1.item.kind != ContentKind.live && e.$1.positionMs > 0)
        .where((e) => kind == null || e.$1.item.kind == kind)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text('Continue watching', style: t.titleLarge),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final (entry, url) = entries[i];
              final left = Duration(milliseconds: entry.durationMs - entry.positionMs);
              final title = entry.title ?? entry.item.name;
              return SizedBox(
                width: 220,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    final playUrl = url ?? entry.item.url;
                    if (playUrl == null) return;
                    play(
                      context,
                      ref,
                      PlayRequest(
                        item: entry.item,
                        url: playUrl,
                        title: title,
                        subtitle: entry.item.kind == ContentKind.series ? entry.item.name : null,
                        historyKey: entry.historyKey,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Poster(title: title, url: entry.item.logo, aspectRatio: 16 / 9),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                            child: TallyBar(value: entry.progress, height: 3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.labelMedium),
                      Text('${formatDuration(left)} left', style: t.labelSmall!.copyWith(color: AppColors.tally)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
