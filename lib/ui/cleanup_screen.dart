import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:material_ui/material_ui.dart';

import '../data/category_filter.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'widgets.dart';

/// What a playlist offers to tidy up: its countries (with how many items
/// each has) and its adult categories.
class CleanupOptions {
  const CleanupOptions({required this.countries, required this.adultGroups, this.saved});

  /// Country code to item count, most items first.
  final List<(String, int)> countries;
  final List<String> adultGroups;
  final CategoryFilter? saved;

  /// Worth asking: there is a real choice to make.
  bool get worthAsking => countries.length >= 2 || adultGroups.isNotEmpty;
}

Future<CleanupOptions> loadCleanupOptions(WidgetRef ref, int playlistId) async {
  final db = ref.read(databaseProvider);
  final groups = await db.allGroups(playlistId);
  final counts = <String, int>{};
  final adult = <String>{};
  for (final (_, grp, n) in groups) {
    if (isAdultGroup(grp)) {
      adult.add(grp);
      continue;
    }
    final c = countryOfGroup(grp);
    if (c != null) counts[c] = (counts[c] ?? 0) + n;
  }
  final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return CleanupOptions(
    countries: [for (final e in sorted) (e.key, e.value)],
    adultGroups: adult.toList(),
    saved: await db.filterFor(playlistId),
  );
}

/// Opens the wizard for [playlistId] when the list has something to tidy.
/// [always] opens it even when there is little to choose (from the menu).
Future<void> openCleanup(BuildContext context, WidgetRef ref, int playlistId, {bool always = false}) async {
  final options = await loadCleanupOptions(ref, playlistId);
  if (!context.mounted || (!always && !options.worthAsking)) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CleanupScreen(playlistId: playlistId, options: options),
    ),
  );
}

class CleanupScreen extends ConsumerStatefulWidget {
  const CleanupScreen({super.key, required this.playlistId, required this.options});
  final int playlistId;
  final CleanupOptions options;

  @override
  ConsumerState<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends ConsumerState<CleanupScreen> {
  late final Set<String> _picked;
  late bool _hideAdult;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.options.saved;
    final codes = {for (final (c, _) in widget.options.countries) c};
    if (saved != null) {
      _picked = saved.countries.intersection(codes);
      _hideAdult = saved.hideAdult;
    } else {
      // Start from the phone's own country, which is what most people want.
      final here = PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
      _picked = {if (here != null && codes.contains(here)) here};
      _hideAdult = true;
    }
  }

  Future<void> _save(CategoryFilter filter) async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    await db.applyFilter(widget.playlistId, filter);
    final hidden = (await db.allGroups(widget.playlistId)).where((g) => filter.hides(g.$2)).length;
    ref.read(groupsVersionProvider.notifier).bump();
    ref.read(contentVersionProvider.notifier).bump();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l.cleanupDone(hidden))));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final o = widget.options;
    final lang = l.localeName;
    final number = intl.NumberFormat.decimalPattern(lang);
    final muted = t.bodySmall!.copyWith(color: AppColors.muted);

    return Scaffold(
      appBar: AppBar(title: Text(l.cleanupTitle)),
      body: LayoutBuilder(
        builder: (context, box) {
          final inset = readableInset(box.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(16 + inset, 8, 16 + inset, 24),
            children: [
              Text(
                o.countries.length >= 2 ? l.cleanupIntro(o.countries.length) : l.cleanupIntroNoCountries,
                style: t.bodyMedium,
              ),
              if (o.countries.length >= 2) ...[
                const SizedBox(height: 20),
                Text(l.cleanupCountries, style: t.titleSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (code, n) in o.countries)
                      FilterChip(
                        label: Text(l.cleanupCountryCount(countryByCode(code)?.name(lang) ?? code, number.format(n))),
                        selected: _picked.contains(code),
                        onSelected: (on) => setState(() => on ? _picked.add(code) : _picked.remove(code)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(l.cleanupNoCountryNote, style: muted),
              ],
              if (o.adultGroups.isNotEmpty) ...[
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.cleanupHideAdult),
                  subtitle: Text(l.cleanupAdultFound(o.adultGroups.join(', ')), style: muted),
                  value: _hideAdult,
                  onChanged: (v) => setState(() => _hideAdult = v),
                ),
              ],
              const SizedBox(height: 16),
              Text(l.cleanupLater, style: muted),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : () => _save(CategoryFilter(countries: {..._picked}, hideAdult: _hideAdult)),
                child: Text(l.cleanupSave),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _saving ? null : () => _save(const CategoryFilter()), child: Text(l.cleanupSkip)),
            ],
          );
        },
      ),
    );
  }
}

/// Opens the wizard for a just-added playlist, once.
void takePendingCleanup(BuildContext context, WidgetRef ref) {
  final id = ref.read(pendingCleanupProvider);
  if (id == null) return;
  ref.read(pendingCleanupProvider.notifier).set(null);
  openCleanup(context, ref, id);
}
