import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/backup.dart';
import '../data/models.dart';
import '../state/providers.dart';
import 'add_playlist_screen.dart';
import 'categories_screen.dart';
import 'parental.dart';
import 'player_screen.dart' show languageName;
import 'theme.dart';
import 'widgets.dart';

const appVersion = '0.1.0';
const repoUrl = 'https://github.com/isousluer/slayer-iptv';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final playlists = ref.watch(playlistsProvider).value ?? const <Playlist>[];
    final active = ref.watch(activePlaylistProvider);
    final epgStatus = ref.watch(epgStatusProvider);
    final settings = ref.watch(settingsProvider);
    final pin = ref.watch(parentalPinProvider);
    final unlocked = ref.watch(parentalUnlockedProvider);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(text, style: t.titleMedium!.copyWith(color: SlayerColors.muted)),
    );

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = readableInset(box.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
            children: [
              const ScreenHeader(title: 'Settings'),
              heading('Playlists'),
              for (final p in playlists) _PlaylistTile(playlist: p, active: p.id == active?.id),
              ListTile(
                leading: const Icon(Icons.add, color: SlayerColors.tally),
                title: const Text('Add playlist'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPlaylistScreen())),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.sync),
                title: const Text('Update playlists automatically'),
                subtitle: const Text('When the app opens, lists older than a day are refreshed.'),
                value: settings.autoRefresh,
                onChanged: (v) => ref.read(settingsProvider.notifier).setAutoRefresh(v),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categories'),
                subtitle: const Text('Hide, lock or reorder categories'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
              ),
              heading('Playback'),
              SwitchListTile(
                secondary: const Icon(Icons.skip_next_outlined),
                title: const Text('Play next episode automatically'),
                value: settings.autoNext,
                onChanged: (v) => ref.read(settingsProvider.notifier).setAutoNext(v),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack_outlined),
                title: const Text('Audio language'),
                subtitle: Text(
                  settings.audioLanguage == null
                      ? 'Stream default. Pick a language in the player and it\'s used from then on.'
                      : '${languageName(settings.audioLanguage!)} · tap to go back to the stream default',
                ),
                onTap: settings.audioLanguage == null
                    ? null
                    : () => ref.read(settingsProvider.notifier).setAudioLanguage(null),
              ),
              ListTile(
                leading: const Icon(Icons.closed_caption_outlined),
                title: const Text('Subtitles'),
                subtitle: Text(switch (settings.subtitleLanguage) {
                  null => 'Stream default. Pick subtitles in the player and they\'re used from then on.',
                  'off' => 'Off · tap to go back to the stream default',
                  final l => '${languageName(l)} · tap to go back to the stream default',
                }),
                onTap: settings.subtitleLanguage == null
                    ? null
                    : () => ref.read(settingsProvider.notifier).setSubtitleLanguage(null),
              ),
              heading('Parental control'),
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(pin == null ? 'Set a PIN' : 'Change PIN'),
                subtitle: Text(
                  pin == null
                      ? 'Lock categories so they need a PIN to open.'
                      : unlocked
                      ? 'Locked categories are open until the app restarts.'
                      : 'Locked categories need the PIN to open.',
                ),
                onTap: () async {
                  if (pin != null && !await unlockWithPin(context, ref)) return;
                  if (!context.mounted) return;
                  final next = await choosePin(context);
                  if (next != null) await ref.read(parentalPinProvider.notifier).set(next);
                },
              ),
              if (pin != null && unlocked)
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Lock now'),
                  onTap: () => ref.read(parentalUnlockedProvider.notifier).set(false),
                ),
              if (pin != null)
                ListTile(
                  leading: const Icon(Icons.no_encryption_outlined),
                  title: const Text('Remove PIN'),
                  subtitle: const Text('Locked categories open without a PIN.'),
                  onTap: () async {
                    if (!await unlockWithPin(context, ref)) return;
                    await ref.read(parentalPinProvider.notifier).set(null);
                  },
                ),
              heading('Backup'),
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: const Text('Back up to a file'),
                subtitle: const Text('Playlists, logins, favorites, watch history and categories'),
                onTap: () => _backup(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('Restore from a file'),
                subtitle: const Text('Adds the playlists from a backup and downloads their channels'),
                onTap: () => _restore(context, ref),
              ),
              heading('TV guide'),
              ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: const Text('Update TV guide now'),
                subtitle: Text(switch (epgStatus) {
                  EpgStatus.loading => 'Downloading guide…',
                  EpgStatus.failed =>
                    'Update failed: ${ref.read(epgStatusProvider.notifier).message ?? 'unknown error'}',
                  EpgStatus.idle =>
                    active?.epgUrl == null
                        ? 'No guide link for this playlist. Add one from the playlist menu.'
                        : ref.read(epgStatusProvider.notifier).message ??
                              'Updates automatically when a playlist is refreshed.',
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
                  applicationLegalese:
                      'Copyright (C) 2026 Slayer IPTV contributors.\n'
                      'Licensed under the GNU General Public License v3.0.',
                ),
              ),
              const ListTile(leading: Icon(Icons.code), title: Text('Source code'), subtitle: SelectableText(repoUrl)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Slayer IPTV is a player only. It does not include, sell or promote any channels or content. '
                  'Use it with playlists you are allowed to watch.',
                  style: t.bodySmall!.copyWith(color: SlayerColors.muted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _backup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Back up to a file'),
      content: const Text(
        'The file includes your playlist links, usernames and passwords. '
        'Keep it somewhere private.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Back up')),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final json = await exportBackup(ref.read(databaseProvider), ref.read(prefsProvider));
    final d = DateTime.now();
    final name =
        'slayer-iptv-backup-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.json';
    final saved = await FilePicker.saveFile(
      fileName: name,
      bytes: Uint8List.fromList(utf8.encode(json)),
      mimeType: 'application/json',
      dialogTitle: 'Save backup',
    );
    if (saved != null) messenger.showSnackBar(const SnackBar(content: Text('Backup saved')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Couldn\'t save the backup: $e')));
  }
}

Future<void> _restore(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final file = await FilePicker.pickFile(dialogTitle: 'Choose a backup', type: FileType.any);
  if (file == null || !context.mounted) return;
  final status = ValueNotifier<String>('Reading backup…');
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 16),
            Expanded(
              child: ValueListenableBuilder(valueListenable: status, builder: (_, v, _) => Text(v)),
            ),
          ],
        ),
      ),
    ),
  );
  try {
    final json = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    final r = await ref.read(playlistsProvider.notifier).restore(json, onLoading: (n) => status.value = 'Loading $n…');
    String count(int n) => '$n playlist${n == 1 ? '' : 's'}';
    final parts = [
      if (r.playlists.isNotEmpty) 'Added ${count(r.playlists.length)}',
      if (r.alreadyThere > 0)
        r.playlists.isEmpty
            ? '${count(r.alreadyThere)} already in the app, so only favorites, history and categories were merged'
            : '${r.alreadyThere} already in the app',
      if (r.skipped.isNotEmpty) 'Skipped local files: ${r.skipped.join(', ')}',
    ];
    messenger.showSnackBar(
      SnackBar(
        content: Text(parts.isEmpty ? 'The backup has no playlists.' : parts.join(' · ')),
        duration: const Duration(seconds: 6),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
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
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
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
                if (p.type != SourceType.m3uFile) const PopupMenuItem(value: 'refresh', child: Text('Update channels')),
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'epg', child: Text('TV guide link')),
                const PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
    );
  }
}
