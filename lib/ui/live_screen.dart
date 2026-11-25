import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'category_picker.dart';
import 'channel_lists.dart';
import 'playback.dart';
import 'playlist_switcher.dart';
import 'search_screen.dart';
import 'sort_button.dart';
import 'theme.dart';
import 'widgets.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  String _group = groupAll;

  @override
  Widget build(BuildContext context) {
    final playlist = ref.watch(activePlaylistProvider);
    final count = ref.watch(countProvider(ContentKind.live)).value ?? 0;
    final query = (kind: ContentKind.live, group: _group, search: '');
    final items = ref.watch(itemsProvider(query));

    final wide = isWide(context);
    final l = context.l10n;
    void select(String g) => setState(() => _group = g);
    final content = items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(itemsProvider(query))),
      data: (list) {
        if (list.isEmpty && listIdOf(_group) != null) {
          return EmptyState(icon: Icons.playlist_add, title: l.listEmptyTitle, message: l.listEmptyMessage);
        }
        if (list.isEmpty) {
          return EmptyState(
            icon: _group == groupFavorites ? Icons.star_border : Icons.live_tv_outlined,
            title: _group == groupFavorites
                ? l.noFavoriteChannels
                : l.noChannelsHere,
            message: _group == groupFavorites ? l.favoriteChannelsHint : null,
          );
        }
        return _ChannelList(channels: list);
      },
    );

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ScreenHeader(
            title: l.liveTv,
            subtitle: playlist == null ? null : l.channelCount(count),
            actions: const [
              SearchButton(first: ContentKind.live),
              SortButton(kind: ContentKind.live),
              PlaylistSwitcherButton(),
            ],
          ),
          if (wide)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CategoryPanel(kind: ContentKind.live, selected: _group, onSelected: select),
                  const SizedBox(width: 8),
                  Expanded(child: content),
                ],
              ),
            )
          else ...[
            CategoryBar(kind: ContentKind.live, selected: _group, onSelected: select),
            const SizedBox(height: 12),
            Expanded(child: content),
          ],
        ],
      ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList({required this.channels});
  final List<MediaItem> channels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.watch(nowPlayingProvider).value ?? const {};
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: channels.length,
      itemExtent: 82,
      itemBuilder: (context, i) {
        final c = channels[i];
        final program = c.tvgId == null ? null : guide[c.tvgId!.toLowerCase()];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ChannelRow(
            channel: c,
            program: program,
            now: now,
            onTap: () => openItem(context, ref, c, siblings: channels),
            onFavorite: () => ref.read(favoritesControllerProvider).toggle(c),
          ),
        );
      },
    );
  }
}

class ChannelRow extends StatelessWidget {
  const ChannelRow({
    super.key,
    required this.channel,
    required this.program,
    required this.now,
    required this.onTap,
    required this.onFavorite,
  });

  final MediaItem channel;
  final EpgProgram? program;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => showAddToLists(context, channel),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
          child: Row(
            children: [
              ChannelLogo(name: channel.name, url: channel.logo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (channel.number != null) ...[
                          Text(
                            channel.number.toString().padLeft(3, '0'),
                            style: t.labelSmall!.copyWith(color: AppColors.muted, fontFeatures: tabular),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                        ),
                        if (channel.hasArchive)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Tooltip(
                              message: context.l10n.hasArchive,
                              child: const Icon(Icons.history, size: 15, color: AppColors.muted),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      program == null
                          ? channel.group
                          : '${program!.title}  ${formatTime(program!.start)} – ${formatTime(program!.stop)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall!.copyWith(color: AppColors.muted),
                    ),
                    if (program != null) ...[const SizedBox(height: 7), TallyBar(value: program!.progressAt(now))],
                  ],
                ),
              ),
              IconButton(
                tooltip: channel.favorite ? context.l10n.removeFromFavorites : context.l10n.addToFavorites,
                onPressed: onFavorite,
                icon: Icon(
                  channel.favorite ? Icons.star : Icons.star_border,
                  color: channel.favorite ? AppColors.tally : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
