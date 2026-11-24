import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../data/update_check.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';

Future<void> openLink(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// After start-up: tells the viewer about a new release, once per version and
/// at most twice a day.
Future<void> notifyAboutUpdate(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(prefsProvider);
  final last = DateTime.fromMillisecondsSinceEpoch(prefs.getInt('update_checked_at') ?? 0);
  if (DateTime.now().difference(last) < const Duration(hours: 12)) return;
  final release = await latestRelease(repoSlug);
  await prefs.setInt('update_checked_at', DateTime.now().millisecondsSinceEpoch);
  if (release == null || !isNewerVersion(release.version, appVersion)) return;
  if (prefs.getString('update_seen') == release.version) return;
  await prefs.setString('update_seen', release.version);
  if (context.mounted) _showUpdate(context, release);
}

/// Checks right away, for the button in Settings.
Future<void> checkForUpdateNow(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  messenger.showSnackBar(SnackBar(content: Text(l.checkingForUpdates), duration: const Duration(seconds: 2)));
  final release = await latestRelease(repoSlug);
  messenger.hideCurrentSnackBar();
  if (release == null) {
    messenger.showSnackBar(SnackBar(content: Text(l.updateCheckFailed)));
  } else if (!isNewerVersion(release.version, appVersion)) {
    messenger.showSnackBar(SnackBar(content: Text(l.upToDate(appVersion))));
  } else if (context.mounted) {
    _showUpdate(context, release);
  }
}

void _showUpdate(BuildContext context, AppRelease release) {
  final l = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l.updateAvailable(release.version)),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(label: l.download, onPressed: () => openLink(release.url)),
    ),
  );
}
