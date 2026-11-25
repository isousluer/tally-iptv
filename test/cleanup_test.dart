import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tally/data/category_filter.dart';
import 'package:tally/data/database.dart';
import 'package:tally/data/models.dart';
import 'package:tally/data/repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('the cleanup choice hides countries, keeps the rest and follows later updates', () async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(db.db.close);
    var cats = [
      {'category_id': '1', 'category_name': 'TR-SPOR'},
      {'category_id': '2', 'category_name': 'DE-Sports'},
      {'category_id': '3', 'category_name': 'XXX - ADULT'},
      {'category_id': '4', 'category_name': 'YABANCI MUZIK'},
    ];
    final server = MockClient((req) async {
      final body = switch (req.url.queryParameters['action']) {
        null => {
          'user_info': {'auth': 1, 'status': 'Active'},
        },
        'get_live_categories' => cats,
        'get_live_streams' => [
          for (final c in cats) {'stream_id': int.parse(c['category_id']!), 'name': 'Ch', 'category_id': c['category_id']},
        ],
        _ => <Object>[],
      };
      return http.Response(jsonEncode(body), 200);
    });
    final repo = PlaylistRepository(db, httpClient: server);
    final p = await repo.add(
      const Playlist(id: 0, name: 'X', type: SourceType.xtream, server: 'http://x', username: 'u', password: 'p'),
    );

    // Hidden by hand: the wizard must not bring it back.
    await db.setGroupFlags(p.id, ContentKind.live, 'YABANCI MUZIK', hidden: true);
    await db.applyFilter(p.id, const CategoryFilter(countries: {'TR'}, hideAdult: true));
    Future<Map<String, bool>> hidden() async => {
      for (final g in await db.groups(p.id, ContentKind.live)) g.name: g.hidden,
    };
    expect(await hidden(), {'TR-SPOR': false, 'DE-Sports': true, 'XXX - ADULT': true, 'YABANCI MUZIK': true});

    // A new country in the next update follows the same choice.
    cats = [...cats, {'category_id': '5', 'category_name': 'NO-NORWAY'}, {'category_id': '6', 'category_name': 'TR-HABER'}];
    await repo.refresh(p);
    final after = await hidden();
    expect(after['NO-NORWAY'], isTrue);
    expect(after['TR-HABER'], isFalse);

    // "Show everything" undoes the wizard but not the hand-hidden category.
    await db.applyFilter(p.id, const CategoryFilter());
    final all = await hidden();
    expect(all['DE-Sports'], isFalse);
    expect(all['XXX - ADULT'], isFalse);
    expect(all['YABANCI MUZIK'], isTrue);
  });
}
