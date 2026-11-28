import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/models.dart';
import 'package:tally/data/sport_events.dart';

String _card(String id, String date, String time, String sport, String name, String league, List<String> channels) {
  String logo(String c) =>
      '<div class="event-list__channel-mobile"><picture><img src="x.png" alt="$c" title="$c" '
      'width="24" height="24" class="img-lazy"></picture></div>';
  return '<a href="/home/match/$id/$date/slug-hangi-kanalda" class="event-list__row flex items-center" data-v-1>'
      '<div class="event-list__time-col flex"><picture><img src="s.svg" alt="$sport" title="$sport" width="20" '
      'class="img-lazy event-list__sport-icon blur-up"></picture>'
      '<span class="event-list__time text-xl-bold" data-v-1>$time</span></div>'
      '<div class="event-list__info col"><p class="event-list__name text-xl-bold" data-v-1>$name</p>'
      '<p class="event-list__league text-md" data-v-1>$league </p>'
      '<div class="event-list__channels-mobile flex lt-sm" data-v-1>${channels.map(logo).join()}</div></div>'
      '<div class="event-list__channels flex gt-xs" data-v-1>${channels.map(logo).join()}</div></a>';
}

MediaItem _ch(String name, {String group = 'TR SPOR', String? key}) =>
    MediaItem(playlistId: 1, kind: ContentKind.live, key: key ?? name, name: name, group: group, url: 'http://x/$name');

void main() {
  final day = DateTime(2026, 11, 25);
  final html =
      '<div class="featured"><a href="/home/match/9/2026/11/25/x" class="featured__link">ignored</a></div>'
      '${_card('1', '2026/11/25', '20:45', 'Futbol', 'Galatasaray - Fenerbah&#xE7;e', 'S&#xFC;per Lig', ['beIN Sports 1', 'beIN Sports 1'])}'
      '${_card('2', '2026/11/25', '18:00', 'Basketbol', 'Anadolu Efes - Real Madrid', 'Euroleague', ['S Sport Plus', 'S Sport'])}'
      '${_card('3', '2026/11/25', '15:00', 'Futbol', 'Shakhtar - Fenerbahçe', 'UEFA Gençlik Ligi', ['Yayın Yok'])}'
      '${_card('4', '2026/11/26', '21:00', 'Futbol', 'Tomorrow - Match', 'Lig', ['TRT Spor'])}'
      '${_card('2', '2026/11/25', '18:00', 'Basketbol', 'Anadolu Efes - Real Madrid', 'Euroleague', ['S Sport Plus'])}';

  test('reads today\'s rows in time order, once each', () {
    final events = parseSportEvents(html, day);
    expect(events.map((e) => e.id), ['3', '2', '1']);
    final efes = events[1];
    expect(efes.start, DateTime(2026, 11, 25, 18));
    expect(efes.sport, 'Basketbol');
    expect(efes.title, 'Anadolu Efes - Real Madrid');
    expect(efes.competition, 'Euroleague');
    expect(efes.channels, ['S Sport Plus', 'S Sport']);
    expect(events[2].title, 'Galatasaray - Fenerbahçe');
    expect(events[2].competition, 'Süper Lig');
    expect(events[2].channels, ['beIN Sports 1']);
  });

  test('"Yayın Yok" means no channel', () {
    expect(parseSportEvents(html, day).first.channels, isEmpty);
  });

  test('a page without rows gives nothing', () {
    expect(parseSportEvents('<html><body>Bakımdayız</body></html>', day), isEmpty);
  });

  test('channel names match across spellings', () {
    expect(channelMatchKey('S Sport Plus'), channelMatchKey('TR: S SPORT+ FHD'));
    expect(channelMatchKey('beIN Sports 1'), channelMatchKey('TR | BEIN SPORTS 1 HD'));
    expect(channelMatchKey('TRT Spor Yildiz'), channelMatchKey('TRT SPOR YILDIZ'));
    expect(channelMatchKey('S Sport'), isNot(channelMatchKey('S Sport 2')));
  });

  test('prefers a Turkish copy, then the best quality', () {
    final live = [
      _ch('DE: BEIN SPORTS 1 FHD', group: 'DE SPORT'),
      _ch('TR: BEIN SPORTS 1 SD'),
      _ch('TR: BEIN SPORTS 1 FHD'),
      _ch('TR: S SPORT'),
    ];
    final byKey = indexChannels(live);
    expect(channelFor(['beIN Sports 1'], byKey, const {})!.name, 'TR: BEIN SPORTS 1 FHD');
    expect(channelFor(['S Sport Plus', 'S Sport'], byKey, const {})!.name, 'TR: S SPORT');
    expect(channelFor(['Tivibu Spor'], byKey, const {}), isNull);
  });

  test('a note in brackets and a trailing 1 still match', () {
    final byKey = indexChannels([_ch('TR: S Sport Plus 1 ( YAYIN ZAMANI AKTİF )'), _ch('TR: BEIN SPORTS 1 HD')]);
    expect(channelFor(['S Sport Plus'], byKey, const {})!.name, 'TR: S Sport Plus 1 ( YAYIN ZAMANI AKTİF )');
    // The exact name wins over the one with a 1 after it.
    final both = indexChannels([_ch('TR: S SPORT 1'), _ch('TR: S SPORT')]);
    expect(channelFor(['S Sport'], both, const {})!.name, 'TR: S SPORT');
    expect(channelFor(['S Sport 2'], byKey, const {}), isNull);
    // S Sport and S Sport Plus are different channels.
    expect(channelFor(['S Sport'], byKey, const {}), isNull);
    final sport = indexChannels([_ch('TR: S SPORT HD')]);
    expect(channelFor(['S Sport Plus'], sport, const {}), isNull);
  });
}
