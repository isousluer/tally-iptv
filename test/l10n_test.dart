import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/l10n/strings.dart';
import 'package:tally/ui/widgets.dart';

void main() {
  tearDown(() => useLocale(const Locale('en')));

  test('Turkish strings use Turkish number format and wording', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    expect(tr.channelCount(12345), '12.345 kanal');
    expect(tr.episodeCode(2, 5), 'S2 · B5');
  });

  test('English plurals', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.channelCount(1), '1 channel');
    expect(en.channelCount(12345), '12,345 channels');
  });

  test('helpers follow the app language', () {
    useLocale(const Locale('tr'));
    expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1 sa 5 dk');
    expect(compactCount(1500), '1.500');
    useLocale(const Locale('en'));
    expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1h 5m');
  });
}
