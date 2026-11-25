import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'playback.dart';
import 'theme.dart';
import 'widgets.dart';

/// Plays episode [e] of [series]; the episodes after it in [all] (across
/// seasons) follow automatically.
PlayRequest episodeRequest(MediaItem series, Episode e, List<Episode> all) {
  PlayRequest request(Episode e, [List<PlayRequest> upNext = const []]) => PlayRequest(
    item: series,
    url: e.url,
    title: '${strings.episodeCode(e.season, e.number)}  ${e.title}',
    subtitle: series.name,
    historyKey: e.key,
    description: e.plot ?? series.plot,
    upNext: upNext,
  );
  final i = all.indexWhere((x) => x.key == e.key);
  final rest = i < 0 ? const <Episode>[] : all.skip(i + 1);
  return request(e, [for (final n in rest) request(n)]);
}

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key, required this.series});
  final MediaItem series;

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  int? _season;
  bool _plotExpanded = false;
  late bool _favorite = widget.series.favorite;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  MediaItem get s => widget.series;

  void _playEpisode(Episode e, List<Episode> all, {bool resume = true}) =>
      play(context, ref, episodeRequest(s, e, all), resume: resume);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final details = ref.watch(seriesDetailsProvider(s));
    final history = ref.watch(historyProvider).value ?? const [];
    final progress = <String, WatchEntry>{
      for (final (e, _) in history)
        if (e.item.key == s.key) e.historyKey: e,
    };
    // Most recently watched episode of this series, if any.
    final lastWatched = history.where((h) => h.$1.item.key == s.key).firstOrNull?.$1;

    return Scaffold(
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(seriesDetailsProvider(s))),
        data: (d) {
          final seasons = d.seasons.keys.toList();
          final season = _season ?? (seasons.isEmpty ? null : seasons.first);
          final episodes = season == null ? const <Episode>[] : d.seasons[season]!;
          final allEpisodes = d.seasons.values.expand((e) => e).toList();
          final resumeEp = lastWatched == null
              ? null
              : allEpisodes.where((e) => e.key == lastWatched.historyKey).firstOrNull;
          final plot = d.plot ?? s.plot;
          final meta = [
            s.year,
            context.l10n.seasonCount(seasons.length),
            if (s.rating != null) '★ ${s.rating}',
          ].whereType<String>().join('  ·  ');

          final poster = s.logo ?? d.cover;
          final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
          // On tablets the page keeps a readable width; the backdrop still
          // spans the screen.
          final inset = readableInset(MediaQuery.sizeOf(context).width, 880);
          final big = !isPhone(context);

          final list = CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    if (poster != null) Positioned.fill(child: _BlurredBackdrop(url: poster)),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 + inset, top + 4, 16 + inset, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: big ? 150 : 104,
                            child: Poster(title: s.name, url: poster),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: t.titleLarge),
                                const SizedBox(height: 4),
                                Text(meta, style: t.bodySmall!.copyWith(color: AppColors.muted)),
                                if (plot != null) ...[
                                  const SizedBox(height: 10),
                                  // Tap to read the whole plot.
                                  GestureDetector(
                                    onTap: () => setState(() => _plotExpanded = !_plotExpanded),
                                    child: Text(
                                      plot,
                                      maxLines: _plotExpanded ? null : 4,
                                      overflow: _plotExpanded ? null : TextOverflow.ellipsis,
                                      style: t.bodySmall!.copyWith(color: AppColors.muted, height: 1.4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16 + inset, 0, 16 + inset, 0),
                sliver: SliverList.list(
                  children: [
                    if (allEpisodes.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _playEpisode(resumeEp ?? allEpisodes.first, allEpisodes),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          resumeEp == null
                              ? context.l10n.playEpisode(
                                  context.l10n.episodeCode(allEpisodes.first.season, allEpisodes.first.number),
                                )
                              : context.l10n.continueEpisode(
                                  context.l10n.episodeCode(resumeEp.season, resumeEp.number),
                                ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (seasons.length > 1)
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: seasons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final active = seasons[i] == season;
                            return Center(
                              child: ChoiceChip(
                                label: Text(context.l10n.seasonNumber(seasons[i])),
                                selected: active,
                                onSelected: (_) => setState(() => _season = seasons[i]),
                                labelStyle: t.labelMedium!.copyWith(color: active ? AppColors.onTally : AppColors.text),
                              ),
                            );
                          },
                        ),
                      )
                    else if (season != null)
                      Text(context.l10n.seasonNumber(season), style: t.titleLarge),
                    const SizedBox(height: 8),
                    if (allEpisodes.isEmpty)
                      EmptyState(icon: Icons.video_library_outlined, title: context.l10n.noEpisodes),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16 + inset, 4, 16 + inset, 32 + MediaQuery.paddingOf(context).bottom),
                sliver: SliverList.separated(
                  itemCount: episodes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _EpisodeRow(
                    episode: episodes[i],
                    progress: progress[episodes[i].key],
                    onTap: () => _playEpisode(episodes[i], allEpisodes),
                  ),
                ),
              ),
            ],
          );

          return Stack(
            children: [
              list,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ListenableBuilder(
                  listenable: _scroll,
                  builder: (context, _) {
                    // The bar turns solid once the header scrolls under it.
                    final solid = _scroll.hasClients && _scroll.offset > 24;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      color: solid ? AppColors.canvas : AppColors.canvas.withAlpha(0),
                      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                      child: SizedBox(
                        height: kToolbarHeight,
                        child: Row(
                          children: [
                            const BackButton(),
                            Expanded(
                              child: AnimatedOpacity(
                                opacity: solid ? 1 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium),
                              ),
                            ),
                            IconButton(
                              tooltip: _favorite ? context.l10n.removeFromFavorites : context.l10n.addToFavorites,
                              onPressed: () async {
                                await ref.read(favoritesControllerProvider).toggle(s.copyWith(favorite: _favorite));
                                setState(() => _favorite = !_favorite);
                              },
                              icon: Icon(
                                _favorite ? Icons.star : Icons.star_border,
                                color: _favorite ? AppColors.tally : null,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The poster, heavily blurred and darkened, fading into the page: a soft
/// colour wash behind the header that works with portrait-only artwork.
class _BlurredBackdrop extends StatelessWidget {
  const _BlurredBackdrop({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.clamp),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 160,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x990F1E22), Color(0xCC0F1E22), AppColors.canvas],
                stops: [0, 0.6, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.progress, required this.onTap});
  final Episode episode;
  final WatchEntry? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final started = progress != null && progress!.positionMs > 0;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    EpisodeThumb(number: episode.number, url: episode.image),
                    if (started)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 5),
                        child: TallyBar(value: progress!.progress, height: 3),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${episode.number}. ${episode.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleSmall!.copyWith(color: started ? AppColors.tally : null),
                          ),
                        ),
                        if (episode.duration != null)
                          Text(
                            formatEpisodeLength(episode.duration!),
                            style: t.labelSmall!.copyWith(color: AppColors.muted, fontFeatures: tabular),
                          ),
                      ],
                    ),
                    if (episode.plot != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.plot!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall!.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
