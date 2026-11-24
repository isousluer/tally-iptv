import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'menu.dart';
import 'playback.dart';
import 'theme.dart';
import 'widgets.dart';

/// Asks for a list name. Returns null when cancelled or left empty.
Future<String?> askListName(BuildContext context, {String initial = ''}) async {
  final l = context.l10n;
  final c = TextEditingController(text: initial);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(initial.isEmpty ? l.newList : l.renameList),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l.listNameHint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(l.save)),
      ],
    ),
  );
  return name == null || name.isEmpty ? null : name;
}

/// Ticks [channel] in or out of the viewer's lists, with a way to start a
/// new one.
Future<void> showAddToLists(BuildContext context, MediaItem channel) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _AddToListsSheet(channel: channel),
);

class _AddToListsSheet extends ConsumerStatefulWidget {
  const _AddToListsSheet({required this.channel});
  final MediaItem channel;

  @override
  ConsumerState<_AddToListsSheet> createState() => _AddToListsSheetState();
}

class _AddToListsSheetState extends ConsumerState<_AddToListsSheet> {
  Set<int>? _in;

  ChannelListsController get _lists => ref.read(channelListsControllerProvider);

  @override
  void initState() {
    super.initState();
    _lists.listsWith(widget.channel).then((v) {
      if (mounted) setState(() => _in = v);
    });
  }

  Future<void> _set(int id, bool value) async {
    setState(() => value ? _in!.add(id) : _in!.remove(id));
    await _lists.setIn(id, widget.channel, value);
  }

  Future<void> _create() async {
    final name = await askListName(context);
    if (name == null) return;
    final id = await _lists.create(name);
    if (id != null) await _set(id, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final lists = ref.watch(channelListsProvider).value ?? const <ChannelList>[];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
              child: Text(l.addToList, style: t.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(widget.channel.name, style: t.bodyMedium!.copyWith(color: AppColors.muted)),
            ),
            if (_in == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final list in lists)
                      CheckboxListTile(
                        value: _in!.contains(list.id),
                        onChanged: (v) => _set(list.id, v ?? false),
                        title: Text(list.name),
                        subtitle: Text(l.channelCount(list.count)),
                        secondary: const Icon(Icons.playlist_play),
                        activeColor: AppColors.tally,
                        checkColor: AppColors.onTally,
                      ),
                    ListTile(
                      leading: const Icon(Icons.add, color: AppColors.tally),
                      title: Text(l.newList),
                      onTap: _create,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// The viewer's channel lists: make, rename, delete and reorder them.
class ChannelListsScreen extends ConsumerWidget {
  const ChannelListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lists = ref.watch(channelListsProvider).value;
    final controller = ref.read(channelListsControllerProvider);

    Future<void> create() async {
      final name = await askListName(context);
      if (name != null) await controller.create(name);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.channelLists)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: create,
        icon: const Icon(Icons.add),
        label: Text(l.newList),
      ),
      body: switch (lists) {
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(icon: Icons.playlist_add, title: l.noListsTitle, message: l.noListsMessage),
        final lists => ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
          itemCount: lists.length,
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) {
            final next = [...lists];
            final moved = next.removeAt(from);
            next.insert(to, moved);
            controller.reorder(next);
          },
          itemBuilder: (context, i) {
            final list = lists[i];
            return ListTile(
              key: ValueKey(list.id),
              leading: const Icon(Icons.playlist_play, color: AppColors.tally),
              title: Text(list.name),
              subtitle: Text(l.channelCount(list.count)),
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChannelListScreen(listId: list.id))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MenuButton<String>(
                    tooltip: l.listOptions,
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final name = await askListName(context, initial: list.name);
                        if (name != null) await controller.rename(list, name);
                      } else if (v == 'delete' && await _confirmDelete(context, list)) {
                        await controller.delete(list);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'rename', child: Text(l.rename)),
                      PopupMenuItem(value: 'delete', child: Text(l.deleteList)),
                    ],
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      },
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, ChannelList list) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.deleteListTitle(list.name)),
      content: Text(l.deleteListBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.live),
          child: Text(l.deleteList),
        ),
      ],
    ),
  );
  return ok == true;
}

/// One list's channels in the viewer's order: play, reorder or take out.
class ChannelListScreen extends ConsumerWidget {
  const ChannelListScreen({super.key, required this.listId});
  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final list = ref.watch(channelListsProvider).value?.where((x) => x.id == listId).firstOrNull;
    final query = (kind: ContentKind.live, group: listGroup(listId), search: '');
    final channels = ref.watch(itemsProvider(query)).value;
    final controller = ref.read(channelListsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(list?.name ?? '')),
      body: switch (channels) {
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(icon: Icons.playlist_add, title: l.listEmptyTitle, message: l.listEmptyMessage),
        final channels => ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          itemCount: channels.length,
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) {
            final next = [...channels];
            final moved = next.removeAt(from);
            next.insert(to, moved);
            controller.reorderChannels(listId, next);
          },
          itemBuilder: (context, i) {
            final c = channels[i];
            return ListTile(
              key: ValueKey(c.key),
              leading: ChannelLogo(name: c.name, url: c.logo, size: 40),
              title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                c.group.isEmpty ? l.uncategorized : c.group,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall!.copyWith(color: AppColors.muted),
              ),
              onTap: () => openItem(context, ref, c, siblings: channels),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l.removeFromList,
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.muted),
                    onPressed: () => controller.setIn(listId, c, false),
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.drag_handle, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      },
    );
  }
}
