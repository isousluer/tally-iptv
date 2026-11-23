import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'playback.dart';
import 'theme.dart';
import 'widgets.dart';

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

  MediaItem get s => widget.series;

  PlayRequest _request(Episode e, {List<PlayRequest> upNext = const []}) => PlayRequest(
    item: s,
    url: e.url,
    title: 'S${e.season} · E${e.number}  ${e.title}',
    subtitle: s.name,
    historyKey: e.key,
    description: e.plot ?? s.plot,
    upNext: upNext,
  );

  /// Plays [e]; the episodes after it (across seasons) follow automatically.
  void _playEpisode(Episode e, List<Episode> all, {bool resume = true}) {
    final i = all.indexWhere((x) => x.key == e.key);
    final rest = i < 0 ? const <Episode>[] : all.skip(i + 1);
    play(context, ref, _request(e, upNext: [for (final n in rest) _request(n)]), resume: resume);
  }

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
            '${seasons.length} season${seasons.length == 1 ? '' : 's'}',
            if (s.rating != null) '★ ${s.rating}',
          ].whereType<String>().join('  ·  ');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                backgroundColor: SlayerColors.canvas,
                actions: [
                  IconButton(
                    tooltip: _favorite ? 'Remove from favorites' : 'Add to favorites',
                    onPressed: () async {
                      await ref.read(favoritesControllerProvider).toggle(s.copyWith(favorite: _favorite));
                      setState(() => _favorite = !_favorite);
                    },
                    icon: Icon(
                      _favorite ? Icons.star : Icons.star_border,
                      color: _favorite ? SlayerColors.tally : null,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if ((d.cover ?? s.logo) != null)
                        CachedNetworkImage(
                          imageUrl: (d.cover ?? s.logo)!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      const ColoredBox(color: Color(0xB30F1E22)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Poster(title: s.name, url: s.logo),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: t.headlineMedium),
                              const SizedBox(height: 4),
                              Text(meta, style: t.bodySmall!.copyWith(color: SlayerColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (plot != null) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => setState(() => _plotExpanded = !_plotExpanded),
                        child: Text(
                          plot,
                          maxLines: _plotExpanded ? null : 3,
                          overflow: _plotExpanded ? null : TextOverflow.ellipsis,
                          style: t.bodyMedium!.copyWith(color: SlayerColors.muted),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (allEpisodes.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _playEpisode(resumeEp ?? allEpisodes.first, allEpisodes),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          resumeEp == null
                              ? 'Play S${allEpisodes.first.season} · E${allEpisodes.first.number}'
                              : 'Continue S${resumeEp.season} · E${resumeEp.number}',
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
                                label: Text('Season ${seasons[i]}'),
                                selected: active,
                                onSelected: (_) => setState(() => _season = seasons[i]),
                                labelStyle: t.labelMedium!.copyWith(
                                  color: active ? SlayerColors.onTally : SlayerColors.text,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else if (season != null)
                      Text('Season $season', style: t.titleLarge),
                    const SizedBox(height: 8),
                    if (allEpisodes.isEmpty)
                      const EmptyState(icon: Icons.video_library_outlined, title: 'No episodes available'),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList.separated(
                  itemCount: episodes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _EpisodeRow(
                    episode: episodes[i],
                    progress: progress[episodes[i].key],
                    fallbackImage: s.logo,
                    onTap: () => _playEpisode(episodes[i], allEpisodes),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.progress, required this.fallbackImage, required this.onTap});
  final Episode episode;
  final WatchEntry? progress;
  final String? fallbackImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final started = progress != null && progress!.positionMs > 0;
    return Material(
      color: SlayerColors.surface,
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
                    Poster(title: episode.title, url: episode.image ?? fallbackImage, aspectRatio: 16 / 9),
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
                            style: t.titleSmall!.copyWith(color: started ? SlayerColors.tally : null),
                          ),
                        ),
                        if (episode.duration != null)
                          Text(
                            episode.duration!,
                            style: t.labelSmall!.copyWith(color: SlayerColors.muted, fontFeatures: tabular),
                          ),
                      ],
                    ),
                    if (episode.plot != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.plot!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall!.copyWith(color: SlayerColors.muted),
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
