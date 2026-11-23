import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml_events.dart';

import 'models.dart';

/// Downloads and parses an XMLTV guide. Supports plain and gzip-compressed
/// files. Only programs for [channelIds] within the time window are kept, so
/// large guides stay cheap to store. Pure Dart: safe to run in an isolate.
Future<List<EpgProgram>> downloadEpg(
  String url,
  Set<String> channelIds, {
  Duration past = const Duration(hours: 12),
  Duration future = const Duration(days: 3),
}) async {
  final client = http.Client();
  try {
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) {
      throw HttpException('Guide download failed (${res.statusCode}).');
    }
    final bytes = await _maybeGunzip(res.stream);
    return await parseXmltv(bytes, channelIds, past: past, future: future);
  } finally {
    client.close();
  }
}

/// Peeks at the first bytes and inflates the stream when it is gzip.
Future<Stream<List<int>>> _maybeGunzip(Stream<List<int>> source) async {
  final controller = StreamController<List<int>>();
  final firstChunk = Completer<List<int>?>();
  source.listen(
    (chunk) {
      if (!firstChunk.isCompleted) firstChunk.complete(chunk);
      controller.add(chunk);
    },
    onError: controller.addError,
    onDone: () {
      if (!firstChunk.isCompleted) firstChunk.complete(null);
      controller.close();
    },
  );
  final head = await firstChunk.future;
  final isGzip = head != null && head.length >= 2 && head[0] == 0x1f && head[1] == 0x8b;
  return isGzip ? controller.stream.transform(gzip.decoder) : controller.stream;
}

Future<List<EpgProgram>> parseXmltv(
  Stream<List<int>> bytes,
  Set<String> channelIds, {
  Duration past = const Duration(hours: 12),
  Duration future = const Duration(days: 3),
}) async {
  final now = DateTime.now();
  final from = now.subtract(past);
  final to = now.add(future);
  final lowerIds = {for (final id in channelIds) id.toLowerCase()};
  final out = <EpgProgram>[];

  String? channel;
  DateTime? start;
  DateTime? stop;
  String? title;
  String? desc;
  String? textTarget;
  final text = StringBuffer();

  final events = bytes.transform(utf8.decoder).toXmlEvents().normalizeEvents().flatten();

  await for (final e in events) {
    if (e is XmlStartElementEvent) {
      if (e.name == 'programme') {
        channel = null;
        start = stop = null;
        title = desc = null;
        for (final a in e.attributes) {
          switch (a.name) {
            case 'channel':
              channel = a.value;
            case 'start':
              start = parseXmltvDate(a.value);
            case 'stop':
              stop = parseXmltvDate(a.value);
          }
        }
        if (e.isSelfClosing) channel = null;
      } else if (channel != null && (e.name == 'title' || e.name == 'desc')) {
        textTarget = e.name;
        text.clear();
        if (e.isSelfClosing) textTarget = null;
      }
    } else if (e is XmlTextEvent || e is XmlCDATAEvent) {
      if (textTarget != null) {
        text.write(e is XmlTextEvent ? e.value : (e as XmlCDATAEvent).value);
      }
    } else if (e is XmlEndElementEvent) {
      if (e.name == textTarget) {
        if (textTarget == 'title') title ??= text.toString().trim();
        if (textTarget == 'desc') desc ??= text.toString().trim();
        textTarget = null;
      } else if (e.name == 'programme') {
        if (channel != null &&
            start != null &&
            stop != null &&
            title != null &&
            lowerIds.contains(channel.toLowerCase()) &&
            stop.isAfter(from) &&
            start.isBefore(to)) {
          out.add(EpgProgram(channelId: channel, start: start, stop: stop, title: title, description: desc));
        }
        channel = null;
      }
    }
  }
  return out;
}

/// Parses `20231123190000 +0100` style timestamps into local time.
DateTime? parseXmltvDate(String raw) {
  final v = raw.trim();
  if (v.length < 12) return null;
  final y = int.tryParse(v.substring(0, 4));
  final mo = int.tryParse(v.substring(4, 6));
  final d = int.tryParse(v.substring(6, 8));
  final h = int.tryParse(v.substring(8, 10));
  final mi = int.tryParse(v.substring(10, 12));
  final s = v.length >= 14 ? int.tryParse(v.substring(12, 14)) ?? 0 : 0;
  if (y == null || mo == null || d == null || h == null || mi == null) return null;
  var utc = DateTime.utc(y, mo, d, h, mi, s);
  final tz = RegExp(r'([+-])(\d{2})(\d{2})').firstMatch(v.substring(min(14, v.length)));
  if (tz != null) {
    final sign = tz.group(1) == '-' ? -1 : 1;
    final offset = Duration(hours: int.parse(tz.group(2)!), minutes: int.parse(tz.group(3)!));
    utc = sign == 1 ? utc.subtract(offset) : utc.add(offset);
  }
  return utc.toLocal();
}

int min(int a, int b) => a < b ? a : b;
