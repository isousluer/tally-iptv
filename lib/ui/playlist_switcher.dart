import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'add_playlist_screen.dart';
import 'theme.dart';

class PlaylistSwitcherButton extends ConsumerWidget {
  const PlaylistSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Switch playlist',
      icon: const Icon(Icons.swap_vert),
      onPressed: () => showPlaylistSwitcher(context, ref),
    );
  }
}

Future<void> showPlaylistSwitcher(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final playlists = ref.watch(playlistsProvider).value ?? const <Playlist>[];
        final active = ref.watch(activePlaylistProvider);
        final t = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Playlists', style: t.titleLarge),
              ),
              for (final p in playlists)
                ListTile(
                  leading: Icon(
                    p.isXtream ? Icons.dns_outlined : Icons.playlist_play,
                    color: p.id == active?.id ? SlayerColors.tally : SlayerColors.muted,
                  ),
                  title: Text(p.name),
                  subtitle: Text(_describe(p)),
                  trailing: p.id == active?.id ? const Icon(Icons.check, color: SlayerColors.tally) : null,
                  onTap: () {
                    ref.read(activePlaylistIdProvider.notifier).select(p.id);
                    Navigator.pop(ctx);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add, color: SlayerColors.tally),
                title: const Text('Add playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}

String _describe(Playlist p) => switch (p.type) {
      SourceType.xtream => 'Xtream Codes · ${Uri.tryParse(p.server ?? '')?.host ?? p.server}',
      SourceType.m3uUrl => 'M3U link · ${Uri.tryParse(p.url ?? '')?.host ?? ''}',
      SourceType.m3uFile => 'M3U file',
    };
