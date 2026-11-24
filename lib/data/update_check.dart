import 'dart:convert';

import 'package:http/http.dart' as http;

/// The newest published release on GitHub.
class AppRelease {
  const AppRelease({required this.version, required this.url});

  /// Version without the leading "v", like `0.1.2`.
  final String version;

  /// Release page, where the APKs and installers are.
  final String url;
}

/// Asks GitHub for the latest release of [repo] ("owner/name"). Returns null
/// when there is none or GitHub can't be reached; update checks never fail
/// loudly.
Future<AppRelease?> latestRelease(String repo, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final res = await c
        .get(
          Uri.https('api.github.com', '/repos/$repo/releases/latest'),
          headers: const {'Accept': 'application/vnd.github+json', 'User-Agent': 'Tally'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data is! Map || data['draft'] == true || data['prerelease'] == true) return null;
    final tag = '${data['tag_name'] ?? ''}'.trim();
    final url = '${data['html_url'] ?? ''}';
    if (tag.isEmpty || url.isEmpty) return null;
    return AppRelease(version: tag.replaceFirst(RegExp('^v', caseSensitive: false), ''), url: url);
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// Whether [candidate] is a newer version than [current]. Compares the
/// numeric parts, so `0.1.10` is newer than `0.1.9`.
bool isNewerVersion(String candidate, String current) {
  List<int> parts(String v) => v.split(RegExp(r'[.+-]')).take(3).map((p) => int.tryParse(p) ?? 0).toList();
  final a = parts(candidate), b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}
