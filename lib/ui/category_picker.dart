import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'parental.dart';
import 'widgets.dart';

/// Category chips for a tab: hidden categories are left out, locked ones show
/// a lock and ask for the PIN before opening.
class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key, required this.kind, required this.selected, required this.onSelected});
  final ContentKind kind;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider(kind)).value ?? const <GroupInfo>[];
    final open = ref.watch(lockedContentOpenProvider);
    final visible = groups.where((g) => !g.hidden).toList();
    return CategoryStrip(
      entries: [(groupAll, 'All'), (groupFavorites, 'Favorites'), for (final g in visible) (g.name, g.name)],
      locked: open
          ? const {}
          : {
              for (final g in visible)
                if (g.locked) g.name,
            },
      selected: selected,
      onSelected: (value) async {
        final info = visible.where((g) => g.name == value).firstOrNull;
        if (info != null && info.locked && !open && !await unlockWithPin(context, ref)) return;
        onSelected(value);
      },
    );
  }
}
