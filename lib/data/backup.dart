import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../l10n/strings.dart';
import 'database.dart';
import 'models.dart';

/// Settings copied with a backup. The parental PIN is deliberately left out.
const _settingKeys = ['video_fit', 'audio_lang', 'subtitle_lang', 'auto_next', 'auto_refresh'];

/// Writes playlists, favorites, watch history and category choices to JSON.
/// Channel lists themselves aren't included; they're downloaded again.
Future<String> exportBackup(AppDatabase adb, SharedPreferences prefs) async {
  final db = adb.db;
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'tally',
    'format': 1,
    'exported': DateTime.now().toIso8601String(),
    'playlists': await db.query('playlists'),
    'favorites': await db.query('favorites'),
    'history': await db.query('history'),
    'group_prefs': await db.query('group_prefs'),
    'settings': {
      for (final k in _settingKeys)
        if (prefs.get(k) != null) k: prefs.get(k),
    },
  });
}

class RestoreResult {
  RestoreResult(this.playlists, this.skipped, this.alreadyThere);

  /// Playlists whose channels need to be downloaded.
  final List<Playlist> playlists;

  /// Playlists in the backup that the app already had. Their favorites,
  /// history and category settings are still merged.
  final int alreadyThere;

  /// Names of local-file playlists whose file isn't on this device.
  final List<String> skipped;
}

class BackupFormatException implements Exception {
  @override
  String toString() => strings.errNotBackup;
}

/// Merges a backup into the database. Playlists that already exist (same
/// source and login) are reused, so restoring twice doesn't duplicate them.
Future<RestoreResult> importBackup(AppDatabase adb, SharedPreferences prefs, String json) async {
  final Object? data;
  try {
    data = jsonDecode(json);
  } on FormatException {
    throw BackupFormatException();
  }
  // Backups made before the app was renamed say 'slayer-iptv'.
  if (data is! Map || !const {'tally', 'slayer-iptv'}.contains(data['app'])) throw BackupFormatException();

  List<Map<String, Object?>> rows(String key) => [
    for (final r in (data as Map)[key] as List? ?? const []) Map<String, Object?>.from(r as Map),
  ];

  final db = adb.db;
  final existing = await adb.playlists();
  final idMap = <int, int>{};
  final toLoad = <Playlist>[];
  final skipped = <String>[];
  var alreadyThere = 0;

  await db.transaction((txn) async {
    for (final row in rows('playlists')) {
      final oldId = row['id'] as int;
      final p = Playlist.fromRow(row);
      if (p.type == SourceType.m3uFile && (p.url == null || !File(p.url!).existsSync())) {
        skipped.add(p.name);
        continue;
      }
      final same = existing.where(
        (e) => e.type == p.type && e.url == p.url && e.server == p.server && e.username == p.username,
      );
      if (same.isNotEmpty) {
        idMap[oldId] = same.first.id;
        alreadyThere++;
        continue;
      }
      final fresh = Playlist.fromRow({...row, 'last_updated': null});
      final id = await txn.insert('playlists', fresh.toRow());
      idMap[oldId] = id;
      toLoad.add(Playlist.fromRow({...fresh.toRow(), 'id': id}));
    }

    for (final table in ['favorites', 'history', 'group_prefs']) {
      for (final row in rows(table)) {
        final id = idMap[row['playlist_id']];
        if (id == null) continue;
        await txn.insert(table, {...row, 'playlist_id': id}, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  });

  final settings = data['settings'];
  if (settings is Map) {
    for (final MapEntry(:key, :value) in settings.entries) {
      if (!_settingKeys.contains(key)) continue;
      if (value is bool) await prefs.setBool(key as String, value);
      if (value is String) await prefs.setString(key as String, value);
    }
  }
  return RestoreResult(toLoad, skipped, alreadyThere);
}
