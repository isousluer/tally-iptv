import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'live_screen.dart';
import 'playback.dart';
import 'theme.dart';
import 'vod_screen.dart';
import 'widgets.dart';

/// Header button that opens [SearchScreen].
class SearchButton extends StatelessWidget {
  const SearchButton({super.key, this.first = ContentKind.live});
  final ContentKind first;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.search,
    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(first: first))),
    icon: const Icon(Icons.search),
  );
}

/// One search box for channels, movies and series.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.first = ContentKind.live});

  /// Section shown first, usually the tab the search was opened from.
  final ContentKind first;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _text = '';
  Timer? _debounce;

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => setState(() => _text = v.trim()));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final results = ref.watch(searchProvider(_text));
    final order = [widget.first, ...ContentKind.values.where((k) => k != widget.first)];
    final guide = ref.watch(nowPlayingProvider).value ?? const {};
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final columns = (MediaQuery.sizeOf(context).width / 130).floor().clamp(3, 9);

    Widget heading(String text, int n) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text('$text  ·  $n', style: t.titleMedium),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  const BackButton(),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l.searchHint,
                        prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _text.length < 2
                  ? EmptyState(icon: Icons.manage_search, title: l.searchEverything, message: l.searchMinLetters)
                  : results.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorState(error: e),
                      data: (map) {
                        if (map.values.every((l) => l.isEmpty)) {
                          return EmptyState(icon: Icons.search_off, title: l.nothingMatches(_text));
                        }
                        return CustomScrollView(
                          slivers: [
                            for (final kind in order)
                              if ((map[kind] ?? const []).isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: heading(switch (kind) {
                                    ContentKind.live => l.channels,
                                    ContentKind.movie => l.movies,
                                    ContentKind.series => l.series,
                                  }, map[kind]!.length),
                                ),
                                if (kind == ContentKind.live)
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverList.builder(
                                      itemCount: map[kind]!.length,
                                      itemBuilder: (context, i) {
                                        final c = map[kind]![i];
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: SizedBox(
                                            height: 74,
                                            child: ChannelRow(
                                              channel: c,
                                              program: c.tvgId == null ? null : guide[c.tvgId!.toLowerCase()],
                                              now: now,
                                              onTap: () => openItem(context, ref, c, siblings: map[kind]!),
                                              onFavorite: () async {
                                                await ref.read(favoritesControllerProvider).toggle(c);
                                                ref.invalidate(searchProvider(_text));
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverGrid.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: 0.52,
                                      ),
                                      itemCount: map[kind]!.length,
                                      itemBuilder: (context, i) => PosterTile(
                                        item: map[kind]![i],
                                        onTap: () => openItem(context, ref, map[kind]![i]),
                                      ),
                                    ),
                                  ),
                              ],
                            const SliverToBoxAdapter(child: SizedBox(height: 32)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
