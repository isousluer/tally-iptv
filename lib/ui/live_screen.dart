import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'category_picker.dart';
import 'playback.dart';
import 'playlist_switcher.dart';
import 'search_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  String _group = groupAll;
  final String _search = '';

  @override
  Widget build(BuildContext context) {
    final playlist = ref.watch(activePlaylistProvider);
    final count = ref.watch(countProvider(ContentKind.live)).value ?? 0;
    final query = (kind: ContentKind.live, group: _group, search: _search);
    final items = ref.watch(itemsProvider(query));

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ScreenHeader(
            title: 'Live TV',
            subtitle: playlist == null ? null : '${playlist.name} · ${compactCount(count)} channels',
            actions: const [
              SearchButton(first: ContentKind.live),
              PlaylistSwitcherButton(),
            ],
          ),
          CategoryBar(kind: ContentKind.live, selected: _group, onSelected: (g) => setState(() => _group = g)),
          const SizedBox(height: 8),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(itemsProvider(query))),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: _group == groupFavorites ? Icons.star_border : Icons.live_tv_outlined,
                    title: _search.isNotEmpty
                        ? 'No channels match "$_search"'
                        : _group == groupFavorites
                        ? 'No favorite channels yet'
                        : 'No channels here',
                    message: _group == groupFavorites ? 'Tap the star next to a channel to keep it here.' : null,
                  );
                }
                return _ChannelList(channels: list);
              },
            ),
          ),
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
      color: SlayerColors.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                            style: t.labelSmall!.copyWith(color: SlayerColors.muted, fontFeatures: tabular),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
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
                      style: t.bodySmall!.copyWith(color: SlayerColors.muted),
                    ),
                    if (program != null) ...[const SizedBox(height: 7), TallyBar(value: program!.progressAt(now))],
                  ],
                ),
              ),
              IconButton(
                tooltip: channel.favorite ? 'Remove from favorites' : 'Add to favorites',
                onPressed: onFavorite,
                icon: Icon(
                  channel.favorite ? Icons.star : Icons.star_border,
                  color: channel.favorite ? SlayerColors.tally : SlayerColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
