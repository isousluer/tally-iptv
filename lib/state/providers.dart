import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';

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
    ref.read(pendingCleanupProvider.notifier).set(created.id);
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
      ref.read(epgStatusProvider.notifier).set(EpgStatus.idle, message: strings.guideProgramsLoaded(count));
      ref.read(epgVersionProvider.notifier).bump();
    } catch (e, st) {
      debugPrint('TV guide update failed: $e\n$st');
      ref.read(epgStatusProvider.notifier).set(EpgStatus.failed, message: '$e');
    }
  }

  /// Quietly updates online playlists that are more than a day old.
  /// Returns the names of the playlists that were updated.
  Future<List<String>> refreshStale() async {
    final list = state.value ?? await future;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final done = <String>[];
    for (final p in list) {
      if (p.type == SourceType.m3uFile) continue;
      if (p.lastUpdated != null && p.lastUpdated!.isAfter(cutoff)) continue;
      try {
        await refresh(p);
        done.add(p.name);
      } catch (e) {
        debugPrint('Auto update of ${p.name} failed: $e');
      }
    }
    return done;
  }

  /// Restores a backup, then downloads the channels of each restored playlist.
  Future<RestoreResult> restore(String json, {void Function(String name)? onLoading}) async {
    final result = await importBackup(ref.read(databaseProvider), ref.read(prefsProvider), json);
    await _reload();
    for (final p in result.playlists) {
      onLoading?.call(p.name);
      try {
        await ref.read(repositoryProvider).refresh(p);
      } catch (e) {
        debugPrint('Restoring ${p.name} failed: $e');
      }
    }
    await _reload();
    ref.read(contentVersionProvider.notifier).bump();
    ref.read(groupsVersionProvider.notifier).bump();
    ref.invalidate(settingsProvider);
    if (ref.read(activePlaylistIdProvider) == null && (state.value ?? const []).isNotEmpty) {
      await ref.read(activePlaylistIdProvider.notifier).select(state.value!.first.id);
    }
    return result;
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

/// All categories, including hidden ones (the category manager needs them).
final groupsProvider = FutureProvider.family<List<GroupInfo>, ContentKind>((ref, kind) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  ref.watch(groupsVersionProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).groups(p.id, kind);
});

/// Bumped when categories are hidden, locked or reordered.
final groupsVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

/// Whether locked categories are open right now: no PIN set, or the PIN was
/// entered during this session.
final lockedContentOpenProvider = Provider<bool>(
  (ref) => ref.watch(parentalPinProvider) == null || ref.watch(parentalUnlockedProvider),
);

final countProvider = FutureProvider.family<int, ContentKind>((ref, kind) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  if (p == null) return 0;
  return ref.watch(databaseProvider).count(p.id, kind);
});

/// Special group values used by the category chips.
const groupAll = '\u0000all';
const groupFavorites = '\u0000fav';
const _groupListPrefix = '\u0000list:';

/// The group value that shows one of the viewer's channel lists.
String listGroup(int id) => '$_groupListPrefix$id';

/// The channel list a group value stands for, if it is one.
int? listIdOf(String group) =>
    group.startsWith(_groupListPrefix) ? int.tryParse(group.substring(_groupListPrefix.length)) : null;

typedef ItemQuery = ({ContentKind kind, String group, String search});

/// Items of a category, all of them. The first few arrive at once so the
/// screen fills right away; the rest follow in larger chunks, so even lists
/// of 50,000 movies show in full without a long wait up front.
final itemsProvider = StreamProvider.family<List<MediaItem>, ItemQuery>((ref, q) async* {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  ref.watch(groupsVersionProvider);
  final open = ref.watch(lockedContentOpenProvider);
  if (p == null) {
    yield const [];
    return;
  }
  final db = ref.watch(databaseProvider);
  final listId = listIdOf(q.group);
  if (listId != null) {
    ref.watch(channelListsVersionProvider);
    yield await db.channelListItems(p.id, listId, includeLocked: open);
    return;
  }
  final sort = ref.watch(sortProvider(q.kind));
  final all = <MediaItem>[];
  var chunk = 300;
  while (true) {
    final part = await db.items(
      p.id,
      q.kind,
      group: q.group == groupAll || q.group == groupFavorites ? null : q.group,
      favoritesOnly: q.group == groupFavorites,
      search: q.search,
      includeLocked: open,
      sort: sort,
      limit: chunk,
      offset: all.length,
    );
    all.addAll(part);
    yield List.unmodifiable(all);
    if (part.length < chunk) return;
    chunk = 5000;
  }
});

final favoritesProvider = FutureProvider<List<MediaItem>>((ref) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  ref.watch(groupsVersionProvider);
  final open = ref.watch(lockedContentOpenProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).favorites(p.id, includeLocked: open);
});

/// Search across live channels, movies and series at once.
final searchProvider = FutureProvider.autoDispose.family<Map<ContentKind, List<MediaItem>>, String>((ref, text) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  final open = ref.watch(lockedContentOpenProvider);
  if (p == null || text.trim().length < 2) return const {};
  final db = ref.watch(databaseProvider);
  return {
    for (final kind in ContentKind.values)
      kind: await db.items(p.id, kind, search: text, includeLocked: open, limit: 60),
  };
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

// -------------------------------------------------------------- channel lists

final channelListsVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

/// The viewer's channel lists for the open playlist.
final channelListsProvider = FutureProvider<List<ChannelList>>((ref) async {
  final p = ref.watch(activePlaylistProvider);
  ref.watch(contentVersionProvider);
  ref.watch(channelListsVersionProvider);
  if (p == null) return const [];
  return ref.watch(databaseProvider).channelLists(p.id);
});

class ChannelListsController {
  ChannelListsController(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);
  void _changed() => ref.read(channelListsVersionProvider.notifier).bump();

  Future<int?> create(String name) async {
    final p = ref.read(activePlaylistProvider);
    if (p == null) return null;
    final id = await _db.createChannelList(p.id, name);
    _changed();
    return id;
  }

  Future<void> rename(ChannelList list, String name) async {
    await _db.renameChannelList(list.id, name);
    _changed();
  }

  Future<void> delete(ChannelList list) async {
    await _db.deleteChannelList(list.id);
    _changed();
  }

  Future<void> reorder(List<ChannelList> lists) async {
    await _db.reorderChannelLists([for (final l in lists) l.id]);
    _changed();
  }

  Future<Set<int>> listsWith(MediaItem channel) => _db.listsWith(channel.playlistId, channel.key);

  Future<void> setIn(int listId, MediaItem channel, bool value) async {
    await _db.setInChannelList(listId, channel.key, value);
    _changed();
  }

  Future<void> reorderChannels(int listId, List<MediaItem> channels) async {
    await _db.reorderChannelListItems(listId, [for (final c in channels) c.key]);
    _changed();
  }
}

final channelListsControllerProvider = Provider(ChannelListsController.new);

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
/// Recorded past programs of a channel, newest first, with their addresses.
final archiveProvider = FutureProvider.autoDispose.family<List<(EpgProgram, String)>, MediaItem>((ref, channel) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || !p.isXtream || !channel.hasArchive) return const [];
  return ref.watch(repositoryProvider).xtreamFor(p).archive(channel);
});

/// The Xtream subscription behind a playlist, fetched each time it's shown.
final accountProvider = FutureProvider.autoDispose.family<XtreamAccount, int>((ref, playlistId) async {
  final playlists = await ref.watch(playlistsProvider.future);
  final p = playlists.firstWhere((p) => p.id == playlistId);
  return ref.watch(repositoryProvider).xtreamFor(p).account();
});

/// How many channels, movies and series a playlist has on this device.
final playlistCountsProvider = FutureProvider.autoDispose.family<({int live, int movies, int series}), int>((
  ref,
  playlistId,
) async {
  ref.watch(contentVersionProvider);
  final db = ref.watch(databaseProvider);
  return (
    live: await db.count(playlistId, ContentKind.live),
    movies: await db.count(playlistId, ContentKind.movie),
    series: await db.count(playlistId, ContentKind.series),
  );
});

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

// ------------------------------------------------------------ parental lock

class ParentalPin extends Notifier<String?> {
  static const _key = 'parental_pin';

  @override
  String? build() => ref.watch(prefsProvider).getString(_key);

  Future<void> set(String? pin) async {
    final prefs = ref.read(prefsProvider);
    if (pin == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, pin);
    }
    state = pin;
  }
}

final parentalPinProvider = NotifierProvider<ParentalPin, String?>(ParentalPin.new);

/// Unlocked by entering the PIN; locks again when the app restarts.
class ParentalUnlocked extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool v) => state = v;
}

final parentalUnlockedProvider = NotifierProvider<ParentalUnlocked, bool>(ParentalUnlocked.new);

// ----------------------------------------------------------------- settings

/// How the picture fills the player: whole picture, cropped to fill, or stretched.
enum VideoFit { fit, fill, stretch }

enum SubtitleSize { small, medium, large, huge }

/// Behind subtitle text: an outline only, a see-through box or a dark box.
enum SubtitleBackground { none, box, solid }

/// How far above the bottom of the picture subtitles sit.
enum SubtitlePosition { low, middle, high }

T _enumPref<T extends Enum>(List<T> values, String? saved, T fallback) =>
    values.firstWhere((v) => v.name == saved, orElse: () => fallback);

class AppSettings {
  const AppSettings({
    this.videoFit = VideoFit.fit,
    this.audioLanguage,
    this.subtitleLanguage,
    this.autoNext = true,
    this.autoRefresh = true,
    this.language,
    this.checkUpdates = true,
    this.subtitleSize = SubtitleSize.medium,
    this.subtitleBackground = SubtitleBackground.box,
    this.subtitlePosition = SubtitlePosition.low,
  });

  final VideoFit videoFit;

  /// Language code last picked in the player; applied to new videos.
  final String? audioLanguage;

  /// Language code, `off`, or null for the stream's default.
  final String? subtitleLanguage;
  final bool autoNext;

  /// Update playlists older than a day when the app opens.
  final bool autoRefresh;

  /// App language code, or null to follow the device.
  final String? language;

  /// Look for a new release on GitHub when the app opens.
  final bool checkUpdates;

  final SubtitleSize subtitleSize;
  final SubtitleBackground subtitleBackground;
  final SubtitlePosition subtitlePosition;
}

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    return AppSettings(
      videoFit: VideoFit.values.firstWhere((f) => f.name == p.getString('video_fit'), orElse: () => VideoFit.fit),
      audioLanguage: p.getString('audio_lang'),
      subtitleLanguage: p.getString('subtitle_lang'),
      autoNext: p.getBool('auto_next') ?? true,
      autoRefresh: p.getBool('auto_refresh') ?? true,
      language: p.getString('app_language'),
      checkUpdates: p.getBool('check_updates') ?? true,
      subtitleSize: _enumPref(SubtitleSize.values, p.getString('subtitle_size'), SubtitleSize.medium),
      subtitleBackground: _enumPref(
        SubtitleBackground.values,
        p.getString('subtitle_background'),
        SubtitleBackground.box,
      ),
      subtitlePosition: _enumPref(SubtitlePosition.values, p.getString('subtitle_position'), SubtitlePosition.low),
    );
  }

  Future<void> _str(String key, String? v) => v == null ? _p.remove(key) : _p.setString(key, v);

  Future<void> setVideoFit(VideoFit f) async {
    await _p.setString('video_fit', f.name);
    ref.invalidateSelf();
  }

  Future<void> setAudioLanguage(String? lang) async {
    await _str('audio_lang', lang);
    ref.invalidateSelf();
  }

  Future<void> setSubtitleLanguage(String? lang) async {
    await _str('subtitle_lang', lang);
    ref.invalidateSelf();
  }

  Future<void> setAutoNext(bool v) async {
    await _p.setBool('auto_next', v);
    ref.invalidateSelf();
  }

  Future<void> setAutoRefresh(bool v) async {
    await _p.setBool('auto_refresh', v);
    ref.invalidateSelf();
  }

  Future<void> setSubtitleSize(SubtitleSize v) async {
    await _p.setString('subtitle_size', v.name);
    ref.invalidateSelf();
  }

  Future<void> setSubtitleBackground(SubtitleBackground v) async {
    await _p.setString('subtitle_background', v.name);
    ref.invalidateSelf();
  }

  Future<void> setSubtitlePosition(SubtitlePosition v) async {
    await _p.setString('subtitle_position', v.name);
    ref.invalidateSelf();
  }

  Future<void> setCheckUpdates(bool v) async {
    await _p.setBool('check_updates', v);
    ref.invalidateSelf();
  }

  Future<void> setLanguage(String? code) async {
    await _str('app_language', code);
    ref.invalidateSelf();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ------------------------------------------------------------------- sorting

/// How each tab orders its list; remembered per tab.
class SortNotifier extends Notifier<ItemSort> {
  SortNotifier(this.kind);
  final ContentKind kind;

  String get _key => 'sort_${kind.name}';

  @override
  ItemSort build() {
    final saved = ref.watch(prefsProvider).getString(_key);
    return ItemSort.values.firstWhere((s) => s.name == saved, orElse: () => ItemSort.playlist);
  }

  Future<void> set(ItemSort s) async {
    await ref.read(prefsProvider).setString(_key, s.name);
    state = s;
  }
}

final sortProvider = NotifierProvider.family<SortNotifier, ItemSort, ContentKind>(SortNotifier.new);

// ---------------------------------------------------------------- cleanup

/// Set after a playlist is added, so the home screen can offer the wizard
/// once the new list is on screen.
class PendingCleanup extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? id) => state = id;
}

final pendingCleanupProvider = NotifierProvider<PendingCleanup, int?>(PendingCleanup.new);
