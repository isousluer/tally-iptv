import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/strings.dart';
import 'models.dart';

class XtreamException implements Exception {
  XtreamException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Minimal client for the Xtream Codes player API.
class XtreamClient {
  XtreamClient({required String server, required this.username, required this.password, http.Client? client})
    : server = normalizeServer(server),
      _http = client ?? http.Client();

  final String server;
  final String username;
  final String password;
  final http.Client _http;

  static String normalizeServer(String raw) {
    var s = raw.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  String get _u => Uri.encodeComponent(username);
  String get _p => Uri.encodeComponent(password);

  String get epgUrl => '$server/xmltv.php?username=$_u&password=$_p';

  Future<dynamic> _get(Map<String, String> params) async {
    final uri = Uri.parse('$server/player_api.php')
        .replace(queryParameters: {'username': username, 'password': password, ...params});
    // Large libraries (50k+ movies) can take a while to generate server-side.
    final res = await _http.get(uri).timeout(const Duration(seconds: 180));
    if (res.statusCode != 200) {
      throw XtreamException(strings.errHttpStatus(res.statusCode));
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } on FormatException {
      throw XtreamException(strings.errInvalidXtream);
    }
  }

  /// Verifies credentials. Throws [XtreamException] when they are rejected.
  Future<void> authenticate() async {
    final data = await _get({});
    final info = data is Map ? data['user_info'] : null;
    if (info is! Map || '${info['auth']}' != '1') {
      throw XtreamException(strings.errLoginRejected);
    }
    final status = '${info['status'] ?? ''}'.toLowerCase();
    if (status.isNotEmpty && status != 'active') {
      throw XtreamException(strings.errAccountStatus(status));
    }
  }

  Future<Map<String, String>> _categories(String action) async {
    final data = await _get({'action': action});
    if (data is! List) return {};
    return {for (final c in data.whereType<Map>()) '${c['category_id']}': '${c['category_name'] ?? 'Uncategorized'}'};
  }

  Future<List<MediaItem>> fetchLive(int playlistId) async {
    final liveCats = await _categories('get_live_categories');
    final streams = await _get({'action': 'get_live_streams'});
    final items = <MediaItem>[];
    for (final s in _list(streams)) {
      final id = '${s['stream_id']}';
      items.add(
        MediaItem(
          playlistId: playlistId,
          kind: ContentKind.live,
          key: 'x:live:$id',
          name: _str(s['name']) ?? 'Channel $id',
          group: liveCats['${s['category_id']}'] ?? 'Uncategorized',
          logo: _str(s['stream_icon']),
          url: '$server/live/$_u/$_p/$id.ts',
          tvgId: _str(s['epg_channel_id']),
          number: int.tryParse('${s['num']}'),
        ),
      );
    }
    return items;
  }

  Future<List<MediaItem>> fetchMovies(int playlistId) async {
    final vodCats = await _categories('get_vod_categories');
    final streams = await _get({'action': 'get_vod_streams'});
    final items = <MediaItem>[];
    for (final s in _list(streams)) {
      final id = '${s['stream_id']}';
      final ext = _str(s['container_extension']) ?? 'mp4';
      items.add(
        MediaItem(
          playlistId: playlistId,
          kind: ContentKind.movie,
          key: 'x:movie:$id',
          name: _str(s['name']) ?? 'Movie $id',
          group: vodCats['${s['category_id']}'] ?? 'Uncategorized',
          logo: _str(s['stream_icon']),
          url: '$server/movie/$_u/$_p/$id.$ext',
          rating: _rating(s['rating']),
          year: _str(s['year']) ?? _yearFrom(_str(s['releasedate'])),
        ),
      );
    }
    return items;
  }

  Future<List<MediaItem>> fetchSeries(int playlistId) async {
    final seriesCats = await _categories('get_series_categories');
    final list = await _get({'action': 'get_series'});
    final items = <MediaItem>[];
    for (final s in _list(list)) {
      final id = '${s['series_id']}';
      items.add(
        MediaItem(
          playlistId: playlistId,
          kind: ContentKind.series,
          key: 'x:series:$id',
          name: _str(s['name']) ?? 'Series $id',
          group: seriesCats['${s['category_id']}'] ?? 'Uncategorized',
          logo: _str(s['cover']),
          rating: _rating(s['rating']),
          year: _str(s['year']) ?? _yearFrom(_str(s['releaseDate'])),
          plot: _str(s['plot']),
        ),
      );
    }
    return items;
  }

  Future<SeriesDetails> seriesInfo(String seriesKey) async {
    final id = seriesKey.split(':').last;
    final data = await _get({'action': 'get_series_info', 'series_id': id});
    if (data is! Map) return const SeriesDetails(seasons: {});
    final info = data['info'] is Map ? data['info'] as Map : const {};
    final seasons = <int, List<Episode>>{};
    final eps = data['episodes'];
    final Iterable<MapEntry<dynamic, dynamic>> entries = eps is Map
        ? eps.entries
        : eps is List
        ? eps.asMap().entries
        : const [];
    for (final e in entries) {
      final list = e.value is List ? e.value as List : const [];
      for (final ep in list.whereType<Map>()) {
        final season = int.tryParse('${ep['season'] ?? e.key}') ?? 1;
        final epId = '${ep['id']}';
        final ext = _str(ep['container_extension']) ?? 'mp4';
        final meta = ep['info'] is Map ? ep['info'] as Map : const {};
        seasons
            .putIfAbsent(season, () => [])
            .add(
              Episode(
                key: 'x:episode:$epId',
                season: season,
                number: int.tryParse('${ep['episode_num']}') ?? 0,
                title: _str(ep['title']) ?? 'Episode ${ep['episode_num']}',
                url: '$server/series/$_u/$_p/$epId.$ext',
                plot: _str(meta['plot']) ?? _str(meta['description']) ?? _str(meta['overview']),
                image: _str(meta['movie_image']),
                duration: _str(meta['duration']),
              ),
            );
      }
    }
    for (final list in seasons.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }
    return SeriesDetails(
      seasons: Map.fromEntries(seasons.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
      plot: _str(info['plot']) ?? _str(info['description']),
      cover: _backdrop(info['backdrop_path']) ?? _str(info['cover']),
      info: _details(info),
    );
  }

  /// Per-channel guide for providers that don't publish a full XMLTV file.
  Future<List<EpgProgram>> shortEpg(MediaItem channel, {int limit = 12}) async {
    final id = channel.key.split(':').last;
    final data = await _get({'action': 'get_short_epg', 'stream_id': id, 'limit': '$limit'});
    final list = data is Map && data['epg_listings'] is List ? data['epg_listings'] as List : const [];
    String? decode(dynamic v) {
      final s = _str(v);
      if (s == null) return null;
      try {
        return utf8.decode(base64.decode(s), allowMalformed: true);
      } on FormatException {
        return s; // some servers send plain text
      }
    }

    DateTime? time(Map m, String tsKey, String textKey) {
      final ts = int.tryParse('${m[tsKey] ?? ''}');
      if (ts != null) return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final text = _str(m[textKey]);
      return text == null ? null : DateTime.tryParse(text);
    }

    final out = <EpgProgram>[];
    for (final m in list.whereType<Map>()) {
      final start = time(m, 'start_timestamp', 'start');
      final stop = time(m, 'stop_timestamp', 'end');
      final title = decode(m['title']);
      if (start == null || stop == null || title == null) continue;
      out.add(
        EpgProgram(
          channelId: channel.tvgId ?? id,
          start: start,
          stop: stop,
          title: title,
          description: decode(m['description']),
        ),
      );
    }
    return out..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Full details of one movie. The movie list doesn't include plots.
  Future<VodInfo> movieInfo(String movieKey) async {
    final id = movieKey.split(':').last;
    final data = await _get({'action': 'get_vod_info', 'vod_id': id});
    final info = data is Map && data['info'] is Map ? data['info'] as Map : const {};
    return _details(info);
  }

  static VodInfo _details(Map info) {
    final secs = int.tryParse('${info['duration_secs'] ?? ''}');
    return VodInfo(
      plot: _str(info['plot']) ?? _str(info['description']),
      genre: _str(info['genre']),
      cast: _str(info['cast']) ?? _str(info['actors']),
      director: _directors(_str(info['director'])),
      duration: secs != null && secs > 0 ? Duration(seconds: secs) : null,
      year: _yearFrom(_str(info['releasedate']) ?? _str(info['releaseDate']) ?? _str(info['year'])),
      rating: _rating(info['rating']),
      backdrop: _backdrop(info['backdrop_path']),
    );
  }

  /// Some providers put the whole crew in the director field, repeating
  /// names ("Christopher Nolan / Christopher Nolan / Emma Thomas / ...").
  /// Drops repeats, and when the list is that long keeps only the first
  /// name, which is the director.
  static String? _directors(String? raw) {
    if (raw == null) return null;
    final names = <String>[];
    for (final n in raw.split(RegExp(r'\s*[/,]\s*'))) {
      final name = n.trim();
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
    }
    if (names.isEmpty) return null;
    return (names.length > 4 ? names.take(1) : names).join(', ');
  }

  static String? _backdrop(dynamic v) {
    if (v is List) return v.isEmpty ? null : _str(v.first);
    return _str(v);
  }

  static Iterable<Map> _list(dynamic v) => v is List ? v.whereType<Map>() : const [];

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
  }

  static String? _rating(dynamic v) {
    final d = double.tryParse('${v ?? ''}');
    if (d == null || d <= 0) return null;
    return d.toStringAsFixed(1);
  }

  static String? _yearFrom(String? v) {
    if (v == null) return null;
    final m = RegExp(r'(19|20)\d{2}').firstMatch(v);
    return m?.group(0);
  }
}
