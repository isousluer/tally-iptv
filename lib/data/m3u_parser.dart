import 'models.dart';

/// Result of parsing an M3U / M3U8 playlist.
class M3uResult {
  M3uResult(this.items, this.epgUrl);
  final List<MediaItem> items;
  final String? epgUrl;
}

final _attrRe = RegExp(r'([\w-]+)="([^"]*)"');
final _vodExtRe = RegExp(r'\.(mp4|mkv|avi|mov|wmv|m4v|webm)(\?.*)?$', caseSensitive: false);

/// Parses extended M3U text. Runs fine inside an isolate (pure Dart).
M3uResult parseM3u(String content, int playlistId) {
  final items = <MediaItem>[];
  final seen = <String>{};
  String? epgUrl;

  Map<String, String> attrs = {};
  String? title;
  String? extGroup;
  var number = 0;

  for (final raw in content.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#EXTM3U')) {
      for (final m in _attrRe.allMatches(line)) {
        final k = m.group(1)!.toLowerCase();
        if (k == 'url-tvg' || k == 'x-tvg-url' || k == 'tvg-url') {
          epgUrl = m.group(2)!.split(',').first.trim();
        }
      }
      continue;
    }

    if (line.startsWith('#EXTINF')) {
      attrs = {
        for (final m in _attrRe.allMatches(line)) m.group(1)!.toLowerCase(): m.group(2)!,
      };
      final comma = _firstCommaOutsideQuotes(line);
      title = comma >= 0 ? line.substring(comma + 1).trim() : null;
      extGroup = null;
      continue;
    }

    if (line.startsWith('#EXTGRP:')) {
      extGroup = line.substring(8).trim();
      continue;
    }

    if (line.startsWith('#')) continue; // #EXTVLCOPT, #KODIPROP, etc.

    // A URL line closes the current entry.
    final url = line;
    if (!seen.add(url)) {
      attrs = {};
      title = null;
      continue;
    }
    number++;
    final name = (title?.isNotEmpty ?? false)
        ? title!
        : (attrs['tvg-name']?.isNotEmpty ?? false)
            ? attrs['tvg-name']!
            : 'Channel $number';
    final group = attrs['group-title'] ?? extGroup ?? '';

    items.add(MediaItem(
      playlistId: playlistId,
      kind: _guessKind(url),
      key: url,
      name: name,
      group: group.isEmpty ? 'Uncategorized' : group,
      logo: _nonEmpty(attrs['tvg-logo']),
      url: url,
      tvgId: _nonEmpty(attrs['tvg-id']),
      number: int.tryParse(attrs['tvg-chno'] ?? '') ?? number,
    ));
    attrs = {};
    title = null;
  }
  return M3uResult(items, epgUrl);
}

ContentKind _guessKind(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('/movie/') || lower.contains('/series/')) return ContentKind.movie;
  if (_vodExtRe.hasMatch(lower)) return ContentKind.movie;
  return ContentKind.live;
}

/// Titles may contain commas, so the title starts after the first comma
/// that is not inside an attribute value.
int _firstCommaOutsideQuotes(String line) {
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') inQuotes = !inQuotes;
    if (c == ',' && !inQuotes) return i;
  }
  return -1;
}

String? _nonEmpty(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
