import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../data/repository.dart';

/// Overridden in `main()` once the database is open.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final repositoryProvider = Provider((ref) => PlaylistRepository(ref.watch(databaseProvider)));

// ------------------------------------------------------------------ playlists

class PlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  @override
  Future<List<Playlist>> build() => ref.watch(databaseProvider).playlists();

  Future<Playlist> add(Playlist draft, {ProgressCallback? onProgress}) async {
    final created = await ref.read(repositoryProvider).add(draft, onProgress: onProgress);
    await _reload();
    await ref.read(activePlaylistIdProvider.notifier).select(created.id);
    unawaited(refreshEpg(created));
    return created;
  }

  Future<void> refresh(Playlist p) async {
    final updated = await ref.read(repositoryProvider).refresh(p);
    await _reload();
    ref.read(contentVersionProvider.notifier).bump();
    unawaited(refreshEpg(updated));
  }

  Future<void> refreshEpg(Playlist p) async {
    ref.read(epgStatusProvider.notifier).set(EpgStatus.loading);
    try {
      final count = await ref.read(repositoryProvider).refreshEpg(p);
      ref.read(epgStatusProvider.notifier).set(EpgStatus.idle, message: '${compactNumber(count)} programs loaded');
      ref.read(epgVersionProvider.notifier).bump();
    } catch (e, st) {
      debugPrint('TV guide update failed: $e\n$st');
      ref.read(epgStatusProvider.notifier).set(EpgStatus.failed, message: '$e');
    }
  }

  Future<void> rename(Playlist p, String name) async {
    await ref.read(databaseProvider).updatePlaylist(p.copyWith(name: name));
    await _reload();
  }

  Future<void> setEpgUrl(Playlist p, String url) async {
    final updated = p.copyWith(epgUrl: url);
    await ref.read(databaseProvider).updatePlaylist(updated);
    await _reload();
    unawaited(refreshEpg(updated));
  }

  Future<void> remove(Playlist p) async {
    await ref.read(databaseProvider).deletePlaylist(p.id);
    await _reload();
    final list = state.value ?? const [];
    final active = ref.read(activePlaylistIdProvider);
    if (active == p.id) {
      await ref.read(activePlaylistIdProvider.notifier).select(list.isEmpty ? null : list.first.id);
    }
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(databaseProvider).playlists());
  }
}

final playlistsProvider = AsyncNotifierProvider<PlaylistsNotifier, List<Playlist>>(PlaylistsNotifier.new);

class ActivePlaylistId extends Notifier<int?> {
  static const _key = 'active_playlist';

  @override
  int? build() => ref.watch(prefsProvider).getInt(_key);

  Future<void> select(int? id) async {
    final prefs = ref.read(prefsProvider);
    if (id == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setInt(_key, id);
    }
    state = id;
  }
}

final activePlaylistIdProvider = NotifierProvider<ActivePlaylistId, int?>(ActivePlaylistId.new);

final activePlaylistProvider = Provider<Playlist?>((ref) {
  final list = ref.watch(playlistsProvider).value ?? const [];
  if (list.isEmpty) return null;
  final id = ref.watch(activePlaylistIdProvider);
  return list.firstWhere((p) => p.id == id, orElse: () => list.first);
});

/// Bumped when stored data changes outside the normal provider graph.
/// Content providers watch these instead of being invalidated from inside
/// other providers (Riverpod treats that as a circular dependency).
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final contentVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);
final epgVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

// -------------------------------------------------------------------- content

final groupsProvider = FutureProvider.family<List<String>, ContentKind>((ref, kind) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).groups(p.id, kind);
});

final countProvider = FutureProvider.family<int, ContentKind>((ref, kind) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  if (p == null) return 0;
  return ref.watch(databaseProvider).count(p.id, kind);
});

/// Special group values used by the category chips.
const groupAll = '\u0000all';
const groupFavorites = '\u0000fav';

typedef ItemQuery = ({ContentKind kind, String group, String search});

final itemsProvider = FutureProvider.family<List<MediaItem>, ItemQuery>((ref, q) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).items(
        p.id,
        q.kind,
        group: q.group == groupAll || q.group == groupFavorites ? null : q.group,
        favoritesOnly: q.group == groupFavorites,
        search: q.search,
      );
});

final favoritesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).favorites(p.id);
});

final historyProvider = FutureProvider<List<(WatchEntry, String?)>>((ref) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).history(p.id);
});

final seriesDetailsProvider = FutureProvider.family<SeriesDetails, MediaItem>((ref, series) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || !p.isXtream) return const SeriesDetails(seasons: {});
  return ref.watch(repositoryProvider).seriesDetails(p, series);
});

/// Plot, genre, cast etc. of a movie. Empty for M3U playlists.
final movieInfoProvider = FutureProvider.autoDispose.family<VodInfo, MediaItem>((ref, movie) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || !p.isXtream || movie.kind != ContentKind.movie) return VodInfo(plot: movie.plot);
  ref.keepAlive(); // cache while the app runs; details rarely change
  return ref.watch(repositoryProvider).xtreamFor(p).movieInfo(movie.key);
});

class FavoritesController {
  FavoritesController(this.ref);
  final Ref ref;

  Future<void> toggle(MediaItem item) async {
    await ref.read(databaseProvider).setFavorite(item.playlistId, item.key, !item.favorite);
    ref.invalidate(itemsProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(historyProvider);
  }
}

final favoritesControllerProvider = Provider(FavoritesController.new);

// ------------------------------------------------------------------------ epg

enum EpgStatus { idle, loading, failed }

class EpgStatusNotifier extends Notifier<EpgStatus> {
  /// Result or error text of the last update, shown in Settings.
  String? message;

  @override
  EpgStatus build() => EpgStatus.idle;

  void set(EpgStatus s, {String? message}) {
    if (message != null || s == EpgStatus.loading) this.message = message;
    state = s;
  }
}

String compactNumber(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

final epgStatusProvider = NotifierProvider<EpgStatusNotifier, EpgStatus>(EpgStatusNotifier.new);

/// Ticks every 30 seconds so progress bars and "now" programs stay current.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final nowPlayingProvider = FutureProvider<Map<String, EpgProgram>>((ref) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return const {};
  ref.watch(epgVersionProvider);
  // Re-query when the clock ticks.
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  return ref.watch(databaseProvider).nowPlayingAll(p.id, now);
});

/// Now and upcoming programs of a channel: from the stored guide, or straight
/// from the Xtream server when the provider has no full guide file.
final scheduleProvider = FutureProvider.autoDispose.family<List<EpgProgram>, MediaItem>((ref, channel) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(epgVersionProvider);
  if (p == null) return const [];
  final id = channel.tvgId;
  if (id != null) {
    final stored = await ref.watch(databaseProvider).schedule(p.id, id, DateTime.now());
    if (stored.isNotEmpty) return stored;
  }
  if (!p.isXtream) return const [];
  try {
    final now = DateTime.now();
    final list = await ref.watch(repositoryProvider).xtreamFor(p).shortEpg(channel);
    return list.where((e) => e.stop.isAfter(now)).toList();
  } catch (_) {
    return const [];
  }
});
