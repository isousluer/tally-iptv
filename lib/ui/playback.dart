import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../state/providers.dart';
import 'parental.dart';
import 'player_screen.dart';
import 'series_screen.dart';
import 'vod_details_sheet.dart';

/// Opens the right screen for [item]: player for live, details for movies,
/// season list for series. Items in a locked category ask for the PIN first.
Future<void> openItem(
  BuildContext context,
  WidgetRef ref,
  MediaItem item, {
  List<MediaItem> siblings = const [],
}) async {
  if (!await ensureUnlockedFor(context, ref, item)) return;
  if (!context.mounted) return;
  switch (item.kind) {
    case ContentKind.live:
      await play(context, ref, PlayRequest(item: item, url: item.url!, siblings: siblings));
    case ContentKind.movie:
      await showVodDetails(context, ref, item);
    case ContentKind.series:
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeriesScreen(series: item)));
  }
}

/// Starts playback, resuming VOD where the viewer left off.
Future<void> play(BuildContext context, WidgetRef ref, PlayRequest request, {bool resume = true}) async {
  var req = request;
  if (!request.isLive && resume) {
    final key = request.historyKey ?? request.item.key;
    final ms = await ref.read(databaseProvider).progressOf(request.item.playlistId, key);
    if (ms > 0) {
      req = request.copyWith(historyKey: key, startAt: Duration(milliseconds: ms));
    }
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(request: req)));
  if (context.mounted) ref.invalidate(historyProvider);
}
