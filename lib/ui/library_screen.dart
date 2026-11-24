import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'continue_row.dart';
import 'live_screen.dart';
import 'playback.dart';
import 'search_screen.dart';
import 'theme.dart';
import 'vod_screen.dart';
import 'widgets.dart';

/// Watch history and favorites, as two tabs. History opens first.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            ScreenHeader(title: l.library, actions: const [SearchButton()]),
            TabBar(
              indicatorColor: AppColors.tally,
              labelColor: AppColors.text,
              unselectedLabelColor: AppColors.muted,
              dividerColor: AppColors.border,
              tabs: [
                Tab(text: l.watchHistory),
                Tab(text: l.favorites),
              ],
            ),
            const Expanded(child: TabBarView(children: [_HistoryTab(), _FavoritesTab()])),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final history = ref.watch(historyProvider).value ?? const [];
    final channels = history.map((h) => h.$1.item).where((i) => i.kind == ContentKind.live).take(10).toList();
    final hasContinue = history.any((h) => h.$1.item.kind != ContentKind.live && h.$1.positionMs > 0);

    if (channels.isEmpty && !hasContinue) {
      return EmptyState(icon: Icons.history, title: l.historyEmptyTitle, message: l.historyEmptyMessage);
    }

    return CustomScrollView(
      slivers: [
        if (hasContinue) const SliverToBoxAdapter(child: ContinueRow()),
        if (channels.isNotEmpty) ...[
          SliverToBoxAdapter(child: _Heading(l.recentChannels)),
          SliverList.builder(
            itemCount: channels.length,
            itemBuilder: (_, i) => _ChannelTile(channel: channels[i], siblings: channels),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _clearHistory(context, ref),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l.clearHistory),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted, textStyle: t.labelLarge),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _clearHistory(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.clearHistoryTitle),
        content: Text(l.clearHistoryBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.live),
            child: Text(l.clear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final p = ref.read(activePlaylistProvider);
    if (p == null) return;
    await ref.read(databaseProvider).clearHistory(p.id);
    ref.invalidate(historyProvider);
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final favorites = ref.watch(favoritesProvider).value ?? const <MediaItem>[];
    final channels = favorites.where((f) => f.kind == ContentKind.live).toList();
    final vod = favorites.where((f) => f.kind != ContentKind.live).toList();

    if (favorites.isEmpty) {
      return EmptyState(icon: Icons.star_border, title: l.favoritesEmptyTitle, message: l.favoritesEmptyMessage);
    }

    return CustomScrollView(
      slivers: [
        if (channels.isNotEmpty) ...[
          SliverToBoxAdapter(child: _Heading(l.favoriteChannels)),
          SliverList.builder(
            itemCount: channels.length,
            itemBuilder: (_, i) => _ChannelTile(channel: channels[i], siblings: channels),
          ),
        ],
        if (vod.isNotEmpty) ...[
          SliverToBoxAdapter(child: _Heading(l.favoriteMoviesAndSeries)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 236,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: vod.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 116,
                  child: PosterTile(item: vod[i], onTap: () => openItem(context, ref, vod[i])),
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _ChannelTile extends ConsumerWidget {
  const _ChannelTile({required this.channel, required this.siblings});
  final MediaItem channel;
  final List<MediaItem> siblings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(nowPlayingProvider).value ?? const {};
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 74,
        child: ChannelRow(
          channel: channel,
          program: channel.tvgId == null ? null : guide[channel.tvgId!.toLowerCase()],
          now: now,
          onTap: () => openItem(context, ref, channel, siblings: siblings),
          onFavorite: () => ref.read(favoritesControllerProvider).toggle(channel),
        ),
      ),
    );
  }
}
