import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

/// SQLite storage for playlists, items, favorites, history and guide data.
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  static Future<AppDatabase> open() async {
    final DatabaseFactory factory;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final path = p.join(dir.path, 'slayer_iptv.db');
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, _) => _create(db),
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _create(Database db) async {
    await db.execute('''
      CREATE TABLE playlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        url TEXT, server TEXT, username TEXT, password TEXT,
        epg_url TEXT,
        last_updated INTEGER
      )''');
    await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        kind TEXT NOT NULL,
        ukey TEXT NOT NULL,
        name TEXT NOT NULL,
        grp TEXT NOT NULL DEFAULT '',
        logo TEXT, url TEXT, tvg_id TEXT, num INTEGER,
        rating TEXT, year TEXT, plot TEXT
      )''');
    await db.execute('CREATE INDEX idx_items_browse ON items(playlist_id, kind, grp)');
    await db.execute('CREATE UNIQUE INDEX idx_items_key ON items(playlist_id, ukey)');
    await db.execute('''
      CREATE TABLE favorites(
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        ukey TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY(playlist_id, ukey)
      )''');
    await db.execute('''
      CREATE TABLE history(
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        hkey TEXT NOT NULL,
        item_key TEXT NOT NULL,
        title TEXT,
        url TEXT,
        position_ms INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY(playlist_id, hkey)
      )''');
    await db.execute('''
      CREATE TABLE epg(
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        channel_id TEXT NOT NULL COLLATE NOCASE,
        start INTEGER NOT NULL,
        stop INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT
      )''');
    await db.execute('CREATE INDEX idx_epg ON epg(playlist_id, channel_id, start)');
  }

  // ---------------------------------------------------------------- playlists

  Future<List<Playlist>> playlists() async =>
      (await db.query('playlists', orderBy: 'id')).map(Playlist.fromRow).toList();

  Future<int> insertPlaylist(Playlist p) => db.insert('playlists', p.toRow());

  Future<void> updatePlaylist(Playlist p) =>
      db.update('playlists', p.toRow(), where: 'id = ?', whereArgs: [p.id]);

  Future<void> deletePlaylist(int id) => db.delete('playlists', where: 'id = ?', whereArgs: [id]);

  // -------------------------------------------------------------------- items

  /// Replaces all items of a playlist. Favorites and history are keyed by the
  /// stable `ukey`, so they survive a refresh.
  Future<void> replaceItems(int playlistId, List<MediaItem> items) async {
    await db.transaction((txn) async {
      await txn.delete('items', where: 'playlist_id = ?', whereArgs: [playlistId]);
      const chunk = 500;
      for (var i = 0; i < items.length; i += chunk) {
        final batch = txn.batch();
        for (final item in items.skip(i).take(chunk)) {
          batch.insert('items', item.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      }
    });
  }

  static const _favExpr =
      'EXISTS(SELECT 1 FROM favorites f WHERE f.playlist_id = i.playlist_id AND f.ukey = i.ukey) AS fav';

  Future<List<String>> groups(int playlistId, ContentKind kind) async {
    final rows = await db.rawQuery(
      'SELECT grp, MIN(id) AS first FROM items WHERE playlist_id = ? AND kind = ? '
      'GROUP BY grp ORDER BY first',
      [playlistId, kind.dbValue],
    );
    return rows.map((r) => r['grp'] as String).toList();
  }

  Future<int> count(int playlistId, ContentKind kind) async {
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM items WHERE playlist_id = ? AND kind = ?',
      [playlistId, kind.dbValue],
    );
    return r.first['c'] as int;
  }

  Future<List<MediaItem>> items(
    int playlistId,
    ContentKind kind, {
    String? group,
    bool favoritesOnly = false,
    String? search,
    int limit = 5000,
  }) async {
    final where = <String>['i.playlist_id = ?', 'i.kind = ?'];
    final args = <Object?>[playlistId, kind.dbValue];
    if (group != null) {
      where.add('i.grp = ?');
      args.add(group);
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('i.name LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (favoritesOnly) {
      where.add('EXISTS(SELECT 1 FROM favorites f WHERE f.playlist_id = i.playlist_id AND f.ukey = i.ukey)');
    }
    final rows = await db.rawQuery(
      'SELECT i.*, $_favExpr FROM items i WHERE ${where.join(' AND ')} ORDER BY i.id LIMIT ?',
      [...args, limit],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  Future<MediaItem?> itemByKey(int playlistId, String key) async {
    final rows = await db.rawQuery(
      'SELECT i.*, $_favExpr FROM items i WHERE i.playlist_id = ? AND i.ukey = ? LIMIT 1',
      [playlistId, key],
    );
    return rows.isEmpty ? null : MediaItem.fromRow(rows.first);
  }

  // ---------------------------------------------------------------- favorites

  Future<void> setFavorite(int playlistId, String key, bool value) async {
    if (value) {
      await db.insert(
        'favorites',
        {'playlist_id': playlistId, 'ukey': key, 'added_at': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete('favorites', where: 'playlist_id = ? AND ukey = ?', whereArgs: [playlistId, key]);
    }
  }

  Future<List<MediaItem>> favorites(int playlistId) async {
    final rows = await db.rawQuery(
      'SELECT i.*, 1 AS fav FROM favorites f JOIN items i '
      'ON i.playlist_id = f.playlist_id AND i.ukey = f.ukey '
      'WHERE f.playlist_id = ? ORDER BY f.added_at DESC',
      [playlistId],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  // ------------------------------------------------------------------ history

  Future<void> saveProgress({
    required int playlistId,
    required String historyKey,
    required String itemKey,
    String? title,
    String? url,
    required int positionMs,
    required int durationMs,
  }) =>
      db.insert(
        'history',
        {
          'playlist_id': playlistId,
          'hkey': historyKey,
          'item_key': itemKey,
          'title': title,
          'url': url,
          'position_ms': positionMs,
          'duration_ms': durationMs,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<int> progressOf(int playlistId, String historyKey) async {
    final r = await db.query('history',
        columns: ['position_ms'],
        where: 'playlist_id = ? AND hkey = ?',
        whereArgs: [playlistId, historyKey]);
    return r.isEmpty ? 0 : r.first['position_ms'] as int;
  }

  Future<List<(WatchEntry, String?)>> history(int playlistId, {int limit = 50}) async {
    final rows = await db.rawQuery(
      'SELECT h.hkey, h.position_ms, h.duration_ms, h.updated_at, h.title AS h_title, h.url AS h_url, '
      'i.*, $_favExpr FROM history h JOIN items i '
      'ON i.playlist_id = h.playlist_id AND i.ukey = h.item_key '
      'WHERE h.playlist_id = ? ORDER BY h.updated_at DESC LIMIT ?',
      [playlistId, limit],
    );
    return rows
        .map((r) => (
              WatchEntry(
                item: MediaItem.fromRow(r),
                positionMs: r['position_ms'] as int,
                durationMs: r['duration_ms'] as int,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
                historyKey: r['hkey'] as String,
                title: r['h_title'] as String?,
              ),
              r['h_url'] as String?,
            ))
        .toList();
  }

  Future<void> clearHistory(int playlistId) =>
      db.delete('history', where: 'playlist_id = ?', whereArgs: [playlistId]);

  // ---------------------------------------------------------------------- epg

  Future<Set<String>> tvgIds(int playlistId) async {
    final rows = await db.rawQuery(
      "SELECT DISTINCT tvg_id FROM items WHERE playlist_id = ? AND kind = 'live' AND tvg_id IS NOT NULL",
      [playlistId],
    );
    return rows.map((r) => r['tvg_id'] as String).toSet();
  }

  Future<void> replaceEpg(int playlistId, List<EpgProgram> programs) async {
    await db.transaction((txn) async {
      await txn.delete('epg', where: 'playlist_id = ?', whereArgs: [playlistId]);
      const chunk = 1000;
      for (var i = 0; i < programs.length; i += chunk) {
        final batch = txn.batch();
        for (final pr in programs.skip(i).take(chunk)) {
          batch.insert('epg', {
            'playlist_id': playlistId,
            'channel_id': pr.channelId,
            'start': pr.start.millisecondsSinceEpoch,
            'stop': pr.stop.millisecondsSinceEpoch,
            'title': pr.title,
            'description': pr.description,
          });
        }
        await batch.commit(noResult: true);
      }
    });
  }

  /// Current program of every channel in the playlist, keyed by lowercase id.
  Future<Map<String, EpgProgram>> nowPlayingAll(int playlistId, DateTime at) async {
    final ms = at.millisecondsSinceEpoch;
    final rows = await db.rawQuery(
      'SELECT * FROM epg WHERE playlist_id = ? AND start <= ? AND stop > ?',
      [playlistId, ms, ms],
    );
    return {for (final r in rows) (r['channel_id'] as String).toLowerCase(): _program(r)};
  }

  /// Current program for each of [channelIds] at [at].
  Future<Map<String, EpgProgram>> nowPlaying(int playlistId, Iterable<String> channelIds, DateTime at) async {
    final ids = channelIds.toSet().toList();
    if (ids.isEmpty) return {};
    final out = <String, EpgProgram>{};
    final ms = at.millisecondsSinceEpoch;
    const chunk = 500;
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.skip(i).take(chunk).toList();
      final marks = List.filled(part.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT * FROM epg WHERE playlist_id = ? AND start <= ? AND stop > ? AND channel_id IN ($marks)',
        [playlistId, ms, ms, ...part],
      );
      for (final r in rows) {
        final pr = _program(r);
        out[pr.channelId.toLowerCase()] = pr;
      }
    }
    return out;
  }

  Future<List<EpgProgram>> schedule(int playlistId, String channelId, DateTime from, {int limit = 30}) async {
    final rows = await db.query(
      'epg',
      where: 'playlist_id = ? AND channel_id = ? AND stop > ?',
      whereArgs: [playlistId, channelId, from.millisecondsSinceEpoch],
      orderBy: 'start',
      limit: limit,
    );
    return rows.map(_program).toList();
  }

  static EpgProgram _program(Map<String, Object?> r) => EpgProgram(
        channelId: r['channel_id'] as String,
        start: DateTime.fromMillisecondsSinceEpoch(r['start'] as int),
        stop: DateTime.fromMillisecondsSinceEpoch(r['stop'] as int),
        title: r['title'] as String,
        description: r['description'] as String?,
      );
}
