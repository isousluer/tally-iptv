/// Finds copies of the same channel in a list ("beIN SPORTS 1 HD",
/// "beIN SPORTS 1 SD/MOBIL", "beIN SPORTS 1 FHD ᴿᴬᵂ") and ranks them, so a
/// list can show one row per channel and the player can fall back to the
/// next copy when one doesn't play.
library;

import 'models.dart';

/// What the app has learned about a stream from playing it.
class StreamHealth {
  const StreamHealth({this.fails = 0, this.height});

  /// Failed attempts in a row since it last played.
  final int fails;

  /// Picture height it played at, when it did.
  final int? height;

  /// Shown as not working in lists.
  bool get failing => fails >= 2;
}

/// Words that only describe the quality or the source of a stream.
const _tags = {
  '4K', 'UHD', 'FHD', 'FULLHD', 'HD', 'SD', 'HQ', 'LQ', 'HEVC', 'H265', 'H264', 'X265', 'RAW', 'MOBIL', //
  'MOBILE', '2160P', '1080P', '1080I', '720P', '576P', '540P', '480P', '360P', '50FPS', '60FPS', 'FPS',
  'BACKUP', 'YEDEK', 'ALT', 'MULTI', 'VIP', 'LOW', 'HIGH', 'NEW', 'YENI', 'TEST', 'LIVE', 'CANLI', 'TV2',
};

/// "TR:", "TR |", "|TR|" and the like at the start of a channel name.
final _countryPrefix = RegExp(r'^\s*\|?\s*[A-Z]{2,4}\s*[:|]\s*');
final _token = RegExp(r'[A-Z0-9]+');

String _fold(String s) {
  const map = {
    'İ': 'I', 'ı': 'I', 'Ş': 'S', 'ş': 'S', 'Ğ': 'G', 'ğ': 'G', 'Ü': 'U', 'ü': 'U', 'Ö': 'O', 'ö': 'O', //
    'Ç': 'C', 'ç': 'C', 'Ä': 'A', 'ä': 'A', 'Å': 'A', 'å': 'A', 'Ø': 'O', 'ø': 'O', 'é': 'E', 'É': 'E',
  };
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    b.write(map[ch] ?? ch);
  }
  return b.toString().toUpperCase();
}

/// The channel's name without quality tags, for spotting copies. Empty
/// when nothing is left, which never matches anything.
String baseChannelName(String name) {
  final up = _fold(name).replaceFirst(_countryPrefix, ' ');
  final words = _token.allMatches(up).map((m) => m.group(0)!).where((w) => !_tags.contains(w));
  return words.join(' ');
}

/// Tags that only say how good a copy looks; dropped from the name of a
/// row that stands for several copies.
const _qualityTags = {
  '4K', 'UHD', 'FHD', 'FULLHD', 'HD', 'SD', 'HQ', 'LQ', 'HEVC', 'H265', 'H264', 'X265', 'RAW', 'MOBIL', //
  'MOBILE', '2160P', '1080P', '1080I', '720P', '576P', '540P', '480P', '360P', '50FPS', '60FPS', 'FPS',
};

/// Small capital and superscript letters some lists use ("ᴿᴬᵂ").
const _small = {
  'ᴬ': 'A', 'ᴮ': 'B', 'ᴰ': 'D', 'ᴱ': 'E', 'ᴳ': 'G', 'ᴴ': 'H', 'ᴵ': 'I', 'ᴶ': 'J', 'ᴷ': 'K', 'ᴸ': 'L', //
  'ᴹ': 'M', 'ᴺ': 'N', 'ᴼ': 'O', 'ᴾ': 'P', 'ᴿ': 'R', 'ᵀ': 'T', 'ᵁ': 'U', 'ⱽ': 'V', 'ᵂ': 'W',
};

final _word = RegExp(r'[^\s\-_|/()\[\]:.,+]+');
final _emptyBrackets = RegExp(r'\(\s*\)|\[\s*\]');
final _spaces = RegExp(r'\s+');
final _trailing = RegExp(r'[\s\-_|/,.:]+$');

/// [name] without its quality tags, in its own spelling:
/// "TR: beIN SPORTS 1 FHD ᴿᴬᵂ" becomes "TR: beIN SPORTS 1". Unchanged when
/// nothing would be left.
String nameWithoutQuality(String name) {
  final out = name
      .replaceAllMapped(_word, (m) {
        final w = m.group(0)!;
        final plain = _fold(w.split('').map((c) => _small[c] ?? c).join());
        return _qualityTags.contains(plain) ? '' : w;
      })
      .replaceAll(_emptyBrackets, ' ')
      .replaceAll(_spaces, ' ')
      .replaceAll(_trailing, '')
      .trim();
  return baseChannelName(out).isEmpty ? name : out;
}

/// Copies are channels of the same category with the same base name.
String familyKey(MediaItem c) {
  final base = baseChannelName(c.name);
  return base.isEmpty ? 'key:${c.key}' : '${c.group}\u0000$base';
}

/// Higher is better: 4 for 4K, 3 for Full HD, 2 for HD, 1 for SD. A height
/// the stream really played at counts more than what its name claims.
int qualityRank(MediaItem c, [StreamHealth? health]) {
  final h = health?.height;
  if (h != null && h > 0) {
    if (h >= 1800) return 4;
    if (h >= 1000) return 3;
    if (h >= 700) return 2;
    return 1;
  }
  final words = _token.allMatches(_fold(c.name)).map((m) => m.group(0)!).toSet();
  if (words.contains('4K') || words.contains('UHD') || words.contains('2160P')) return 4;
  if (words.contains('FHD') || words.contains('FULLHD') || words.contains('1080P') || words.contains('1080I')) {
    return 3;
  }
  if (words.contains('SD') || words.contains('MOBIL') || words.contains('MOBILE') || words.contains('LQ')) return 1;
  if (words.contains('576P') || words.contains('480P') || words.contains('360P') || words.contains('540P')) return 1;
  return 2;
}

/// Orders copies best first: working before failing, then by quality, then
/// in playlist order.
List<MediaItem> rankCopies(List<MediaItem> copies, Map<String, StreamHealth> health) {
  final indexed = copies.indexed.toList();
  indexed.sort((a, b) {
    final ha = health[a.$2.key], hb = health[b.$2.key];
    final fa = (ha?.failing ?? false) ? 1 : 0, fb = (hb?.failing ?? false) ? 1 : 0;
    if (fa != fb) return fa - fb;
    final q = qualityRank(b.$2, hb) - qualityRank(a.$2, ha);
    if (q != 0) return q;
    return a.$1 - b.$1;
  });
  return [for (final (_, c) in indexed) c];
}

/// One row per channel: the best copy stands for the others, in the place
/// of the first copy. Its [MediaItem.copies] says how many there are, and it
/// counts as a favorite when any copy is one.
List<MediaItem> mergeCopies(List<MediaItem> items, Map<String, StreamHealth> health) {
  final families = <String, List<MediaItem>>{};
  for (final c in items) {
    (families[familyKey(c)] ??= []).add(c);
  }
  final out = <MediaItem>[];
  final seen = <String>{};
  for (final c in items) {
    final k = familyKey(c);
    if (!seen.add(k)) continue;
    final copies = families[k]!;
    if (copies.length == 1) {
      out.add(c);
      continue;
    }
    final best = rankCopies(copies, health).first;
    out.add(
      best.copyWith(
        copies: copies.length,
        favorite: copies.any((x) => x.favorite),
        // The row stands for every copy, so its name shouldn't promise one.
        name: nameWithoutQuality(best.name),
      ),
    );
  }
  return out;
}

/// "4K", "Full HD", "HD" or "SD", from what the stream played at or its name.
String qualityLabel(MediaItem c, [StreamHealth? health]) => switch (qualityRank(c, health)) {
  4 => '4K',
  3 => 'Full HD',
  2 => 'HD',
  _ => 'SD',
};

/// A label that tells [c] apart from the other [copies]: its quality, with
/// a number when two copies share it.
String copyLabel(MediaItem c, List<MediaItem> copies, Map<String, StreamHealth> health) {
  final label = qualityLabel(c, health[c.key]);
  final same = copies.where((x) => qualityLabel(x, health[x.key]) == label).toList();
  final failing = (health[c.key]?.failing ?? false) ? ' ⚠' : '';
  return same.length < 2 ? '$label$failing' : '$label ${same.indexOf(c) + 1}$failing';
}
