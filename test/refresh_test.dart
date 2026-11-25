import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tally/data/database.dart';
import 'package:tally/data/models.dart';
import 'package:tally/data/repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('an Xtream section that comes back broken keeps what was stored', () async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(db.db.close);
    var seriesBroken = false;
    final server = MockClient((req) async {
      final body = switch (req.url.queryParameters['action']) {
        null => {
          'user_info': {'auth': 1, 'status': 'Active'},
        },
        'get_live_streams' => [
          {'stream_id': 1, 'name': 'News', 'category_id': '1'},
        ],
        'get_vod_streams' => [
          {'stream_id': 2, 'name': 'Film', 'category_id': '2'},
        ],
        // A busy server answers with an error object instead of a list.
        'get_series' => seriesBroken ? {'error': 'busy'} : [
          {'series_id': 3, 'name': 'Show', 'category_id': '3'},
        ],
        _ => <Object>[],
      };
      return http.Response(jsonEncode(body), 200);
    });
    final repo = PlaylistRepository(db, httpClient: server);
    final p = await repo.add(
      const Playlist(id: 0, name: 'X', type: SourceType.xtream, server: 'http://x', username: 'u', password: 'p'),
    );
    await db.saveProgress(
      playlistId: p.id,
      historyKey: 'x:episode:9',
      itemKey: 'x:series:3',
      positionMs: 1000,
      durationMs: 5000,
    );

    seriesBroken = true;
    await repo.refresh(p);

    expect((await db.allItems(p.id, ContentKind.series)).map((i) => i.name), ['Show']);
    expect(await db.history(p.id), hasLength(1));
  });
}
