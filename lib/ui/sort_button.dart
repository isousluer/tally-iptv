import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'theme.dart';

String sortLabel(AppLocalizations l, ItemSort s) => switch (s) {
  ItemSort.playlist => l.sortPlaylist,
  ItemSort.number => l.sortNumber,
  ItemSort.nameAsc => l.sortNameAsc,
  ItemSort.nameDesc => l.sortNameDesc,
  ItemSort.rating => l.sortRating,
  ItemSort.year => l.sortYear,
};

/// Header button that picks the order of a tab's list.
class SortButton extends ConsumerWidget {
  const SortButton({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortProvider(kind));
    return PopupMenuButton<ItemSort>(
      tooltip: context.l10n.sort,
      initialValue: current,
      onSelected: (s) => ref.read(sortProvider(kind).notifier).set(s),
      icon: Icon(Icons.sort, color: current == ItemSort.playlist ? null : AppColors.tally),
      itemBuilder: (_) => [
        for (final s in ItemSort.forKind(kind))
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(sortLabel(context.l10n, s))),
                if (s == current) const Icon(Icons.check, size: 18, color: AppColors.tally),
              ],
            ),
          ),
      ],
    );
  }
}
