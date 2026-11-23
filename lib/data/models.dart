/// Core data models used across Slayer IPTV.
library;

enum SourceType { m3uUrl, m3uFile, xtream }

enum ContentKind { live, movie, series }

extension ContentKindX on ContentKind {
  String get dbValue => name;
  static ContentKind parse(String v) =>
      ContentKind.values.firstWhere((k) => k.name == v, orElse: () => ContentKind.live);
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.server,
    this.username,
    this.password,
    this.epgUrl,
    this.lastUpdated,
  });

  final int id;
  final String name;
  final SourceType type;

  /// M3U URL or local file path.
  final String? url;

  /// Xtream Codes credentials.
  final String? server;
  final String? username;
  final String? password;

  /// XMLTV guide URL (optional, auto-detected when possible).
  final String? epgUrl;
  final DateTime? lastUpdated;

  bool get isXtream => type == SourceType.xtream;

  Map<String, Object?> toRow() => {
        'name': name,
        'type': type.name,
        'url': url,
        'server': server,
        'username': username,
        'password': password,
        'epg_url': epgUrl,
        'last_updated': lastUpdated?.millisecondsSinceEpoch,
      };

  factory Playlist.fromRow(Map<String, Object?> r) => Playlist(
        id: r['id'] as int,
        name: r['name'] as String,
        type: SourceType.values.firstWhere((t) => t.name == r['type'],
            orElse: () => SourceType.m3uUrl),
        url: r['url'] as String?,
        server: r['server'] as String?,
        username: r['username'] as String?,
        password: r['password'] as String?,
        epgUrl: r['epg_url'] as String?,
        lastUpdated: r['last_updated'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['last_updated'] as int),
      );

  Playlist copyWith({String? name, String? epgUrl, DateTime? lastUpdated}) => Playlist(
        id: id,
        name: name ?? this.name,
        type: type,
        url: url,
        server: server,
        username: username,
        password: password,
        epgUrl: epgUrl ?? this.epgUrl,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// A playable or browsable entry: live channel, movie, or series.
class MediaItem {
  const MediaItem({
    this.id = 0,
    required this.playlistId,
    required this.kind,
    required this.key,
    required this.name,
    this.group = '',
    this.logo,
    this.url,
    this.tvgId,
    this.number,
    this.rating,
    this.year,
    this.plot,
    this.favorite = false,
  });

  final int id;
  final int playlistId;
  final ContentKind kind;

  /// Stable identity across refreshes (stream URL or Xtream id).
  final String key;
  final String name;
  final String group;
  final String? logo;

  /// Direct stream URL. Null for series (episodes are loaded on demand).
  final String? url;
  final String? tvgId;
  final int? number;
  final String? rating;
  final String? year;
  final String? plot;
  final bool favorite;

  Map<String, Object?> toRow() => {
        'playlist_id': playlistId,
        'kind': kind.dbValue,
        'ukey': key,
        'name': name,
        'grp': group,
        'logo': logo,
        'url': url,
        'tvg_id': tvgId,
        'num': number,
        'rating': rating,
        'year': year,
        'plot': plot,
      };

  factory MediaItem.fromRow(Map<String, Object?> r) => MediaItem(
        id: r['id'] as int,
        playlistId: r['playlist_id'] as int,
        kind: ContentKindX.parse(r['kind'] as String),
        key: r['ukey'] as String,
        name: r['name'] as String,
        group: (r['grp'] as String?) ?? '',
        logo: r['logo'] as String?,
        url: r['url'] as String?,
        tvgId: r['tvg_id'] as String?,
        number: r['num'] as int?,
        rating: r['rating'] as String?,
        year: r['year'] as String?,
        plot: r['plot'] as String?,
        favorite: (r['fav'] as int? ?? 0) == 1,
      );

  /// Identity is the playlist + stable key, so providers keyed by an item
  /// survive rebuilds and favorite toggles.
  @override
  bool operator ==(Object other) =>
      other is MediaItem && other.playlistId == playlistId && other.key == key;

  @override
  int get hashCode => Object.hash(playlistId, key);

  MediaItem copyWith({bool? favorite}) => MediaItem(
        id: id,
        playlistId: playlistId,
        kind: kind,
        key: key,
        name: name,
        group: group,
        logo: logo,
        url: url,
        tvgId: tvgId,
        number: number,
        rating: rating,
        year: year,
        plot: plot,
        favorite: favorite ?? this.favorite,
      );
}

class Episode {
  const Episode({
    required this.key,
    required this.season,
    required this.number,
    required this.title,
    required this.url,
    this.plot,
    this.image,
    this.duration,
  });

  final String key;
  final int season;
  final int number;
  final String title;
  final String url;
  final String? plot;
  final String? image;
  final String? duration;
}

class SeriesDetails {
  const SeriesDetails({required this.seasons, this.plot, this.cover, this.info = const VodInfo()});
  final Map<int, List<Episode>> seasons;
  final String? plot;
  final String? cover;
  final VodInfo info;
}

/// Extra details of a movie or series, loaded on demand.
class VodInfo {
  const VodInfo({
    this.plot,
    this.genre,
    this.cast,
    this.director,
    this.duration,
    this.year,
    this.rating,
    this.backdrop,
  });

  final String? plot;
  final String? genre;
  final String? cast;
  final String? director;
  final Duration? duration;
  final String? year;
  final String? rating;
  final String? backdrop;
}

class EpgProgram {
  const EpgProgram({
    required this.channelId,
    required this.start,
    required this.stop,
    required this.title,
    this.description,
  });

  final String channelId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? description;

  double progressAt(DateTime now) {
    final total = stop.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (now.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }

  bool isLiveAt(DateTime now) => !now.isBefore(start) && now.isBefore(stop);
}

class WatchEntry {
  const WatchEntry({
    required this.item,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
    required this.historyKey,
    this.title,
  });

  final MediaItem item;

  /// Episode key for series, otherwise the item key.
  final String historyKey;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;

  /// Episode title when the entry is a series episode.
  final String? title;

  double get progress =>
      durationMs <= 0 ? 0 : (positionMs / durationMs).clamp(0.0, 1.0);
}

/// What the player should open.
class PlayRequest {
  const PlayRequest({
    required this.item,
    required this.url,
    this.title,
    this.subtitle,
    this.historyKey,
    this.startAt = Duration.zero,
    this.siblings = const [],
    this.description,
  });

  final MediaItem item;
  final String url;
  final String? title;
  final String? subtitle;

  /// Episode synopsis; movies load theirs from the server.
  final String? description;

  /// Key used for resume history (episode key for series, item key otherwise).
  final String? historyKey;
  final Duration startAt;

  /// Channels the user can zap between (live only).
  final List<MediaItem> siblings;

  bool get isLive => item.kind == ContentKind.live;
}
