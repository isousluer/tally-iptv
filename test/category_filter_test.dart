import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/category_filter.dart';

void main() {
  test('reads the country from common category names', () {
    const cases = {
      'TR-SPOR': 'TR',
      'TR-ULUSAL': 'TR',
      'DE-Sports': 'DE',
      'DE-Deutschen': 'DE',
      'NO-NORWAY': 'NO',
      'UK-ENGLAND': 'GB',
      'CH-SWITZERLAND': 'CH',
      'AR-ARABIAN': 'ARAB',
      'EX-YU': 'EXYU',
      'IR-IRAN': 'IR',
      'NL | NEDERLAND HD': 'NL',
      'TR: BELGESEL': 'TR',
      '|NO| Sport': 'NO',
      'NORGE': 'NO',
      'Türkiye Ulusal': 'TR',
      'TURK FILMLERI': 'TR',
      '4K TURK FILMLERI': 'TR',
      'IT | Calcio': 'IT',
    };
    cases.forEach((name, code) => expect(countryOfGroup(name), code, reason: name));
  });

  test('categories without a country stay without one', () {
    for (final name in [
      'YABANCI MUZIK',
      'XXX - ADULT',
      'NETFLIX DIZILER',
      'BEIN-PUHU TV DIZILER',
      '4K FILMLER',
      'HBO MAX DIZILER',
      'APPLE TV+ DIZILER',
      'KEMAL SUNAL FILMLERI',
      '007 JAMES BOND MOVIES',
      'SONVIZYON FILMLER',
      'TV SHOWS',
    ]) {
      expect(countryOfGroup(name), isNull, reason: name);
    }
  });

  test('adult categories are found by name only', () {
    for (final name in ['XXX - ADULT', 'ADULTS', 'Adult 18+', 'For Adults', 'YETİŞKİN', 'Erotik']) {
      expect(isAdultGroup(name), isTrue, reason: name);
    }
    for (final name in ['Adult Swim', 'Young Adult', 'TR-SINEMA', 'KONSERLER', 'ADULTERY DRAMAS']) {
      expect(isAdultGroup(name), isFalse, reason: name);
    }
  });

  test('the filter keeps picked countries and categories without a country', () {
    const f = CategoryFilter(countries: {'TR', 'NO'}, hideAdult: true);
    expect(f.hides('TR-SPOR'), isFalse);
    expect(f.hides('NO-NORWAY'), isFalse);
    expect(f.hides('DE-Sports'), isTrue);
    expect(f.hides('YABANCI MUZIK'), isFalse);
    expect(f.hides('XXX - ADULT'), isTrue);
    expect(const CategoryFilter().hides('DE-Sports'), isFalse);
    expect(const CategoryFilter().hides('XXX - ADULT'), isFalse);
  });
}
