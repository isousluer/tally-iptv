import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'models.dart';

/// SQLite storage for playlists, items, favorites, history and guide data.
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  /// Opens the app's database, or the one at [path] (tests pass
  /// `inMemoryDatabasePath`).
  static Future<AppDatabase> open({String? path}) async {
    final DatabaseFactory factory;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }
    if (path == null) {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      path = p.join(dir.path, 'tally.db');
    }
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, _) async {
          await _create(db);
          await _createGroupPrefs(db);
          await _createChannelLists(db);
        },
        onUpgrade: (db, from, _) async {
          if (from < 2) await _createGroupPrefs(db);
          if (from < 3) await db.execute('ALTER TABLE items ADD COLUMN archive_days INTEGER');
          if (from < 4) await _createChannelLists(db);
        },
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
        rating TEXT, year TEXT, plot TEXT,
        archive_days INTEGER
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

  /// Per-category choices: hidden, locked behind the parental PIN, and order.
  static Future<void> _createGroupPrefs(Database db) => db.execute('''
      CREATE TABLE group_prefs(
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        kind TEXT NOT NULL,
        grp TEXT NOT NULL,
        hidden INTEGER NOT NULL DEFAULT 0,
        locked INTEGER NOT NULL DEFAULT 0,
        position INTEGER,
        PRIMARY KEY(playlist_id, kind, grp)
      )''');

  /// The viewer's own channel lists. Items are kept by key, like favorites,
  /// so they survive playlist updates.
  static Future<void> _createChannelLists(Database db) async {
    await db.execute('''
      CREATE TABLE channel_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        position INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE channel_list_items(
        list_id INTEGER NOT NULL REFERENCES channel_lists(id) ON DELETE CASCADE,
        ukey TEXT NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY(list_id, ukey)
      )''');
  }

  // ---------------------------------------------------------------- playlists

  Future<List<Playlist>> playlists() async =>
      (await db.query('playlists', orderBy: 'id')).map(Playlist.fromRow).toList();

  Future<int> insertPlaylist(Playlist p) => db.insert('playlists', p.toRow());

  Future<void> updatePlaylist(Playlist p) => db.update('playlists', p.toRow(), where: 'id = ?', whereArgs: [p.id]);

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

  /// Categories in the user's order (new ones go last, in playlist order),
  /// with their hidden/locked flags.
  Future<List<GroupInfo>> groups(int playlistId, ContentKind kind) async {
    final rows = await db.rawQuery(
      'SELECT i.grp, MIN(i.id) AS first, COUNT(*) AS n, '
      'COALESCE(g.hidden, 0) AS hidden, COALESCE(g.locked, 0) AS locked, g.position '
      'FROM items i LEFT JOIN group_prefs g '
      'ON g.playlist_id = i.playlist_id AND g.kind = i.kind AND g.grp = i.grp '
      'WHERE i.playlist_id = ? AND i.kind = ? '
      'GROUP BY i.grp ORDER BY COALESCE(g.position, 1000000000 + MIN(i.id))',
      [playlistId, kind.dbValue],
    );
    return rows
        .map(
          (r) => GroupInfo(
            name: r['grp'] as String,
            count: r['n'] as int,
            hidden: r['hidden'] == 1,
            locked: r['locked'] == 1,
          ),
        )
        .toList();
  }

  Future<void> _ensureGroupPref(DatabaseExecutor ex, int playlistId, ContentKind kind, String group) => ex.insert(
    'group_prefs',
    {'playlist_id': playlistId, 'kind': kind.dbValue, 'grp': group},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  Future<void> setGroupFlags(int playlistId, ContentKind kind, String group, {bool? hidden, bool? locked}) async {
    await _ensureGroupPref(db, playlistId, kind, group);
    await db.update(
      'group_prefs',
      {if (hidden != null) 'hidden': hidden ? 1 : 0, if (locked != null) 'locked': locked ? 1 : 0},
      where: 'playlist_id = ? AND kind = ? AND grp = ?',
      whereArgs: [playlistId, kind.dbValue, group],
    );
  }

  Future<void> setGroupOrder(int playlistId, ContentKind kind, List<String> order) async {
    await db.transaction((txn) async {
      for (final (i, g) in order.indexed) {
        await _ensureGroupPref(txn, playlistId, kind, g);
        await txn.update(
          'group_prefs',
          {'position': i},
          where: 'playlist_id = ? AND kind = ? AND grp = ?',
          whereArgs: [playlistId, kind.dbValue, g],
        );
      }
    });
  }

  Future<bool> isGroupLocked(int playlistId, ContentKind kind, String group) async {
    final r = await db.query(
      'group_prefs',
      columns: ['locked'],
      where: 'playlist_id = ? AND kind = ? AND grp = ? AND locked = 1',
      whereArgs: [playlistId, kind.dbValue, group],
    );
    return r.isNotEmpty;
  }

  Future<void> resetGroupPrefs(int playlistId, ContentKind kind) => db.update(
    'group_prefs',
    {'hidden': 0, 'position': null},
    where: 'playlist_id = ? AND kind = ?',
    whereArgs: [playlistId, kind.dbValue],
  );

  /// Hides items of hidden categories, and of locked ones unless unlocked.
  static String _groupFilter(bool includeLocked) =>
      'NOT EXISTS(SELECT 1 FROM group_prefs g WHERE g.playlist_id = i.playlist_id AND g.kind = i.kind '
      'AND g.grp = i.grp AND (g.hidden = 1${includeLocked ? '' : ' OR g.locked = 1'}))';

  Future<int> count(int playlistId, ContentKind kind) async {
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM items WHERE playlist_id = ? AND kind = ?', [
      playlistId,
      kind.dbValue,
    ]);
    return r.first['c'] as int;
  }

  Future<List<MediaItem>> items(
    int playlistId,
    ContentKind kind, {
    String? group,
    bool favoritesOnly = false,
    String? search,
    bool includeLocked = false,
    ItemSort sort = ItemSort.playlist,
    int limit = 5000,
  }) async {
    final where = <String>['i.playlist_id = ?', 'i.kind = ?'];
    final args = <Object?>[playlistId, kind.dbValue];
    if (group != null) {
      where.add('i.grp = ?');
      args.add(group);
    } else {
      where.add(_groupFilter(includeLocked));
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('i.name LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (favoritesOnly) {
      where.add('EXISTS(SELECT 1 FROM favorites f WHERE f.playlist_id = i.playlist_id AND f.ukey = i.ukey)');
    }
    final rows = await db.rawQuery(
      'SELECT i.*, $_favExpr FROM items i WHERE ${where.join(' AND ')} ORDER BY ${_orderBy(sort)} LIMIT ?',
      [...args, limit],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  static String _orderBy(ItemSort s) => switch (s) {
    ItemSort.playlist => 'i.id',
    ItemSort.number => 'i.num IS NULL, i.num, i.id',
    ItemSort.nameAsc => 'i.name COLLATE NOCASE, i.id',
    ItemSort.nameDesc => 'i.name COLLATE NOCASE DESC, i.id',
    ItemSort.rating => 'COALESCE(CAST(i.rating AS REAL), 0) DESC, i.id',
    ItemSort.year => "COALESCE(i.year, '') DESC, i.id",
  };

  Future<MediaItem?> itemByKey(int playlistId, String key) async {
    final rows = await db.rawQuery(
      'SELECT i.*, $_favExpr FROM items i WHERE i.playlist_id = ? AND i.ukey = ? LIMIT 1',
      [playlistId, key],
    );
    return rows.isEmpty ? null : MediaItem.fromRow(rows.first);
  }

  /// The live channel with this number, leaving out hidden categories and
  /// locked ones unless they are open.
  Future<MediaItem?> liveByNumber(int playlistId, int number, {bool includeLocked = false}) async {
    final rows = await db.rawQuery(
      'SELECT i.*, $_favExpr FROM items i WHERE i.playlist_id = ? AND i.kind = ? AND i.num = ? '
      'AND ${_groupFilter(includeLocked)} ORDER BY i.id LIMIT 1',
      [playlistId, ContentKind.live.dbValue, number],
    );
    return rows.isEmpty ? null : MediaItem.fromRow(rows.first);
  }

  // ---------------------------------------------------------------- favorites

  Future<void> setFavorite(int playlistId, String key, bool value) async {
    if (value) {
      await db.insert('favorites', {
        'playlist_id': playlistId,
        'ukey': key,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('favorites', where: 'playlist_id = ? AND ukey = ?', whereArgs: [playlistId, key]);
    }
  }

  Future<List<MediaItem>> favorites(int playlistId, {bool includeLocked = false}) async {
    final rows = await db.rawQuery(
      'SELECT i.*, 1 AS fav FROM favorites f JOIN items i '
      'ON i.playlist_id = f.playlist_id AND i.ukey = f.ukey '
      'WHERE f.playlist_id = ? AND ${_groupFilter(includeLocked)} ORDER BY f.added_at DESC',
      [playlistId],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  // ------------------------------------------------------------ channel lists

  /// Lists of a playlist in the viewer's order, with how many of their
  /// channels the playlist still has.
  Future<List<ChannelList>> channelLists(int playlistId) async {
    final rows = await db.rawQuery(
      'SELECT l.id, l.name, (SELECT COUNT(*) FROM channel_list_items c JOIN items i '
      'ON i.playlist_id = l.playlist_id AND i.ukey = c.ukey WHERE c.list_id = l.id) AS n '
      'FROM channel_lists l WHERE l.playlist_id = ? ORDER BY l.position, l.id',
      [playlistId],
    );
    return [for (final r in rows) ChannelList(id: r['id'] as int, name: r['name'] as String, count: r['n'] as int)];
  }

  Future<int> createChannelList(int playlistId, String name) async {
    final r = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS p FROM channel_lists WHERE playlist_id = ?',
      [playlistId],
    );
    return db.insert('channel_lists', {'playlist_id': playlistId, 'name': name, 'position': r.first['p']});
  }

  Future<void> renameChannelList(int id, String name) =>
      db.update('channel_lists', {'name': name}, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteChannelList(int id) => db.delete('channel_lists', where: 'id = ?', whereArgs: [id]);

  Future<void> reorderChannelLists(List<int> ids) => db.transaction((txn) async {
    for (final (i, id) in ids.indexed) {
      await txn.update('channel_lists', {'position': i}, where: 'id = ?', whereArgs: [id]);
    }
  });

  /// Channels of a list in its order, leaving out locked categories unless
  /// they are open. Hidden categories still show: the viewer chose these.
  Future<List<MediaItem>> channelListItems(int playlistId, int listId, {bool includeLocked = false}) async {
    final locked = includeLocked
        ? ''
        : 'AND NOT EXISTS(SELECT 1 FROM group_prefs g WHERE g.playlist_id = i.playlist_id AND g.kind = i.kind '
              'AND g.grp = i.grp AND g.locked = 1) ';
    final rows = await db.rawQuery(
      'SELECT i.*, $_favExpr FROM channel_list_items c JOIN items i ON i.playlist_id = ? AND i.ukey = c.ukey '
      'WHERE c.list_id = ? ${locked}ORDER BY c.position',
      [playlistId, listId],
    );
    return rows.map(MediaItem.fromRow).toList();
  }

  /// Ids of the lists of [playlistId] that hold the channel [key].
  Future<Set<int>> listsWith(int playlistId, String key) async {
    final rows = await db.rawQuery(
      'SELECT c.list_id FROM channel_list_items c JOIN channel_lists l ON l.id = c.list_id '
      'WHERE l.playlist_id = ? AND c.ukey = ?',
      [playlistId, key],
    );
    return {for (final r in rows) r['list_id'] as int};
  }

  /// Adds the channel at the end of the list, or takes it out.
  Future<void> setInChannelList(int listId, String key, bool value) async {
    if (!value) {
      await db.delete('channel_list_items', where: 'list_id = ? AND ukey = ?', whereArgs: [listId, key]);
      return;
    }
    final r = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS p FROM channel_list_items WHERE list_id = ?',
      [listId],
    );
    await db.insert('channel_list_items', {
      'list_id': listId,
      'ukey': key,
      'position': r.first['p'],
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> reorderChannelListItems(int listId, List<String> keys) => db.transaction((txn) async {
    for (final (i, key) in keys.indexed) {
      await txn.update(
        'channel_list_items',
        {'position': i},
        where: 'list_id = ? AND ukey = ?',
        whereArgs: [listId, key],
      );
    }
  });

  // ------------------------------------------------------------------ history

  Future<void> saveProgress({
    required int playlistId,
    required String historyKey,
    required String itemKey,
    String? title,
    String? url,
    required int positionMs,
    required int durationMs,
  }) => db.insert('history', {
    'playlist_id': playlistId,
    'hkey': historyKey,
    'item_key': itemKey,
    'title': title,
    'url': url,
    'position_ms': positionMs,
    'duration_ms': durationMs,
    'updated_at': DateTime.now().millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<int> progressOf(int playlistId, String historyKey) async {
    final r = await db.query(
      'history',
      columns: ['position_ms'],
      where: 'playlist_id = ? AND hkey = ?',
      whereArgs: [playlistId, historyKey],
    );
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
        .map(
          (r) => (
            WatchEntry(
              item: MediaItem.fromRow(r),
              positionMs: r['position_ms'] as int,
              durationMs: r['duration_ms'] as int,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
              historyKey: r['hkey'] as String,
              title: r['h_title'] as String?,
            ),
            r['h_url'] as String?,
          ),
        )
        .toList();
  }

  Future<void> clearHistory(int playlistId) => db.delete('history', where: 'playlist_id = ?', whereArgs: [playlistId]);

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
    final rows = await db.rawQuery('SELECT * FROM epg WHERE playlist_id = ? AND start <= ? AND stop > ?', [
      playlistId,
      ms,
      ms,
    ]);
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
