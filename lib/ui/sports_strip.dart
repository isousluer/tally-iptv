import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../state/providers.dart';
import '../state/sports.dart';
import 'playback.dart';
import 'theme.dart';

/// Today's matches on Turkish TV (from sporekrani.com), above the channel
/// list. A tap opens the viewer's channel for it; matches on channels the
/// list doesn't have are dimmed. Hidden when there is nothing to show.
class SportsStrip extends ConsumerWidget {
  const SportsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(sportListingsProvider).value ?? const [];
    if (listings.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final channels = [
      for (final s in listings)
        if (s.channel != null) s.channel!,
    ];
    final scale = MediaQuery.textScalerOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l.todaysMatches, style: t.titleMedium),
        ),
        SizedBox(
          height: 24 + scale.scale(14) + scale.scale(20) + scale.scale(16) + scale.scale(18) + 12,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (:event, :channel) = listings[i];
              final started = !now.isBefore(event.start);
              final time =
                  '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';
              final where = channel?.name ?? (event.channels.isEmpty ? l.matchNotOnTv : event.channels.first);
              return Opacity(
                opacity: channel == null ? 0.45 : 1,
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: channel == null ? null : () => openItem(context, ref, channel, siblings: channels),
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                started ? l.matchOn : time,
                                style: t.labelMedium!.copyWith(
                                  color: started ? AppColors.tally : null,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.sport,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelSmall!.copyWith(color: AppColors.muted),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                          Text(
                            event.competition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelSmall!.copyWith(color: AppColors.muted),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                channel == null ? Icons.tv_off_outlined : Icons.live_tv_outlined,
                                size: 14,
                                color: channel == null ? AppColors.muted : AppColors.tally,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  channel == null && event.channels.isNotEmpty ? l.matchNotInList(where) : where,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
