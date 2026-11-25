import 'dart:convert';
import 'dart:math';

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
/// to [end], the live edge, with playback at [position]. All in seconds of
/// the stream's own clock. [behind] is how far the viewer has moved away from
/// live by pausing or rewinding.
class LiveWindow {
  const LiveWindow({required this.start, required this.end, required this.position, this.behind = 0});

  final double start;
  final double end;
  final double position;
  final double behind;

  double get length => end - start;

  bool get isLive => behind < 1;

  /// Whether there is enough behind the viewer to bother showing a bar.
  bool get useful => length > 15;

  /// Reads mpv's `demuxer-cache-state` (JSON) and `time-pos` as they are:
  /// [end] is the newest data received. Null when the cache has no seekable
  /// range yet.
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

/// Keeps track of how far behind live the viewer is.
///
/// Providers send live TV in bursts, so the newest data received runs a few
/// seconds ahead of playback, by an amount that keeps changing. Measuring
/// "behind" from it made the label flicker. Instead, only what the viewer does
/// counts: pausing adds the time paused, rewinding adds the seconds jumped,
/// and going forward takes them off again.
class TimeshiftTracker {
  /// How far playback trails the newest data while live, smoothed. Where
  /// "live" sits on the bar.
  double _lag = -1;

  /// Seconds behind live because of the viewer.
  double _behind = 0;

  void reset() {
    _lag = -1;
    _behind = 0;
  }

  double get behind => _behind;

  /// Turns a raw reading into what the bar shows. [paused] is true while the
  /// viewer has playback paused; [elapsed] is the time since the last reading.
  LiveWindow update(LiveWindow raw, {required bool paused, required double elapsed}) {
    final lag = (raw.end - raw.position).clamp(0.0, double.infinity);
    if (_behind == 0 && !paused) {
      // Smoothed, so a burst of data doesn't move the live edge much.
      _lag = _lag < 0 ? lag : _lag * 0.8 + lag * 0.2;
    }
    if (paused) _behind += elapsed;
    final edge = max(raw.start, raw.end - max(_lag, 0));
    _behind = _behind.clamp(0.0, max(0.0, edge - raw.start));
    return LiveWindow(
      start: raw.start,
      end: edge,
      position: _behind == 0 ? edge : max(raw.start, edge - _behind),
      behind: _behind,
    );
  }

  /// Where to seek for [seconds] on the bar; moving within a second of live
  /// counts as live.
  double seekTo(LiveWindow w, double seconds) {
    final to = seconds.clamp(w.start, w.end).toDouble();
    _behind = w.end - to < 1 ? 0 : w.end - to;
    return w.end - _behind;
  }

  /// Where to seek after jumping [seconds] (negative is back).
  double seekBy(LiveWindow w, double seconds) => seekTo(w, w.end - _behind + seconds);
}
