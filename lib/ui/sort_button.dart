import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'theme.dart';

/// Header button that picks the order of a tab's list.
class SortButton extends ConsumerWidget {
  const SortButton({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortProvider(kind));
    return PopupMenuButton<ItemSort>(
      tooltip: 'Sort',
      initialValue: current,
      onSelected: (s) => ref.read(sortProvider(kind).notifier).set(s),
      icon: Icon(Icons.sort, color: current == ItemSort.playlist ? null : SlayerColors.tally),
      itemBuilder: (_) => [
        for (final s in ItemSort.forKind(kind))
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(s.label)),
                if (s == current) const Icon(Icons.check, size: 18, color: SlayerColors.tally),
              ],
            ),
          ),
      ],
    );
  }
}
