import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:slayer_iptv/data/epg_parser.dart';
import 'package:slayer_iptv/data/m3u_parser.dart';
import 'package:slayer_iptv/data/models.dart';
import 'package:slayer_iptv/data/repository.dart';

void main() {
  group('parseM3u', () {
    const sample = '''
#EXTM3U url-tvg="http://example.com/guide.xml"
#EXTINF:-1 tvg-id="news.us" tvg-name="City News" tvg-logo="http://logo/news.png" group-title="News",City News, Live
http://example.com/live/1.ts
#EXTINF:-1 tvg-id="sport.us" group-title="Sports",Arena Sports 1
#EXTVLCOPT:http-user-agent=Mozilla
http://example.com/live/2.m3u8
#EXTINF:-1,Big Movie (2021)
http://example.com/movie/user/pass/77.mkv
#EXTINF:-1,Duplicate
http://example.com/live/1.ts
#EXTINF:-1
#EXTGRP:Music
http://example.com/live/3.ts
''';

    test('reads channels, groups, logos and the guide link', () {
      final r = parseM3u(sample, 1);
      expect(r.epgUrl, 'http://example.com/guide.xml');
      expect(r.items, hasLength(4));

      final news = r.items[0];
      expect(news.name, 'City News, Live');
      expect(news.group, 'News');
      expect(news.tvgId, 'news.us');
      expect(news.logo, 'http://logo/news.png');
      expect(news.kind, ContentKind.live);

      expect(r.items[1].name, 'Arena Sports 1');
      expect(r.items[2].kind, ContentKind.movie);
      expect(r.items[3].group, 'Music');
      expect(r.items[3].name, 'Channel 4');
    });

    test('handles CRLF line endings', () {
      final r = parseM3u(sample.replaceAll('\n', '\r\n'), 1);
      expect(r.items, hasLength(4));
      expect(r.items.first.url, 'http://example.com/live/1.ts');
    });
  });

  group('upgradeXtreamLink', () {
    Playlist m3u(String url) => Playlist(id: 0, name: 'x', type: SourceType.m3uUrl, url: url);

    test('turns get.php links into an Xtream login', () {
      final p = PlaylistRepository.upgradeXtreamLink(
          m3u('http://tv.example.com:8080/get.php?username=ann&password=s3cret&type=m3u_plus&output=ts'));
      expect(p.type, SourceType.xtream);
      expect(p.server, 'http://tv.example.com:8080');
      expect(p.username, 'ann');
      expect(p.password, 's3cret');
    });

    test('leaves other links alone', () {
      final p = PlaylistRepository.upgradeXtreamLink(m3u('https://example.com/list.m3u'));
      expect(p.type, SourceType.m3uUrl);
    });
  });

  group('XMLTV', () {
    test('parses dates with time zone offsets', () {
      final d = parseXmltvDate('20261123190000 +0100')!;
      expect(d.toUtc(), DateTime.utc(2026, 11, 23, 18));
    });

    test('keeps programs for known channels only', () async {
      final now = DateTime.now().toUtc();
      String fmt(DateTime d) =>
          '${d.year}${pad2(d.month)}${pad2(d.day)}${pad2(d.hour)}${pad2(d.minute)}00 +0000';
      final start = fmt(now.subtract(const Duration(minutes: 30)));
      final stop = fmt(now.add(const Duration(minutes: 30)));
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="news.us"><display-name>News</display-name></channel>
  <programme start="$start" stop="$stop" channel="news.us">
    <title lang="en">Evening news</title>
    <desc>Headlines &amp; weather</desc>
  </programme>
  <programme start="$start" stop="$stop" channel="other.us">
    <title>Ignored</title>
  </programme>
</tv>''';
      final list = await parseXmltv(Stream.value(utf8.encode(xml)), {'NEWS.us'});
      expect(list, hasLength(1));
      expect(list.single.title, 'Evening news');
      expect(list.single.description, 'Headlines & weather');
      expect(list.single.isLiveAt(DateTime.now()), isTrue);
    });
  });
}

String pad2(int v) => v.toString().padLeft(2, '0');
