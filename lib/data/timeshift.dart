import 'dart:convert';

/// Roughly what a minute of live TV takes on disk (about 5 Mbit/s).
const timeshiftBytesPerMinute = 40 * 1024 * 1024;

/// Space left free on the phone, whatever the setting says.
const timeshiftReserveBytes = 1024 * 1024 * 1024;

/// Minutes the viewer can pick in Settings; 0 is off.
const timeshiftChoices = [0, 5, 10, 30];

/// Bytes of past live TV to keep for [minutes], shrunk when the phone is
/// low on space ([freeBytes], null when unknown). 0 turns rewinding off.
int timeshiftBytes(int minutes, int? freeBytes) {
  var bytes = minutes * timeshiftBytesPerMinute;
  if (freeBytes != null) {
    final room = freeBytes - timeshiftReserveBytes;
    if (room < bytes) bytes = room;
  }
  // Less than a minute isn't worth the disk writes.
  return bytes < timeshiftBytesPerMinute ? 0 : bytes;
}

/// The part of a live stream the viewer can move around in: from [start]
/// to [end] (the newest picture received), with playback at [position].
/// All in seconds of the stream's own clock.
class LiveWindow {
  const LiveWindow({required this.start, required this.end, required this.position});

  final double start;
  final double end;
  final double position;

  double get length => end - start;

  /// Seconds behind the newest picture.
  double get behind => (end - position).clamp(0, double.infinity);

  /// How far behind still counts as live: providers send a few seconds
  /// ahead, so playback always trails the newest picture a little.
  static const liveSlack = 10.0;

  bool get isLive => behind < liveSlack;

  /// Whether there is enough behind the viewer to bother showing a bar.
  bool get useful => length > 15;

  /// Reads mpv's `demuxer-cache-state` (JSON) and `time-pos`. Null when the
  /// cache has no seekable range yet.
  static LiveWindow? parse(String cacheState, String timePos) {
    final pos = double.tryParse(timePos.trim());
    if (pos == null) return null;
    final Object? data;
    try {
      data = jsonDecode(cacheState);
    } on FormatException {
      return null;
    }
    if (data is! Map) return null;
    final ranges = data['seekable-ranges'];
    if (ranges is! List) return null;
    // The range that holds playback; after a reconnect there can be older ones.
    LiveWindow? best;
    for (final r in ranges.whereType<Map>()) {
      final s = r['start'], e = r['end'];
      if (s is! num || e is! num || e <= s) continue;
      final w = LiveWindow(start: s.toDouble(), end: e.toDouble(), position: pos);
      if (pos >= w.start - 1 && pos <= w.end + 1) return w;
      if (best == null || w.end > best.end) best = w;
    }
    return best;
  }
}
