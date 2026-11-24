import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'menu.dart';
import 'parental.dart';
import 'theme.dart';
import 'widgets.dart';

/// Hide, lock and reorder the categories of the active playlist.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  ContentKind _kind = ContentKind.live;

  /// Local order while dragging, so the list doesn't jump while saving.
  List<GroupInfo>? _order;

  void _bump() => ref.read(groupsVersionProvider.notifier).bump();

  Future<void> _toggleHidden(GroupInfo g) async {
    final p = ref.read(activePlaylistProvider);
    if (p == null) return;
    await ref.read(databaseProvider).setGroupFlags(p.id, _kind, g.name, hidden: !g.hidden);
    _bump();
  }

  Future<void> _toggleLocked(GroupInfo g) async {
    final p = ref.read(activePlaylistProvider);
    if (p == null) return;
    if (!await _ensurePin()) return;
    await ref.read(databaseProvider).setGroupFlags(p.id, _kind, g.name, locked: !g.locked);
    _bump();
  }

  /// Locking needs a PIN; offers to create one the first time.
  Future<bool> _ensurePin() async {
    if (ref.read(parentalPinProvider) != null) return unlockWithPin(context, ref);
    final pin = await choosePin(context);
    if (pin == null) return false;
    await ref.read(parentalPinProvider.notifier).set(pin);
    ref.read(parentalUnlockedProvider.notifier).set(true);
    return true;
  }

  Future<void> _lockAdult(List<GroupInfo> groups) async {
    final p = ref.read(activePlaylistProvider);
    if (p == null) return;
    final matches = groups.where((g) => adultGroupPattern.hasMatch(g.name) && !g.locked).toList();
    final messenger = ScaffoldMessenger.of(context);
    if (matches.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.noAdultCategories)));
      return;
    }
    if (!await _ensurePin()) return;
    final db = ref.read(databaseProvider);
    for (final g in matches) {
      await db.setGroupFlags(p.id, _kind, g.name, locked: true);
    }
    _bump();
    messenger.showSnackBar(SnackBar(content: Text(strings.lockedCategories(matches.length))));
  }

  Future<void> _reorder(List<GroupInfo> list, int from, int to) async {
    final p = ref.read(activePlaylistProvider);
    if (p == null) return;
    final copy = [...list];
    final moved = copy.removeAt(from);
    copy.insert(to, moved);
    setState(() => _order = copy);
    await ref.read(databaseProvider).setGroupOrder(p.id, _kind, [for (final g in copy) g.name]);
    _bump();
  }

  Future<void> _reset() async {
    final p = ref.read(activePlaylistProvider);
    if (p == null) return;
    await ref.read(databaseProvider).resetGroupPrefs(p.id, _kind);
    setState(() => _order = null);
    _bump();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final async = ref.watch(groupsProvider(_kind));
    final fresh = async.value;
    // Keep the dragged order on screen until the stored one has caught up.
    final groups = _order != null && (fresh == null || !_sameOrder(_order!, fresh)) ? _order : fresh;

    // Locks take effect as soon as you leave: the PIN entered here only
    // opens locked categories while editing them.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && ref.read(parentalPinProvider) != null) {
          ref.read(parentalUnlockedProvider.notifier).set(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.categories),
          actions: [
            MenuButton<String>(
              tooltip: context.l10n.more,
              onSelected: (v) {
                if (v == 'adult') _lockAdult(groups ?? const []);
                if (v == 'reset') _reset();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'adult', child: Text(context.l10n.lockAdultCategories)),
                PopupMenuItem(value: 'reset', child: Text(context.l10n.showAllRestoreOrder)),
              ],
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, box) {
            final inset = readableInset(box.maxWidth);
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16 + inset, 8, 16 + inset, 4),
                  child: SegmentedButton<ContentKind>(
                    segments: [
                      ButtonSegment(value: ContentKind.live, label: Text(context.l10n.liveTv)),
                      ButtonSegment(value: ContentKind.movie, label: Text(context.l10n.movies)),
                      ButtonSegment(value: ContentKind.series, label: Text(context.l10n.series)),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() {
                      _kind = s.first;
                      _order = null;
                    }),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16 + inset, 8, 16 + inset, 4),
                  child: Text(context.l10n.categoriesHelp, style: t.bodySmall!.copyWith(color: AppColors.muted)),
                ),
                Expanded(
                  child: groups == null
                      ? const Center(child: CircularProgressIndicator())
                      : groups.isEmpty
                      ? EmptyState(icon: Icons.category_outlined, title: context.l10n.noCategoriesHere)
                      : ReorderableListView.builder(
                          padding: EdgeInsets.fromLTRB(inset, 0, inset, 24),
                          itemCount: groups.length,
                          buildDefaultDragHandles: false,
                          onReorderItem: (a, b) => _reorder(groups, a, b),
                          itemBuilder: (_, i) {
                            final g = groups[i];
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 16, right: 4),
                              key: ValueKey(g.name),
                              title: Text(
                                g.name.isEmpty ? context.l10n.uncategorized : g.name,
                                style: TextStyle(color: g.hidden ? AppColors.muted : null),
                              ),
                              subtitle: Text(compactCount(g.count)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: g.locked ? context.l10n.unlock : context.l10n.lockWithPin,
                                    onPressed: () => _toggleLocked(g),
                                    icon: Icon(
                                      g.locked ? Icons.lock : Icons.lock_open_outlined,
                                      color: g.locked ? AppColors.tally : AppColors.muted,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: g.hidden ? context.l10n.show : context.l10n.hide,
                                    onPressed: () => _toggleHidden(g),
                                    icon: Icon(
                                      g.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: g.hidden ? AppColors.muted : AppColors.text,
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(4, 8, 8, 8),
                                      child: Icon(Icons.drag_handle, color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static bool _sameOrder(List<GroupInfo> a, List<GroupInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name) return false;
    }
    return true;
  }
}
