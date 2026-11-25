import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/timeshift.dart';

void main() {
  const mb = 1024 * 1024;
  const gb = 1024 * mb;

  group('timeshiftBytes', () {
    test('uses 40 MB a minute when there is room', () {
      expect(timeshiftBytes(10, 20 * gb), 400 * mb);
      expect(timeshiftBytes(10, null), 400 * mb);
    });

    test('shrinks to keep a gigabyte free', () {
      expect(timeshiftBytes(30, gb + 200 * mb), 200 * mb);
    });

    test('turns off when less than a minute fits', () {
      expect(timeshiftBytes(10, gb + 10 * mb), 0);
      expect(timeshiftBytes(0, 20 * gb), 0);
    });
  });

  group('LiveWindow.parse', () {
    test('reads the range playback is in', () {
      final w = LiveWindow.parse(
        '{"seekable-ranges":[{"start":10.0,"end":20.0},{"start":100.5,"end":400.0}],"cache-end":400.0}',
        '350.000000',
      )!;
      expect(w.start, 100.5);
      expect(w.end, 400.0);
      expect(w.position, 350.0);
      expect(w.useful, isTrue);
    });

    test('null without ranges or a position', () {
      expect(LiveWindow.parse('{"seekable-ranges":[]}', '1'), isNull);
      expect(LiveWindow.parse('{"seekable-ranges":[{"start":0,"end":60}]}', ''), isNull);
      expect(LiveWindow.parse('not json', '1'), isNull);
    });
  });

  group('TimeshiftTracker', () {
    LiveWindow raw(double end, double pos) => LiveWindow(start: 0, end: end, position: pos);

    test('data arriving in bursts never moves the viewer off live', () {
      final t = TimeshiftTracker();
      // Playback trails the newest data by 2 to 9 seconds, changing all the time.
      for (var i = 0; i < 60; i++) {
        final pos = 100.0 + i;
        final w = t.update(raw(pos + (i % 4 == 0 ? 9 : 2), pos), paused: false, elapsed: 1);
        expect(w.isLive, isTrue);
        expect(w.behind, 0);
      }
    });

    test('pausing adds the time paused, and it stays while playing on', () {
      final t = TimeshiftTracker();
      t.update(raw(103, 100), paused: false, elapsed: 0);
      for (var i = 1; i <= 5; i++) {
        t.update(raw(103.0 + i, 100), paused: true, elapsed: 1);
      }
      expect(t.behind, 5);
      final w = t.update(raw(110, 101), paused: false, elapsed: 1);
      expect(w.behind, 5);
      expect(w.isLive, isFalse);
    });

    test('jumps add up and going forward past live is live again', () {
      final t = TimeshiftTracker();
      var w = t.update(raw(203, 200), paused: false, elapsed: 0);
      final edge = w.end;
      expect(t.seekBy(w, -10), closeTo(edge - 10, 1e-9));
      expect(t.seekBy(w, -10), closeTo(edge - 20, 1e-9));
      expect(t.behind, 20);
      expect(t.seekBy(w, 30), closeTo(edge, 1e-9));
      expect(t.behind, 0);
      w = t.update(raw(204, 201), paused: false, elapsed: 1);
      expect(w.isLive, isTrue);
    });

    test('can not go back further than the disk keeps', () {
      final t = TimeshiftTracker();
      final w = t.update(raw(33, 30), paused: false, elapsed: 0);
      expect(t.seekBy(w, -100), 0);
      expect(t.behind, closeTo(30, 1e-9));
    });
  });
}
