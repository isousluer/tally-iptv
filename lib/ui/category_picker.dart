import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'categories_screen.dart';
import 'parental.dart';
import 'theme.dart';
import 'widgets.dart';

String _label(String group) => group.isEmpty ? strings.uncategorized : group;

/// Categories a tab shows (hidden ones left out), plus whether locked ones are open.
({List<GroupInfo>? groups, List<GroupInfo> visible, bool open}) _watchGroups(WidgetRef ref, ContentKind kind) {
  final groups = ref.watch(groupsProvider(kind)).value;
  final open = ref.watch(lockedContentOpenProvider);
  return (groups: groups, visible: [...?groups?.where((g) => !g.hidden)], open: open);
}

/// When the open category was just hidden or locked, falls back to All.
void _keepSelectionValid(
  List<GroupInfo>? groups,
  List<GroupInfo> visible,
  bool open,
  String selected,
  ValueChanged<String> onSelected,
) {
  if (groups == null || selected == groupAll || selected == groupFavorites) return;
  final current = visible.where((g) => g.name == selected).firstOrNull;
  if (current == null || (current.locked && !open)) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onSelected(groupAll));
  }
}

/// Selects [value], asking for the PIN first when it's a locked category.
Future<bool> _choose(
  BuildContext context,
  WidgetRef ref,
  GroupInfo? info,
  String value,
  ValueChanged<String> onSelected,
) async {
  if (info != null && info.locked && !ref.read(lockedContentOpenProvider)) {
    if (!await unlockWithPin(context, ref)) return false;
  }
  onSelected(value);
  return true;
}

/// Phone layout: All, Favorites and a button that opens the searchable
/// category menu.
class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key, required this.kind, required this.selected, required this.onSelected});
  final ContentKind kind;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final (:groups, :visible, :open) = _watchGroups(ref, kind);
    _keepSelectionValid(groups, visible, open, selected, onSelected);
    final inCategory = selected != groupAll && selected != groupFavorites;

    Widget chip(String value, String label) {
      final active = selected == value;
      return ChoiceChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => onSelected(value),
        labelStyle: t.labelMedium!.copyWith(color: active ? AppColors.onTally : AppColors.text),
        side: BorderSide(color: active ? AppColors.tally : AppColors.border),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          chip(groupAll, context.l10n.all),
          const SizedBox(width: 8),
          chip(groupFavorites, context.l10n.favorites),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () => showCategorySheet(context, kind: kind, selected: selected, onSelected: onSelected),
              style: OutlinedButton.styleFrom(
                foregroundColor: inCategory ? AppColors.tally : AppColors.text,
                side: BorderSide(color: inCategory ? AppColors.tally : AppColors.border),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
                minimumSize: const Size(0, 34),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inCategory ? _label(selected) : context.l10n.categories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelMedium!.copyWith(color: inCategory ? AppColors.tally : AppColors.text),
                    ),
                  ),
                  if (!inCategory && visible.isNotEmpty)
                    Text(
                      '${visible.length}',
                      style: t.labelSmall!.copyWith(color: AppColors.muted, fontFeatures: tabular),
                    ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the searchable category menu from the bottom of the screen.
Future<void> showCategorySheet(
  BuildContext context, {
  required ContentKind kind,
  required String selected,
  required ValueChanged<String> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final keyboard = mq.viewInsets.bottom;
      // Keep the menu below the status bar when the keyboard pushes it up,
      // and keep its last row clear of the navigation bar.
      // The sheet drops the top padding from its own context, so read the
      // status bar height from the screen that opened it.
      final statusBar = MediaQuery.paddingOf(context).top;
      final room = mq.size.height - keyboard - statusBar - 104;
      final height = min(mq.size.height * 0.8, room);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard > 0 ? keyboard : mq.padding.bottom),
        child: SizedBox(
          height: height,
          child: CategoryList(
            kind: kind,
            selected: selected,
            showShortcuts: false,
            onSelected: (v) {
              Navigator.pop(ctx);
              onSelected(v);
            },
          ),
        ),
      );
    },
  );
}

/// Tablet, desktop and TV layout: categories in a column beside the list.
class CategoryPanel extends ConsumerWidget {
  const CategoryPanel({super.key, required this.kind, required this.selected, required this.onSelected});
  final ContentKind kind;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:groups, :visible, :open) = _watchGroups(ref, kind);
    _keepSelectionValid(groups, visible, open, selected, onSelected);
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: CategoryList(kind: kind, selected: selected, showShortcuts: true, onSelected: onSelected),
    );
  }
}

/// Search box and category rows with counts, used by the menu and the panel.
class CategoryList extends ConsumerStatefulWidget {
  const CategoryList({
    super.key,
    required this.kind,
    required this.selected,
    required this.onSelected,
    required this.showShortcuts,
  });
  final ContentKind kind;
  final String selected;
  final ValueChanged<String> onSelected;

  /// Adds All and Favorites rows (the phone shows those as chips instead).
  final bool showShortcuts;

  @override
  ConsumerState<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<CategoryList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (:groups, :visible, :open) = _watchGroups(ref, widget.kind);
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty ? visible : visible.where((g) => _label(g.name).toLowerCase().contains(q)).toList();

    Widget row(String value, String label, {int? count, bool locked = false, IconData? icon}) {
      final active = widget.selected == value;
      // The highlight sits in its own Material: a ListTile's tile color is
      // painted on the nearest Material outside the list, so it would show
      // behind the search box once the row scrolls under it.
      return Material(
        color: active ? AppColors.tally.withAlpha(0x1F) : Colors.transparent,
        child: ListTile(
          dense: true,
          selected: active,
          leading: icon == null ? null : Icon(icon, size: 20, color: active ? AppColors.tally : AppColors.muted),
          title: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodyLarge!.copyWith(color: active ? AppColors.tally : (locked ? AppColors.muted : null)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count != null)
                Text(
                  compactCount(count),
                  style: t.labelMedium!.copyWith(color: AppColors.muted, fontFeatures: tabular),
                ),
              if (locked) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
              ],
              if (active) ...[const SizedBox(width: 8), const Icon(Icons.check, size: 18, color: AppColors.tally)],
            ],
          ),
          onTap: () =>
              _choose(context, ref, visible.where((g) => g.name == value).firstOrNull, value, widget.onSelected),
        ),
      );
    }

    final manage = ListTile(
      dense: true,
      leading: const Icon(Icons.tune, size: 20, color: AppColors.muted),
      title: Text(context.l10n.manageCategories, style: t.bodyMedium!.copyWith(color: AppColors.muted)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
    );

    return LayoutBuilder(
      builder: (context, box) {
        // A phone on its side leaves little height for the panel, so drop the
        // title and move Manage categories to the end of the list.
        final short = widget.showShortcuts && box.maxHeight < 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!short)
              Padding(
                padding: EdgeInsets.fromLTRB(16, widget.showShortcuts ? 12 : 0, 16, 4),
                child: Row(
                  children: [
                    Expanded(child: Text(context.l10n.categories, style: t.titleMedium)),
                    Text('${visible.length}', style: t.labelMedium!.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, short ? 12 : 6, 16, 6),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.findCategory,
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: groups == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        if (widget.showShortcuts && q.isEmpty) ...[
                          row(groupAll, context.l10n.all, icon: Icons.apps),
                          row(groupFavorites, context.l10n.favorites, icon: Icons.star_border),
                          const Divider(height: 12),
                        ],
                        for (final g in shown) row(g.name, _label(g.name), count: g.count, locked: g.locked && !open),
                        if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.l10n.noCategoryMatches(_query),
                              textAlign: TextAlign.center,
                              style: t.bodyMedium!.copyWith(color: AppColors.muted),
                            ),
                          ),
                        if (short) ...[const Divider(height: 12), manage],
                      ],
                    ),
            ),
            if (!short) ...[const Divider(height: 1), manage],
          ],
        );
      },
    );
  }
}
