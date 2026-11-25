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
      expect(w.behind, 50);
      expect(w.isLive, isFalse);
      expect(w.useful, isTrue);
    });

    test('a few seconds behind still counts as live', () {
      final w = LiveWindow.parse('{"seekable-ranges":[{"start":0,"end":60}]}', '55')!;
      expect(w.isLive, isTrue);
    });

    test('null without ranges or a position', () {
      expect(LiveWindow.parse('{"seekable-ranges":[]}', '1'), isNull);
      expect(LiveWindow.parse('{"seekable-ranges":[{"start":0,"end":60}]}', ''), isNull);
      expect(LiveWindow.parse('not json', '1'), isNull);
    });
  });
}
