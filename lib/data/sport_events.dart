/// Today's sports on Turkish TV, read from a TV listings site, and
/// the viewer's channels that show them.
library;

import 'channel_merge.dart';
import 'models.dart';

/// One listing: a match or a sports programme.
class SportEvent {
  const SportEvent({
    required this.id,
    required this.start,
    required this.sport,
    required this.title,
    required this.competition,
    required this.channels,
  });

  final String id;
  final DateTime start;

  /// "Futbol", "Basketbol", "Programlar"…
  final String sport;

  /// "Galatasaray - Fenerbahçe".
  final String title;
  final String competition;

  /// Channel names as the site writes them ("S Sport Plus"); empty when
  /// it isn't shown anywhere.
  final List<String> channels;

  Map<String, Object> toJson() => {
    'id': id,
    'start': start.millisecondsSinceEpoch,
    'sport': sport,
    'title': title,
    'competition': competition,
    'channels': channels,
  };

  static SportEvent fromJson(Map<String, dynamic> j) => SportEvent(
    id: j['id'] as String,
    start: DateTime.fromMillisecondsSinceEpoch(j['start'] as int),
    sport: j['sport'] as String,
    title: j['title'] as String,
    competition: j['competition'] as String,
    channels: (j['channels'] as List).cast<String>(),
  );
}

final _row = RegExp(r'<a href="/home/match/(\d+)/(\d{4})/(\d{1,2})/(\d{1,2})/[^"]*"\s+class="event-list__row');
final _time = RegExp(r'class="event-list__time[^"]*"[^>]*>\s*(\d{1,2}):(\d{2})\s*<');
final _name = RegExp(r'class="event-list__name[^"]*"[^>]*>([^<]*)<');
final _league = RegExp(r'class="event-list__league[^"]*"[^>]*>([^<]*)<');
final _sportIcon = RegExp(r'<img[^>]*alt="([^"]*)"[^>]*event-list__sport-icon');
final _alt = RegExp(r'<img[^>]*alt="([^"]*)"');

/// The site's word for "not on TV".
const _noChannel = 'YAYIN YOK';

/// Reads the event rows of the listings home page for the day [day]
/// (other days are skipped). Empty when the page looks different from
/// what this expects.
List<SportEvent> parseSportEvents(String html, DateTime day) {
  final out = <SportEvent>[];
  final seen = <String>{};
  final rows = _row.allMatches(html).toList();
  for (final (i, m) in rows.indexed) {
    final y = int.parse(m.group(2)!), mo = int.parse(m.group(3)!), d = int.parse(m.group(4)!);
    if (y != day.year || mo != day.month || d != day.day) continue;
    final id = m.group(1)!;
    if (!seen.add(id)) continue;
    var end = html.indexOf('</a>', m.end);
    if (end < 0) end = i + 1 < rows.length ? rows[i + 1].start : html.length;
    final card = html.substring(m.end, end);
    final time = _time.firstMatch(card);
    final name = _name.firstMatch(card);
    if (time == null || name == null) continue;
    final title = _text(name.group(1)!);
    if (title.isEmpty) continue;
    // Channel logos appear twice, for phones and for wide screens.
    final mobile = card.indexOf('event-list__channels-mobile');
    final wide = card.indexOf('event-list__channels ', mobile < 0 ? 0 : mobile);
    final logos = mobile < 0 ? '' : card.substring(mobile, wide < 0 ? card.length : wide);
    final channels = <String>[];
    for (final a in _alt.allMatches(logos)) {
      final n = _text(a.group(1)!);
      if (n.isEmpty || _fold(n) == _noChannel || channels.contains(n)) continue;
      channels.add(n);
    }
    out.add(
      SportEvent(
        id: id,
        start: DateTime(y, mo, d, int.parse(time.group(1)!), int.parse(time.group(2)!)),
        sport: _text(_sportIcon.firstMatch(card)?.group(1) ?? ''),
        title: title,
        competition: _text(_league.firstMatch(card)?.group(1) ?? ''),
        channels: channels,
      ),
    );
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

final _numeric = RegExp(r'&#(x?)([0-9a-fA-F]+);');

String _text(String s) => s
    .replaceAllMapped(_numeric, (m) {
      final code = int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
      return code == null || code > 0x10FFFF ? m.group(0)! : String.fromCharCode(code);
    })
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _fold(String s) => baseChannelName(s);

/// Compares channel names across spellings: "S Sport Plus" matches
/// "TR: S SPORT+ FHD", "beIN Sports 1" matches "BEIN SPORTS 1 HD".
/// Notes in brackets ("( YAYIN ZAMANI AKTİF )") are left out.
String channelMatchKey(String name) =>
    baseChannelName(name.replaceAll(_bracketed, ' ').replaceAll('+', ' PLUS ')).replaceAll(' ', '');

final _bracketed = RegExp(r'\([^)]*\)|\[[^\]]*\]');

/// Picks the viewer's channel for an event: the first of its [names] that
/// the list has, preferring Turkish copies, then the best quality. A name
/// the list only has with a 1 after it ("S Sport Plus 1") counts too.
MediaItem? channelFor(List<String> names, Map<String, List<MediaItem>> byKey, Map<String, StreamHealth> health) {
  for (final suffix in const ['', '1']) {
    for (final n in names) {
      final found = byKey['${channelMatchKey(n)}$suffix'];
      if (found == null || found.isEmpty) continue;
      final turkish = found.where(_isTurkish).toList();
      return rankCopies(turkish.isNotEmpty ? turkish : found, health).first;
    }
  }
  return null;
}

final _trPrefix = RegExp(r'^\s*\|?\s*TR\s*[:|]', caseSensitive: false);
final _trGroup = RegExp(r'(^|[^A-Z])TR([^A-Z]|$)|TURK', caseSensitive: false);

bool _isTurkish(MediaItem c) => _trPrefix.hasMatch(c.name) || _trGroup.hasMatch(c.group);

/// Indexes live channels by [channelMatchKey].
Map<String, List<MediaItem>> indexChannels(Iterable<MediaItem> live) {
  final out = <String, List<MediaItem>>{};
  for (final c in live) {
    if (c.url == null) continue;
    final k = channelMatchKey(c.name);
    if (k.isEmpty) continue;
    (out[k] ??= []).add(c);
  }
  return out;
}
