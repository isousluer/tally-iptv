import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'continue_row.dart';
import 'playback.dart';
import 'playlist_switcher.dart';
import 'theme.dart';
import 'widgets.dart';

/// Poster grid for movies or series.
class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key, required this.kind});
  final ContentKind kind;

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen> {
  String _group = groupAll;
  String _search = '';
  bool _searching = false;

  bool get _movies => widget.kind == ContentKind.movie;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(countProvider(widget.kind)).value ?? 0;
    final groups = ref.watch(groupsProvider(widget.kind)).value ?? const [];
    final query = (kind: widget.kind, group: _group, search: _search);
    final items = ref.watch(itemsProvider(query));
    final noun = _movies ? 'movies' : 'series';
    final width = MediaQuery.sizeOf(context).width;
    final columns = (width / 150).floor().clamp(3, 9);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _searching
                ? SearchBarField(
                    hint: 'Search $noun',
                    onChanged: (v) => setState(() => _search = v),
                    onClose: () => setState(() {
                      _searching = false;
                      _search = '';
                    }),
                  )
                : ScreenHeader(
                    title: _movies ? 'Movies' : 'Series',
                    subtitle: '${compactCount(count)} $noun',
                    actions: [
                      IconButton(
                        tooltip: 'Search $noun',
                        onPressed: () => setState(() => _searching = true),
                        icon: const Icon(Icons.search),
                      ),
                      const PlaylistSwitcherButton(),
                    ],
                  ),
          ),
          SliverToBoxAdapter(
            child: CategoryStrip(
              entries: [
                (groupAll, 'All'),
                (groupFavorites, 'Favorites'),
                for (final g in groups) (g, g),
              ],
              selected: _group,
              onSelected: (g) => setState(() => _group = g),
            ),
          ),
          if (_group == groupAll && _search.isEmpty)
            SliverToBoxAdapter(child: ContinueRow(kind: widget.kind)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ...items.when(
            loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
            error: (e, _) => [SliverFillRemaining(child: ErrorState(error: e))],
            data: (list) {
              if (list.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: _movies ? Icons.movie_outlined : Icons.video_library_outlined,
                      title: _search.isNotEmpty
                          ? 'Nothing matches "$_search"'
                          : _group == groupFavorites
                              ? 'No favorite $noun yet'
                              : 'No $noun in this playlist',
                      message: count == 0 && _search.isEmpty && _group == groupAll
                          ? 'Your playlist doesn\'t include $noun. Xtream Codes accounts usually do.'
                          : null,
                    ),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.52,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => PosterTile(
                      item: list[i],
                      onTap: () => openItem(context, ref, list[i]),
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class PosterTile extends StatelessWidget {
  const PosterTile({super.key, required this.item, required this.onTap});
  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final meta = [if (item.year != null) item.year!, if (item.rating != null) '★ ${item.rating}'].join('  ');
    // The year is shown below, so drop a trailing "(2024)" from the title.
    final title = item.year == null ? item.name : item.name.replaceFirst(RegExp(r'\s*\(\d{4}\)\s*$'), '');
    // Fixed-height text block (scaled with the user's font size); the poster
    // takes whatever space is left, so long titles can never overflow.
    final textHeight = MediaQuery.textScalerOf(context).scale(56);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Poster(title: title, url: item.logo, aspectRatio: null),
                if (item.favorite)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.star, size: 18, color: SlayerColors.tally),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: textHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.labelMedium!.copyWith(height: 1.25)),
                if (meta.isNotEmpty)
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: t.labelSmall!.copyWith(color: SlayerColors.muted, fontFeatures: tabular)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
