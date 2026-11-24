import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'add_playlist_screen.dart';
import 'theme.dart';

class PlaylistSwitcherButton extends ConsumerWidget {
  const PlaylistSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activePlaylistProvider);
    // Shows which playlist is open; tapping it switches to another one.
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: context.l10n.switchPlaylist,
        child: ActionChip(
          onPressed: () => showPlaylistSwitcher(context, ref),
          avatar: const Icon(Icons.playlist_play, size: 18, color: AppColors.tally),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    active?.name ?? context.l10n.defaultPlaylistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
          side: const BorderSide(color: AppColors.border),
          visualDensity: VisualDensity.compact,
        ),
      ),
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
                child: Text(ctx.l10n.playlists, style: t.titleLarge),
              ),
              for (final p in playlists)
                ListTile(
                  leading: Icon(
                    p.isXtream ? Icons.dns_outlined : Icons.playlist_play,
                    color: p.id == active?.id ? AppColors.tally : AppColors.muted,
                  ),
                  title: Text(p.name),
                  subtitle: Text(_describe(ctx.l10n, p)),
                  trailing: p.id == active?.id ? const Icon(Icons.check, color: AppColors.tally) : null,
                  onTap: () {
                    ref.read(activePlaylistIdProvider.notifier).select(p.id);
                    Navigator.pop(ctx);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.tally),
                title: Text(ctx.l10n.addPlaylist),
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

String _describe(AppLocalizations l, Playlist p) => switch (p.type) {
  SourceType.xtream => 'Xtream Codes · ${Uri.tryParse(p.server ?? '')?.host ?? p.server}',
  SourceType.m3uUrl => '${l.m3uLink} · ${Uri.tryParse(p.url ?? '')?.host ?? ''}',
  SourceType.m3uFile => l.m3uFile,
};
