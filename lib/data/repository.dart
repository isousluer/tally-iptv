import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import '../l10n/strings.dart';
import 'database.dart';
import 'epg_parser.dart';
import 'm3u_parser.dart';
import 'models.dart';
import 'xtream_client.dart';

class SourceException implements Exception {
  SourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Steps shown while a playlist loads.
enum LoadStage { connect, live, movies, series, save }

class LoadProgress {
  const LoadProgress({required this.stages, this.current, this.counts = const {}});

  /// Stages that apply to this source, in order.
  final List<LoadStage> stages;
  final LoadStage? current;
  final Map<LoadStage, int> counts;

  bool isDone(LoadStage s) => current == null || stages.indexOf(s) < stages.indexOf(current!);

  LoadProgress at(LoadStage stage) => LoadProgress(stages: stages, current: stage, counts: counts);

  LoadProgress withCount(LoadStage stage, int count) =>
      LoadProgress(stages: stages, current: current, counts: {...counts, stage: count});
}

typedef ProgressCallback = void Function(LoadProgress progress);

/// Loads playlists from their sources and keeps the local database in sync.
class PlaylistRepository {
  PlaylistRepository(this.db, {this.httpClient});
  final AppDatabase db;

  /// Lets tests stand in for the Xtream server.
  final http.Client? httpClient;

  XtreamClient xtreamFor(Playlist p) => XtreamClient(
    server: p.server ?? '',
    username: p.username ?? '',
    password: p.password ?? '',
    client: httpClient,
  );

  /// Recognizes Xtream "get.php?username=…&password=…" M3U links and turns
  /// them into an Xtream login, which gives proper movie and series data.
  static Playlist upgradeXtreamLink(Playlist draft) {
    if (draft.type != SourceType.m3uUrl || draft.url == null) return draft;
    final uri = Uri.tryParse(draft.url!.trim());
    if (uri == null || !uri.path.toLowerCase().endsWith('get.php')) return draft;
    final user = uri.queryParameters['username'];
    final pass = uri.queryParameters['password'];
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) return draft;
    final server = uri.replace(path: '', query: '', fragment: '').toString().replaceAll(RegExp(r'[?#/]+$'), '');
    return Playlist(
      id: draft.id,
      name: draft.name,
      type: SourceType.xtream,
      server: server,
      username: user,
      password: pass,
      epgUrl: draft.epgUrl,
    );
  }

  /// Creates the playlist and downloads its content. The playlist row is
  /// removed again when the first load fails, so broken sources don't linger.
  Future<Playlist> add(Playlist draft, {ProgressCallback? onProgress}) async {
    final source = upgradeXtreamLink(draft);
    final id = await db.insertPlaylist(source);
    final created = Playlist.fromRow({...source.toRow(), 'id': id});
    try {
      return await refresh(created, onProgress: onProgress);
    } catch (_) {
      await db.deletePlaylist(id);
      rethrow;
    }
  }

  Future<Playlist> refresh(Playlist p, {ProgressCallback? onProgress}) async {
    void report(LoadProgress lp) => onProgress?.call(lp);
    List<MediaItem> items;
    String? epgUrl = p.epgUrl;

    switch (p.type) {
      case SourceType.xtream:
        var progress = const LoadProgress(
          stages: [LoadStage.connect, LoadStage.live, LoadStage.movies, LoadStage.series, LoadStage.save],
          current: LoadStage.connect,
        );
        report(progress);
        final client = xtreamFor(p);
        await _guard(client.authenticate);
        epgUrl ??= client.epgUrl;

        report(progress = progress.at(LoadStage.live));
        final live = await _keepIfEmpty(p.id, ContentKind.live, await _guard(() => client.fetchLive(p.id)));
        report(progress = progress.withCount(LoadStage.live, live.length).at(LoadStage.movies));
        final movies = await _keepIfEmpty(p.id, ContentKind.movie, await _guard(() => client.fetchMovies(p.id)));
        report(progress = progress.withCount(LoadStage.movies, movies.length).at(LoadStage.series));
        final series = await _keepIfEmpty(p.id, ContentKind.series, await _guard(() => client.fetchSeries(p.id)));
        report(progress = progress.withCount(LoadStage.series, series.length).at(LoadStage.save));
        items = [...live, ...movies, ...series];
        if (items.isEmpty) throw SourceException(strings.errNoContent);

      case SourceType.m3uUrl:
      case SourceType.m3uFile:
        var progress = const LoadProgress(
          stages: [LoadStage.connect, LoadStage.live, LoadStage.movies, LoadStage.save],
          current: LoadStage.connect,
        );
        report(progress);
        final text = p.type == SourceType.m3uUrl
            ? await _download(p.url!)
            : await File(p.url!).readAsString(encoding: const Utf8Codec(allowMalformed: true));
        report(progress = progress.at(LoadStage.live));
        final id = p.id;
        final result = await Isolate.run(() => parseM3u(text, id));
        if (result.items.isEmpty) {
          throw SourceException(strings.errNoChannelsInM3u);
        }
        final liveCount = result.items.where((i) => i.kind == ContentKind.live).length;
        progress = progress.withCount(LoadStage.live, liveCount).at(LoadStage.movies);
        report(progress = progress.withCount(LoadStage.movies, result.items.length - liveCount).at(LoadStage.save));
        items = result.items;
        epgUrl ??= result.epgUrl;
    }

    await db.replaceItems(p.id, items);
    final updated = p.copyWith(epgUrl: epgUrl, lastUpdated: DateTime.now());
    await db.updatePlaylist(updated);
    return updated;
  }

  /// Xtream servers that are busy or briefly broken sometimes answer a list
  /// request with an error object instead of a list, which reads as "no
  /// movies". Replacing the stored movies with nothing would also hide their
  /// history, favorites and channel lists until the next update, so the
  /// stored ones stay instead.
  Future<List<MediaItem>> _keepIfEmpty(int playlistId, ContentKind kind, List<MediaItem> fetched) async =>
      fetched.isNotEmpty ? fetched : db.allItems(playlistId, kind);

  /// Downloads the guide for [p]. Returns the number of programs stored.
  Future<int> refreshEpg(Playlist p) async {
    final url = p.epgUrl;
    if (url == null || url.isEmpty) return 0;
    final ids = await db.tvgIds(p.id);
    if (ids.isEmpty) return 0;
    final List<EpgProgram> programs;
    try {
      programs = await Isolate.run(() => downloadEpg(url, ids));
    } on HttpException catch (e) {
      if (e.message.contains('404') || e.message.contains('403')) {
        throw SourceException(
          p.isXtream && url == xtreamFor(p).epgUrl ? strings.errProviderNoGuide : strings.errGuideLinkNotFound,
        );
      }
      throw SourceException(strings.errGuideDownload(e.message));
    } on SocketException {
      throw SourceException(strings.errGuideUnreachable);
    }
    await db.replaceEpg(p.id, programs);
    return programs.length;
  }

  Future<SeriesDetails> seriesDetails(Playlist p, MediaItem series) => xtreamFor(p).seriesInfo(series.key);

  /// Turns low-level network errors into messages people can act on.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on SocketException {
      throw SourceException(strings.errServerUnreachable);
    } on HandshakeException {
      throw SourceException(strings.errSecureConnection);
    } on http.ClientException catch (e) {
      throw SourceException(strings.errConnectionFailed(e.message));
    } on TimeoutException {
      throw SourceException(strings.errTimeout);
    }
  }

  Future<String> _download(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      throw SourceException(strings.errFullLink);
    }
    final res = await _guard(() => http.get(uri).timeout(const Duration(seconds: 120)));
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw SourceException(strings.errAccessRefused(res.statusCode));
    }
    if (res.statusCode != 200) {
      throw SourceException(strings.errHttpStatus(res.statusCode));
    }
    final bytes = res.bodyBytes.length > 2 && res.bodyBytes[0] == 0x1f && res.bodyBytes[1] == 0x8b
        ? gzip.decode(res.bodyBytes)
        : res.bodyBytes;
    return utf8.decode(bytes, allowMalformed: true);
  }
}
