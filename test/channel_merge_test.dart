import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/channel_merge.dart';
import 'package:tally/data/models.dart';

MediaItem ch(String name, {String group = 'TR-SPOR', String? key}) =>
    MediaItem(playlistId: 1, kind: ContentKind.live, key: key ?? name, name: name, group: group, url: 'u');

void main() {
  test('copies share a base name without quality tags', () {
    expect(baseChannelName('TR: beIN SPORTS 1 SD/MOBIL'), 'BEIN SPORTS 1');
    expect(baseChannelName('TR: beIN SPORTS 1 HD'), 'BEIN SPORTS 1');
    expect(baseChannelName('TR: beIN SPORTS 1 FHD ᴿᴬᵂ'), 'BEIN SPORTS 1');
    expect(baseChannelName('|TR| ATV 4K HEVC'), 'ATV');
    expect(baseChannelName('TR: ATV AVRUPA HD'), 'ATV AVRUPA');
    expect(baseChannelName('TR: MAXSPORTS 4 Formula 1'), 'MAXSPORTS 4 FORMULA 1');
    expect(baseChannelName('S Sport Plus HD'), 'S SPORT PLUS');
  });

  test('ranks by health, then quality, then playlist order', () {
    final sd = ch('beIN SPORTS 1 SD'), hd = ch('beIN SPORTS 1 HD'), fhd = ch('beIN SPORTS 1 FHD');
    expect(rankCopies([sd, hd, fhd], const {}), [fhd, hd, sd]);
    // Full HD failed twice: it goes last.
    expect(rankCopies([sd, hd, fhd], {fhd.key: const StreamHealth(fails: 2)}), [hd, sd, fhd]);
    // Named FHD but played at 576 lines: it is really SD.
    expect(rankCopies([hd, fhd], {fhd.key: const StreamHealth(height: 576)}), [hd, fhd]);
  });

  test('a list shows one row per channel, in the place of the first copy', () {
    final items = [
      ch('TR: beIN SPORTS 1 SD/MOBIL'),
      ch('TR: beIN SPORTS 1 HD'),
      ch('TR: ATV HD'),
      ch('TR: ATV AVRUPA HD'),
      ch('TR: beIN SPORTS 1 FHD'),
      // Same name in another category stays apart.
      ch('TR: ATV HD', group: 'TR-ULUSAL', key: 'atv2'),
    ];
    final merged = mergeCopies(items, const {});
    expect(merged.map((c) => c.name), [
      'TR: beIN SPORTS 1 FHD',
      'TR: ATV HD',
      'TR: ATV AVRUPA HD',
      'TR: ATV HD',
    ]);
    expect(merged.first.copies, 3);
    expect(merged[1].copies, 1);
  });

  test('labels tell copies apart', () {
    final a = ch('X HD', key: 'a'), b = ch('X HD backup', key: 'b'), c = ch('X SD', key: 'c');
    expect(copyLabel(a, [a, b, c], const {}), 'HD 1');
    expect(copyLabel(b, [a, b, c], const {}), 'HD 2');
    expect(copyLabel(c, [a, b, c], const {}), 'SD');
  });
}
