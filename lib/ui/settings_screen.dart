import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:material_ui/material_ui.dart';

import '../app_info.dart';
import '../data/backup.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'account_sheet.dart';
import 'add_playlist_screen.dart';
import 'categories_screen.dart';
import 'channel_lists.dart';
import 'menu.dart';
import 'parental.dart';
import 'player_screen.dart' show languageName;
import 'subtitle_style.dart';
import 'theme.dart';
import 'updates.dart';
import 'widgets.dart';

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
    final l = context.l10n;

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(text, style: t.titleMedium!.copyWith(color: AppColors.muted)),
    );

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) {
          final inset = readableInset(box.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
            children: [
              ScreenHeader(title: l.settings),
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(l.language),
                subtitle: Text(languageLabel(l, settings.language)),
                onTap: () => _pickLanguage(context, ref, settings.language),
              ),
              heading(l.playlists),
              for (final p in playlists) _PlaylistTile(playlist: p, active: p.id == active?.id),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.tally),
                title: Text(l.addPlaylist),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPlaylistScreen())),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.sync),
                title: Text(l.autoRefreshTitle),
                subtitle: Text(l.autoRefreshSubtitle),
                value: settings.autoRefresh,
                onChanged: (v) => ref.read(settingsProvider.notifier).setAutoRefresh(v),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(l.categories),
                subtitle: Text(l.categoriesSubtitle),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: Text(l.channelLists),
                subtitle: Text(l.channelListsSubtitle),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChannelListsScreen())),
              ),
              heading(l.playback),
              SwitchListTile(
                secondary: const Icon(Icons.skip_next_outlined),
                title: Text(l.autoNextTitle),
                value: settings.autoNext,
                onChanged: (v) => ref.read(settingsProvider.notifier).setAutoNext(v),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack_outlined),
                title: Text(l.audioLanguage),
                subtitle: Text(
                  settings.audioLanguage == null
                      ? l.audioLanguageDefault
                      : l.tapForStreamDefault(languageName(settings.audioLanguage!)),
                ),
                onTap: settings.audioLanguage == null
                    ? null
                    : () => ref.read(settingsProvider.notifier).setAudioLanguage(null),
              ),
              ListTile(
                leading: const Icon(Icons.closed_caption_outlined),
                title: Text(l.subtitles),
                subtitle: Text(switch (settings.subtitleLanguage) {
                  null => l.subtitlesDefault,
                  'off' => l.tapForStreamDefault(l.off),
                  final code => l.tapForStreamDefault(languageName(code)),
                }),
                onTap: settings.subtitleLanguage == null
                    ? null
                    : () => ref.read(settingsProvider.notifier).setSubtitleLanguage(null),
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: Text(l.subtitleStyle),
                subtitle: Text(l.subtitleStyleSubtitle),
                onTap: () => showSubtitleStyle(context),
              ),
              heading(l.parentalControl),
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(pin == null ? l.setPin : l.changePin),
                subtitle: Text(
                  pin == null
                      ? l.pinNotSet
                      : unlocked
                      ? l.pinUnlocked
                      : l.pinLocked,
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
                  title: Text(l.lockNow),
                  onTap: () => ref.read(parentalUnlockedProvider.notifier).set(false),
                ),
              if (pin != null)
                ListTile(
                  leading: const Icon(Icons.no_encryption_outlined),
                  title: Text(l.removePin),
                  subtitle: Text(l.removePinSubtitle),
                  onTap: () async {
                    if (!await unlockWithPin(context, ref)) return;
                    await ref.read(parentalPinProvider.notifier).set(null);
                  },
                ),
              heading(l.backup),
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(l.backupToFile),
                subtitle: Text(l.backupToFileSubtitle),
                onTap: () => _backup(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l.restoreFromFile),
                subtitle: Text(l.restoreFromFileSubtitle),
                onTap: () => _restore(context, ref),
              ),
              heading(l.tvGuide),
              ListTile(
                leading: const Icon(Icons.event_note_outlined),
                title: Text(l.updateTvGuideNow),
                subtitle: Text(switch (epgStatus) {
                  EpgStatus.loading => l.downloadingGuide,
                  EpgStatus.failed => l.guideUpdateFailed(
                    ref.read(epgStatusProvider.notifier).message ?? l.unknownError,
                  ),
                  EpgStatus.idle =>
                    active?.epgUrl == null
                        ? l.guideNoLink
                        : ref.read(epgStatusProvider.notifier).message ?? l.guideUpdatesAutomatically,
                }),
                trailing: epgStatus == EpgStatus.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: active == null || epgStatus == EpgStatus.loading
                    ? null
                    : () => ref.read(playlistsProvider.notifier).refreshEpg(active),
              ),
              heading(l.about),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Tally'),
                subtitle: Text(l.versionLine(appVersion)),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Tally',
                  applicationVersion: appVersion,
                  applicationLegalese:
                      'Copyright (C) 2026 Tally contributors.\n'
                      'Licensed under the GNU General Public License v3.0.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: Text(l.checkForUpdates),
                onTap: () => checkForUpdateNow(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_none),
                title: Text(l.notifyUpdates),
                subtitle: Text(l.notifyUpdatesSubtitle),
                value: settings.checkUpdates,
                onChanged: (v) => ref.read(settingsProvider.notifier).setCheckUpdates(v),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(l.sourceCode),
                subtitle: const SelectableText(repoUrl),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(l.disclaimer, style: t.bodySmall!.copyWith(color: AppColors.muted)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Name of a language setting: a language in its own name, or "System language".
String languageLabel(AppLocalizations l, String? code) => switch (code) {
  null => l.systemLanguage,
  'tr' => 'Türkçe',
  _ => 'English',
};

Future<void> _pickLanguage(BuildContext context, WidgetRef ref, String? current) async {
  final l = context.l10n;
  final picked = await showDialog<(String?,)>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l.language),
      children: [
        for (final code in [null, ...appLocales.map((x) => x.languageCode)])
          ListTile(
            title: Text(languageLabel(l, code)),
            trailing: code == current ? const Icon(Icons.check, color: AppColors.tally) : null,
            onTap: () => Navigator.pop(ctx, (code,)),
          ),
      ],
    ),
  );
  if (picked != null) await ref.read(settingsProvider.notifier).setLanguage(picked.$1);
}

Future<void> _backup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.backupToFile),
      content: Text(l.backupWarning),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.backUp)),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final json = await exportBackup(ref.read(databaseProvider), ref.read(prefsProvider));
    final d = DateTime.now();
    final name =
        'tally-backup-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.json';
    final saved = await FilePicker.saveFile(
      fileName: name,
      bytes: Uint8List.fromList(utf8.encode(json)),
      mimeType: 'application/json',
      dialogTitle: l.saveBackup,
    );
    if (saved != null) messenger.showSnackBar(SnackBar(content: Text(l.backupSaved)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.backupFailed('$e'))));
  }
}

Future<void> _restore(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  final file = await FilePicker.pickFile(dialogTitle: l.chooseBackup, type: FileType.any);
  if (file == null || !context.mounted) return;
  final status = ValueNotifier<String>(l.readingBackup);
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
    final r = await ref
        .read(playlistsProvider.notifier)
        .restore(json, onLoading: (n) => status.value = l.loadingNamed(n));
    final parts = [
      if (r.playlists.isNotEmpty) l.restoreAdded(l.playlistCount(r.playlists.length)),
      if (r.alreadyThere > 0)
        r.playlists.isEmpty
            ? l.restoreAllPresent(l.playlistCount(r.alreadyThere))
            : l.restoreSomePresent(r.alreadyThere),
      if (r.skipped.isNotEmpty) l.restoreSkipped(r.skipped.join(', ')),
    ];
    messenger.showSnackBar(
      SnackBar(content: Text(parts.isEmpty ? l.restoreEmpty : parts.join(' · ')), duration: const Duration(seconds: 6)),
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
      messenger.showSnackBar(SnackBar(content: Text(strings.playlistUpdated(p.name))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(strings.playlistUpdateFailed(p.name, '$e'))));
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(context.l10n.save)),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.removePlaylistTitle(p.name)),
        content: Text(context.l10n.removePlaylistBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.live),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(playlistsProvider.notifier).remove(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final updated = p.lastUpdated == null
        ? l.neverUpdated
        : l.updatedOn('${intl.DateFormat.yMMMd(l.localeName).format(p.lastUpdated!)} ${formatTime(p.lastUpdated!)}');
    return ListTile(
      leading: Icon(
        p.isXtream ? Icons.dns_outlined : Icons.playlist_play,
        color: widget.active ? AppColors.tally : AppColors.muted,
      ),
      title: Text(p.name),
      subtitle: Text(widget.active ? l.inUse(updated) : updated),
      onTap: widget.active ? null : () => ref.read(activePlaylistIdProvider.notifier).select(p.id),
      trailing: _busy
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : MenuButton<String>(
              tooltip: l.playlistOptions,
              onSelected: (v) async {
                switch (v) {
                  case 'refresh':
                    await _refresh();
                  case 'account':
                    await showAccountSheet(context, p);
                  case 'rename':
                    final name = await _ask(l.renamePlaylist, p.name);
                    if (name != null && name.isNotEmpty) {
                      await ref.read(playlistsProvider.notifier).rename(p, name);
                    }
                  case 'epg':
                    final url = await _ask(l.tvGuideLink, p.epgUrl ?? '', hint: 'https://…/guide.xml.gz');
                    if (url != null) await ref.read(playlistsProvider.notifier).setEpgUrl(p, url);
                  case 'delete':
                    await _delete();
                }
              },
              itemBuilder: (_) => [
                if (p.type != SourceType.m3uFile) PopupMenuItem(value: 'refresh', child: Text(l.updateChannels)),
                if (p.isXtream) PopupMenuItem(value: 'account', child: Text(l.accountInfo)),
                PopupMenuItem(value: 'rename', child: Text(l.rename)),
                PopupMenuItem(value: 'epg', child: Text(l.tvGuideLink)),
                PopupMenuItem(value: 'delete', child: Text(l.remove)),
              ],
            ),
    );
  }
}
