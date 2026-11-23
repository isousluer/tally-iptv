import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'playback.dart';
import 'theme.dart';
import 'widgets.dart';

/// Shows movie details. Playback starts from the caller's context after the
/// sheet closes, because the sheet's own context is gone by then.
Future<void> showVodDetails(BuildContext context, WidgetRef ref, MediaItem movie) async {
  final resume = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _VodDetails(movie: movie),
  );
  if (resume == null || !context.mounted) return;
  await play(
    context,
    ref,
    PlayRequest(item: movie, url: movie.url!),
    resume: resume,
  );
}

final _resumeProvider = FutureProvider.autoDispose.family<(int, bool), MediaItem>((ref, item) async {
  final db = ref.watch(databaseProvider);
  final pos = await db.progressOf(item.playlistId, item.key);
  final fresh = await db.itemByKey(item.playlistId, item.key);
  return (pos, fresh?.favorite ?? item.favorite);
});

class _VodDetails extends ConsumerWidget {
  const _VodDetails({required this.movie});
  final MediaItem movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final state = ref.watch(_resumeProvider(movie)).value;
    final resumeMs = state?.$1 ?? 0;
    final favorite = state?.$2 ?? movie.favorite;
    final infoAsync = ref.watch(movieInfoProvider(movie));
    final info = infoAsync.value;
    final year = movie.year ?? info?.year;
    final rating = movie.rating ?? info?.rating;
    final meta = [
      year,
      if (rating != null) '★ $rating',
      if (info?.duration != null) formatDuration(info!.duration!),
    ].whereType<String>().join('  ·  ');
    final genre = info?.genre ?? movie.group;
    // The year is in the meta line, so don't repeat it in the title.
    final title = year == null ? movie.name : movie.name.replaceFirst(RegExp(r'\s*\(\d{4}\)\s*$'), '');
    final muted = t.bodySmall!.copyWith(color: SlayerColors.muted);

    Widget credit(String label, String value, {int lines = 2}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label  ', style: muted),
            TextSpan(text: value, style: t.bodySmall),
          ],
        ),
        maxLines: lines,
        overflow: TextOverflow.ellipsis,
      ),
    );

    void start({required bool resume}) {
      Navigator.pop(context, resume);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Poster(title: movie.name, url: movie.logo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.titleLarge, maxLines: 3, overflow: TextOverflow.ellipsis),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(meta, style: t.bodySmall!.copyWith(fontFeatures: tabular)),
                      ],
                      const SizedBox(height: 2),
                      Text(genre, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
                      if (info?.director != null) credit('Director', info!.director!, lines: 1),
                      if (info?.cast != null) credit('Cast', info!.cast!, lines: 3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: infoAsync.isLoading && info == null
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
                    : _Plot(text: info?.plot ?? movie.plot),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => start(resume: true),
              icon: const Icon(Icons.play_arrow),
              label: Text(resumeMs > 0 ? 'Resume from ${formatClock(Duration(milliseconds: resumeMs))}' : 'Play'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (resumeMs > 0) ...[
                  Expanded(
                    child: OutlinedButton(onPressed: () => start(resume: false), child: const Text('Start over')),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(favoritesControllerProvider).toggle(movie.copyWith(favorite: favorite));
                      ref.invalidate(_resumeProvider(movie));
                    },
                    icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? SlayerColors.tally : null),
                    label: Text(favorite ? 'In favorites' : 'Add to favorites'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Plot, director and cast of a movie or series.
class VodInfoText extends StatelessWidget {
  const VodInfoText({super.key, required this.info, this.fallbackPlot});
  final VodInfo? info;
  final String? fallbackPlot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final plot = info?.plot ?? fallbackPlot;
    Widget credit(String label, String value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: t.bodySmall!.copyWith(color: SlayerColors.muted),
            ),
            TextSpan(text: value, style: t.bodySmall),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plot ?? 'No description available.',
          style: t.bodyMedium!.copyWith(color: plot == null ? SlayerColors.muted : null),
        ),
        if (info?.director != null) credit('Director', info!.director!),
        if (info?.cast != null) credit('Cast', info!.cast!),
      ],
    );
  }
}

/// Plot text, collapsed to a few lines until tapped.
class _Plot extends StatefulWidget {
  const _Plot({required this.text});
  final String? text;

  @override
  State<_Plot> createState() => _PlotState();
}

class _PlotState extends State<_Plot> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (widget.text == null) {
      return Text('No description available.', style: t.bodyMedium!.copyWith(color: SlayerColors.muted));
    }
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Text(
          widget.text!,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? null : TextOverflow.ellipsis,
          style: t.bodyMedium,
        ),
      ),
    );
  }
}
