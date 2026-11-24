import 'package:material_ui/material_ui.dart';

import '../data/repository.dart';
import '../l10n/strings.dart';
import 'theme.dart';

/// Step-by-step progress while a playlist is added or updated.
class LoadingPlaylistView extends StatelessWidget {
  const LoadingPlaylistView({super.key, required this.name, required this.progress});
  final String name;
  final LoadProgress? progress;

  static String label(AppLocalizations l, LoadStage s, {required bool m3u}) => switch (s) {
    LoadStage.connect => m3u ? l.stageDownloadPlaylist : l.stageConnect,
    LoadStage.live => l.liveTv,
    LoadStage.movies => l.movies,
    LoadStage.series => l.series,
    LoadStage.save => l.stageSave,
  };

  static String? countLabel(AppLocalizations l, LoadStage s, int? n) {
    if (n == null) return null;
    return switch (s) {
      LoadStage.live => l.channelCount(n),
      LoadStage.movies => l.movieCount(n),
      LoadStage.series => l.seriesCount(n),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final p = progress;
    final m3u = p != null && !p.stages.contains(LoadStage.series);
    final stages = p?.stages ?? const [LoadStage.connect];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? l.loadingYourPlaylist : l.loadingPlaylist(name), style: t.headlineMedium),
                  const SizedBox(height: 6),
                  Text(l.keepAppOpen, style: t.bodyMedium!.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 28),
                  for (final s in stages)
                    _StageRow(
                      label: label(l, s, m3u: m3u),
                      count: countLabel(l, s, p?.counts[s]),
                      state: p == null
                          ? _State.active
                          : p.current == s
                          ? _State.active
                          : p.isDone(s)
                          ? _State.done
                          : _State.waiting,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _State { waiting, active, done }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.label, required this.state, this.count});
  final String label;
  final String? count;
  final _State state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final icon = switch (state) {
      _State.done => const Icon(Icons.check_circle, color: AppColors.tally, size: 22),
      _State.active => const SizedBox(
        width: 22,
        height: 22,
        child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
      _State.waiting => const Icon(Icons.radio_button_unchecked, color: AppColors.border, size: 22),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: t.titleSmall!.copyWith(color: state == _State.waiting ? AppColors.muted : AppColors.text),
            ),
          ),
          if (count != null)
            Text(
              count!,
              style: t.bodySmall!.copyWith(color: AppColors.muted, fontFeatures: tabular),
            ),
        ],
      ),
    );
  }
}
