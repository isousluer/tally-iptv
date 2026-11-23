import 'package:material_ui/material_ui.dart';

import '../data/repository.dart';
import 'theme.dart';
import 'widgets.dart';

/// Step-by-step progress while a playlist is added or updated.
class LoadingPlaylistView extends StatelessWidget {
  const LoadingPlaylistView({super.key, required this.name, required this.progress});
  final String name;
  final LoadProgress? progress;

  static String label(LoadStage s, {required bool m3u}) => switch (s) {
        LoadStage.connect => m3u ? 'Downloading playlist' : 'Connecting to server',
        LoadStage.live => 'Live TV',
        LoadStage.movies => 'Movies',
        LoadStage.series => 'Series',
        LoadStage.save => 'Saving to this device',
      };

  static String? countLabel(LoadStage s, int? n) {
    if (n == null) return null;
    final c = compactCount(n);
    return switch (s) {
      LoadStage.live => n == 1 ? '1 channel' : '$c channels',
      LoadStage.movies => n == 1 ? '1 movie' : '$c movies',
      LoadStage.series => '$c series',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
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
                  Text(name.isEmpty ? 'Loading your playlist' : 'Loading $name', style: t.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Large playlists can take a minute. Keep the app open.',
                    style: t.bodyMedium!.copyWith(color: SlayerColors.muted),
                  ),
                  const SizedBox(height: 28),
                  for (final s in stages)
                    _StageRow(
                      label: label(s, m3u: m3u),
                      count: countLabel(s, p?.counts[s]),
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
      _State.done => const Icon(Icons.check_circle, color: SlayerColors.tally, size: 22),
      _State.active => const SizedBox(
          width: 22,
          height: 22,
          child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2.4)),
        ),
      _State.waiting => const Icon(Icons.radio_button_unchecked, color: SlayerColors.border, size: 22),
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
              style: t.titleSmall!.copyWith(
                color: state == _State.waiting ? SlayerColors.muted : SlayerColors.text,
              ),
            ),
          ),
          if (count != null)
            Text(count!, style: t.bodySmall!.copyWith(color: SlayerColors.muted, fontFeatures: tabular)),
        ],
      ),
    );
  }
}
