import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'continue_row.dart';
import 'live_screen.dart';
import 'playback.dart';
import 'search_screen.dart';
import 'theme.dart';
import 'vod_screen.dart';
import 'widgets.dart';

/// Favorites and watch history in one place.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final favorites = ref.watch(favoritesProvider).value ?? const <MediaItem>[];
    final history = ref.watch(historyProvider).value ?? const [];
    final guide = ref.watch(nowPlayingProvider).value ?? const {};
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    final favChannels = favorites.where((f) => f.kind == ContentKind.live).toList();
    final favVod = favorites.where((f) => f.kind != ContentKind.live).toList();
    final recentChannels = history.map((h) => h.$1.item).where((i) => i.kind == ContentKind.live).take(10).toList();
    final hasContinue = history.any((h) => h.$1.item.kind != ContentKind.live && h.$1.positionMs > 0);

    final empty = favorites.isEmpty && history.isEmpty;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(title, style: t.titleLarge),
    );

    Widget channelRow(MediaItem c, List<MediaItem> siblings) {
      final program = c.tvgId == null ? null : guide[c.tvgId!.toLowerCase()];
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          height: 74,
          child: ChannelRow(
            channel: c,
            program: program,
            now: now,
            onTap: () => openItem(context, ref, c, siblings: siblings),
            onFavorite: () => ref.read(favoritesControllerProvider).toggle(c),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: ScreenHeader(title: 'Library', actions: [SearchButton()]),
          ),
          if (empty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.bookmarks_outlined,
                title: 'Nothing here yet',
                message: 'Channels you watch and anything you mark with a star will show up here.',
              ),
            ),
          if (hasContinue) const SliverToBoxAdapter(child: ContinueRow()),
          if (favChannels.isNotEmpty) ...[
            SliverToBoxAdapter(child: section('Favorite channels')),
            SliverList.builder(
              itemCount: favChannels.length,
              itemBuilder: (_, i) => channelRow(favChannels[i], favChannels),
            ),
          ],
          if (favVod.isNotEmpty) ...[
            SliverToBoxAdapter(child: section('Favorite movies and series')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: favVod.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: 116,
                    child: PosterTile(item: favVod[i], onTap: () => openItem(context, ref, favVod[i])),
                  ),
                ),
              ),
            ),
          ],
          if (recentChannels.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
                child: Row(
                  children: [
                    Expanded(child: Text('Recently watched channels', style: t.titleLarge)),
                    TextButton(
                      onPressed: () async {
                        final p = ref.read(activePlaylistProvider);
                        if (p == null) return;
                        await ref.read(databaseProvider).clearHistory(p.id);
                        ref.invalidate(historyProvider);
                      },
                      child: const Text('Clear history'),
                    ),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: recentChannels.length,
              itemBuilder: (_, i) => channelRow(recentChannels[i], recentChannels),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: favorites.isEmpty && !empty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Tip: tap the star on any channel, movie or series to add it to favorites.',
                      style: t.bodySmall!.copyWith(color: AppColors.muted),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
