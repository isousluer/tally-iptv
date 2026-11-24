import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tally/app_info.dart';
import 'package:tally/data/update_check.dart';

void main() {
  test('compares versions by their numbers', () {
    expect(isNewerVersion('0.1.2', '0.1.1'), isTrue);
    expect(isNewerVersion('0.1.10', '0.1.9'), isTrue);
    expect(isNewerVersion('0.2.0', '0.10.0'), isFalse);
    expect(isNewerVersion('0.1.1', '0.1.1'), isFalse);
    expect(isNewerVersion('1.0', '0.9.9'), isTrue);
  });

  test('reads the latest release and drops the leading v', () async {
    final client = MockClient(
      (req) async => http.Response('{"tag_name":"v0.1.2","html_url":"https://example.com/r","draft":false}', 200),
    );
    final r = await latestRelease('owner/repo', client: client);
    expect(r?.version, '0.1.2');
    expect(r?.url, 'https://example.com/r');
  });

  test('a failed check returns null', () async {
    final client = MockClient((req) async => http.Response('nope', 404));
    expect(await latestRelease('owner/repo', client: client), isNull);
  });

  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([^+\s]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });
}
