import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'add_playlist_screen.dart';
import 'theme.dart';
import 'widgets.dart';

const appVersion = '0.1.0';
const repoUrl = 'https://github.com/slayer-iptv/slayer-iptv';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final playlists = ref.watch(playlistsProvider).value ?? const <Playlist>[];
    final active = ref.watch(activePlaylistProvider);
    final epgStatus = ref.watch(epgStatusProvider);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(text, style: t.titleMedium!.copyWith(color: SlayerColors.muted)),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const ScreenHeader(title: 'Settings'),
          heading('Playlists'),
          for (final p in playlists)
            _PlaylistTile(playlist: p, active: p.id == active?.id),
          ListTile(
            leading: const Icon(Icons.add, color: SlayerColors.tally),
            title: const Text('Add playlist'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddPlaylistScreen())),
          ),
          heading('TV guide'),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Update TV guide now'),
            subtitle: Text(switch (epgStatus) {
              EpgStatus.loading => 'Downloading guide…',
              EpgStatus.failed => 'Update failed: ${ref.read(epgStatusProvider.notifier).message ?? 'unknown error'}',
              EpgStatus.idle => active?.epgUrl == null
                  ? 'No guide link for this playlist. Add one from the playlist menu.'
                  : ref.read(epgStatusProvider.notifier).message ?? 'Updates automatically when a playlist is refreshed.',
            }),
            trailing: epgStatus == EpgStatus.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: active == null || epgStatus == EpgStatus.loading
                ? null
                : () => ref.read(playlistsProvider.notifier).refreshEpg(active),
          ),
          heading('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Slayer IPTV'),
            subtitle: const Text('Version $appVersion · Free and open source under GPL-3.0'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Slayer IPTV',
              applicationVersion: appVersion,
              applicationLegalese: 'Copyright (C) 2026 Slayer IPTV contributors.\n'
                  'Licensed under the GNU General Public License v3.0.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Source code'),
            subtitle: SelectableText(repoUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Slayer IPTV is a player only. It does not include, sell or promote any channels or content. '
              'Use it with playlists you are allowed to watch.',
              style: t.bodySmall!.copyWith(color: SlayerColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends ConsumerStatefulWidget {
  const _PlaylistTile({required this.playlist, required this.active});
  final Playlist playlist;
  final bool active;

  @override
  ConsumerState<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends ConsumerState<_PlaylistTile> {
  bool _busy = false;

  Playlist get p => widget.playlist;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(playlistsProvider.notifier).refresh(p);
      messenger.showSnackBar(SnackBar(content: Text('${p.name} updated')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Couldn\'t update ${p.name}: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _ask(String title, String initial, {String? hint}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${p.name}?'),
        content: const Text('Its channels, favorites and watch history are removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: SlayerColors.live),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(playlistsProvider.notifier).remove(p);
  }

  @override
  Widget build(BuildContext context) {
    final updated = p.lastUpdated == null
        ? 'Never updated'
        : 'Updated ${p.lastUpdated!.day}.${p.lastUpdated!.month}.${p.lastUpdated!.year} ${formatTime(p.lastUpdated!)}';
    return ListTile(
      leading: Icon(
        p.isXtream ? Icons.dns_outlined : Icons.playlist_play,
        color: widget.active ? SlayerColors.tally : SlayerColors.muted,
      ),
      title: Text(p.name),
      subtitle: Text(widget.active ? 'In use · $updated' : updated),
      onTap: widget.active ? null : () => ref.read(activePlaylistIdProvider.notifier).select(p.id),
      trailing: _busy
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : PopupMenuButton<String>(
              tooltip: 'Playlist options',
              onSelected: (v) async {
                switch (v) {
                  case 'refresh':
                    await _refresh();
                  case 'rename':
                    final name = await _ask('Rename playlist', p.name);
                    if (name != null && name.isNotEmpty) {
                      await ref.read(playlistsProvider.notifier).rename(p, name);
                    }
                  case 'epg':
                    final url = await _ask('TV guide link', p.epgUrl ?? '', hint: 'https://…/guide.xml.gz');
                    if (url != null) await ref.read(playlistsProvider.notifier).setEpgUrl(p, url);
                  case 'delete':
                    await _delete();
                }
              },
              itemBuilder: (_) => [
                if (p.type != SourceType.m3uFile)
                  const PopupMenuItem(value: 'refresh', child: Text('Update channels')),
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'epg', child: Text('TV guide link')),
                const PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
    );
  }
}
