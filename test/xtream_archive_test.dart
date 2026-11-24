import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tally/data/models.dart';
import 'package:tally/data/xtream_client.dart';

void main() {
  final channel = const MediaItem(
    playlistId: 1,
    kind: ContentKind.live,
    key: 'x:live:42',
    name: 'News',
    archiveDays: 3,
  );

  int ts(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
  String b64(String s) => base64.encode(utf8.encode(s));

  test('lists recorded programs newest first with timeshift addresses', () async {
    final now = DateTime.utc(2026, 11, 24, 20);
    final client = MockClient((req) async {
      final action = req.url.queryParameters['action'];
      if (action == null) {
        // Server clock is UTC+3.
        return http.Response(
          jsonEncode({
            'user_info': {'auth': 1},
            'server_info': {'time_now': '2026-11-24 23:00:00', 'timestamp_now': ts(now)},
          }),
          200,
        );
      }
      expect(action, 'get_simple_data_table');
      expect(req.url.queryParameters['stream_id'], '42');
      Map<String, Object> p(DateTime start, int minutes, String title, int archive) => {
        'title': b64(title),
        'start_timestamp': '${ts(start)}',
        'stop_timestamp': '${ts(start.add(Duration(minutes: minutes)))}',
        'has_archive': archive,
      };
      return http.Response(
        jsonEncode({
          'epg_listings': [
            p(DateTime.utc(2026, 11, 24, 17), 60, 'Evening news', 1),
            p(DateTime.utc(2026, 11, 24, 18), 30, 'Not recorded', 0),
            p(DateTime.utc(2026, 11, 24, 18, 30), 90, 'Film', 1),
            p(DateTime.utc(2026, 11, 24, 20), 60, 'On now', 1),
            p(DateTime.utc(2026, 11, 20, 18), 60, 'Too old', 1),
          ],
        }),
        200,
      );
    });
    final x = XtreamClient(server: 'http://tv.example:8080/', username: 'u', password: 'p w', client: client);
    final list = await x.archive(channel, now: now.toLocal());
    expect(list.map((e) => e.$1.title), ['Film', 'Evening news']);
    // 18:30 UTC is 21:30 on the server.
    expect(list.first.$2, 'http://tv.example:8080/timeshift/u/p%20w/90/2026-11-24:21-30/42.ts');
  });
}
