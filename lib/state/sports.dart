import 'dart:convert';

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/models.dart';
import '../data/sport_events.dart';
import 'providers.dart';

const _cacheKey = 'sport_events_cache';
const _maxAge = Duration(hours: 3);

/// The listing covers Turkish TV, so the strip only shows to people in
/// Turkey or using the app in Turkish.
bool sportsListingApplies(String? appLanguage) {
  final device = WidgetsBinding.instance.platformDispatcher.locales;
  if (device.any((l) => l.countryCode?.toUpperCase() == 'TR')) return true;
  if (appLanguage != null) return appLanguage == 'tr';
  return device.isNotEmpty && device.first.languageCode == 'tr';
}

/// Today's events, from a copy a few hours old at most. Empty outside
/// Turkey, offline with nothing saved, or when the page can't be read.
final sportEventsProvider = FutureProvider<List<SportEvent>>((ref) async {
  final language = ref.watch(settingsProvider.select((s) => s.language));
  if (!sportsListingApplies(language)) return const [];
  final prefs = ref.read(prefsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  List<SportEvent>? saved;
  var fetched = DateTime(0);
  try {
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['day'] == today.millisecondsSinceEpoch) {
        fetched = DateTime.fromMillisecondsSinceEpoch(j['fetched'] as int);
        saved = [for (final e in j['events'] as List) SportEvent.fromJson((e as Map).cast<String, dynamic>())];
      }
    }
  } catch (_) {
    saved = null;
  }
  if (saved != null && now.difference(fetched) < _maxAge) return saved;

  try {
    final res = await http
        .get(
          Uri.https('www.sporekrani.com', '/'),
          headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) Mobile', 'Accept-Language': 'tr'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return saved ?? const [];
    final events = parseSportEvents(utf8.decode(res.bodyBytes, allowMalformed: true), today);
    // Nothing found most likely means the page changed; keep what we had.
    if (events.isEmpty) return saved ?? const [];
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'day': today.millisecondsSinceEpoch,
        'fetched': now.millisecondsSinceEpoch,
        'events': [for (final e in events) e.toJson()],
      }),
    );
    return events;
  } catch (_) {
    return saved ?? const [];
  }
});

/// The sports in today's listing, for picking which to show.
final sportNamesProvider = FutureProvider<List<String>>((ref) async {
  final events = await ref.watch(sportEventsProvider.future);
  return {
    for (final e in events)
      if (e.sport.isNotEmpty && e.sport != 'Programlar') e.sport,
  }.toList()..sort();
});

/// An event with the viewer's channel for it, when they have one.
typedef SportListing = ({SportEvent event, MediaItem? channel});

/// Matches and other sports (not studio shows) still to come or under way,
/// each with a channel from the open playlist.
final sportListingsProvider = FutureProvider<List<SportListing>>((ref) async {
  final (show, sports) = ref.watch(settingsProvider.select((s) => (s.showMatches, s.matchSports)));
  if (!show) return const [];
  final events = await ref.watch(sportEventsProvider.future);
  if (events.isEmpty) return const [];
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return const [];
  ref.watch(contentVersionProvider);
  ref.watch(groupsVersionProvider);
  final db = ref.watch(databaseProvider);
  final health = await ref.watch(streamHealthProvider.future);
  final open = ref.watch(lockedContentOpenProvider);
  final groups = await db.groups(p.id, ContentKind.live);
  final skip = {
    for (final g in groups)
      if (g.hidden || (g.locked && !open)) g.name,
  };
  final live = (await db.allItems(p.id, ContentKind.live)).where((c) => !skip.contains(c.group));
  final byKey = indexChannels(live);
  final now = DateTime.now();
  final out = [
    for (final e in events)
      // Most matches are over within two and a half hours.
      if (e.sport != 'Programlar' &&
          (sports.isEmpty || sports.contains(e.sport)) &&
          now.difference(e.start) < const Duration(minutes: 150))
        (event: e, channel: channelFor(e.channels, byKey, health)),
  ];
  // The ones the viewer can watch first, each part in time order.
  return [...out.where((s) => s.channel != null), ...out.where((s) => s.channel == null)];
});
