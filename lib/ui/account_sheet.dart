import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'theme.dart';

/// Subscription details of an Xtream playlist: status, end date and
/// connections.
Future<void> showAccountSheet(BuildContext context, Playlist playlist) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _AccountSheet(playlist: playlist),
);

/// After start-up: warns once a day when the open Xtream playlist's
/// subscription ends within a week, has ended or is no longer active.
Future<void> warnAboutAccount(BuildContext context, WidgetRef ref) async {
  final p = ref.read(activePlaylistProvider);
  if (p == null || !p.isXtream) return;
  final prefs = ref.read(prefsProvider);
  final pref = 'account_checked_${p.id}';
  final last = DateTime.fromMillisecondsSinceEpoch(prefs.getInt(pref) ?? 0);
  if (DateTime.now().difference(last) < const Duration(hours: 20)) return;
  final XtreamAccount account;
  try {
    account = await ref.read(repositoryProvider).xtreamFor(p).account();
  } catch (_) {
    return; // offline or the server is down; the playlist screens say so
  }
  await prefs.setInt(pref, DateTime.now().millisecondsSinceEpoch);
  if (!context.mounted) return;
  final l = context.l10n;
  final days = account.daysLeft(DateTime.now());
  final String message;
  if (!account.isActive || (days != null && days < 0)) {
    message = l.accountEnded(p.name);
  } else if (days != null && days <= 7) {
    message = days == 0 ? l.accountEndsToday(p.name) : l.accountEndsInDays(p.name, days);
  } else {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(label: l.details, onPressed: () => showAccountSheet(context, p)),
    ),
  );
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet({required this.playlist});
  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final account = ref.watch(accountProvider(playlist.id));
    final date = intl.DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(l.account, style: t.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(playlist.name, style: t.bodyMedium!.copyWith(color: AppColors.muted)),
            ),
            switch (account) {
              AsyncData(:final value) => _details(context, value, date),
              AsyncError(:final error) => ListTile(
                leading: const Icon(Icons.error_outline, color: AppColors.live),
                title: Text(l.accountLoadFailed),
                subtitle: Text('$error'),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(accountProvider(playlist.id)),
                  child: Text(l.tryAgain),
                ),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }

  Widget _details(BuildContext context, XtreamAccount a, intl.DateFormat date) {
    final l = context.l10n;
    final days = a.daysLeft(DateTime.now());
    final ended = !a.isActive || (days != null && days < 0);
    final status = switch (a.status) {
      'active' when days != null && days < 0 => l.accountExpired,
      'active' => l.accountActive,
      'expired' => l.accountExpired,
      'banned' => l.accountBanned,
      'disabled' => l.accountDisabled,
      final other => other,
    };
    final warn = ended || (days != null && days <= 7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            ended ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: ended ? AppColors.live : AppColors.tally,
          ),
          title: Text(l.accountStatus),
          subtitle: Text(a.trial ? '$status · ${l.accountTrial}' : status),
        ),
        ListTile(
          leading: Icon(Icons.event_outlined, color: warn ? AppColors.live : null),
          title: Text(l.accountExpires),
          subtitle: Text(switch (a.expires) {
            null => l.accountNoEnd,
            final at when days! < 0 => date.format(at),
            final at => '${date.format(at)} · ${days == 0 ? l.accountToday : l.accountDaysLeft(days)}',
          }),
        ),
        if (a.maxConnections != null)
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: Text(l.accountConnections),
            subtitle: Text(l.accountConnectionsInUse(a.activeConnections ?? 0, a.maxConnections!)),
          ),
        if (a.createdAt != null)
          ListTile(
            leading: const Icon(Icons.history_toggle_off),
            title: Text(l.accountCreated),
            subtitle: Text(date.format(a.createdAt!)),
          ),
      ],
    );
  }
}
