import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'vod_details_sheet.dart' show VodInfoText;
import 'widgets.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.request});
  final PlayRequest request;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player = Player(
    configuration: const PlayerConfiguration(title: 'Slayer IPTV', bufferSize: 64 * 1024 * 1024),
  );
  late final VideoController _video = VideoController(_player);
  // Read once: ref must not be used in dispose(), where progress is saved.
  late final AppDatabase _db = ref.read(databaseProvider);
  late MediaItem _item = widget.request.item;
  late String _url = widget.request.url;

  bool _fullscreen = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _saveTimer;
  String? _error;
  bool _hasVideo = false;
  final _subs = <StreamSubscription<Object?>>[];

  bool get _isLive => _item.kind == ContentKind.live;
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _db; // initialize while ref is valid
    // mpv reports warnings (e.g. "cannot seek in this stream" on live TV)
    // through the same error stream. Only treat a message as a failure when
    // no picture has arrived yet.
    _subs.add(_player.stream.error.listen((e) {
      if (!mounted || _hasVideo || e.toLowerCase().contains('seek')) return;
      setState(() => _error = e);
    }));
    _subs.add(_player.stream.width.listen((w) {
      if (w != null && w > 0) {
        _hasVideo = true;
        if (mounted && _error != null) setState(() => _error = null);
      }
    }));
    _open(_url, start: widget.request.startAt);
    if (!_isLive) {
      _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
    }
    _bumpControls();
  }

  Future<void> _open(String url, {Duration start = Duration.zero}) async {
    _hasVideo = false;
    setState(() => _error = null);
    await _player.open(Media(url, start: start > Duration.zero ? start : null));
    if (_isLive) unawaited(_recordLive());
  }

  Future<void> _recordLive() => _db.saveProgress(
        playlistId: _item.playlistId,
        historyKey: _item.key,
        itemKey: _item.key,
        positionMs: 0,
        durationMs: 0,
      );

  Future<void> _saveProgress() async {
    if (_isLive) return;
    final pos = _player.state.position;
    final dur = _player.state.duration;
    if (dur <= Duration.zero || pos < const Duration(seconds: 5)) return;
    // Finished items restart from the beginning next time.
    final done = dur - pos < const Duration(minutes: 2);
    await _db.saveProgress(
          playlistId: _item.playlistId,
          historyKey: widget.request.historyKey ?? _item.key,
          itemKey: _item.key,
          title: widget.request.title,
          url: _url,
          positionMs: done ? 0 : pos.inMilliseconds,
          durationMs: dur.inMilliseconds,
        );
  }

  void _zap(int delta) {
    final list = widget.request.siblings;
    if (list.length < 2) return;
    final i = list.indexWhere((c) => c.key == _item.key);
    final next = list[((i < 0 ? 0 : i) + delta) % list.length];
    setState(() {
      _item = next;
      _url = next.url!;
    });
    _open(_url);
    _bumpControls();
  }

  void _bumpControls() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _player.state.playing) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _setFullscreen(bool value) async {
    setState(() => _fullscreen = value);
    if (_isMobile) {
      if (value) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _saveProgress();
    if (_fullscreen && _isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _player.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.mediaPlayPause) {
      _player.playOrPause();
    } else if (k == LogicalKeyboardKey.keyF) {
      _setFullscreen(!_fullscreen);
    } else if (k == LogicalKeyboardKey.escape && _fullscreen) {
      _setFullscreen(false);
    } else if (_isLive && (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.channelUp)) {
      _zap(-1);
    } else if (_isLive && (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.channelDown)) {
      _zap(1);
    } else if (!_isLive && k == LogicalKeyboardKey.arrowRight) {
      _player.seek(_player.state.position + const Duration(seconds: 10));
    } else if (!_isLive && k == LogicalKeyboardKey.arrowLeft) {
      _player.seek(_player.state.position - const Duration(seconds: 10));
    } else {
      return KeyEventResult.ignored;
    }
    _bumpControls();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final wide = isWide(context);
    final videoOnly = _fullscreen || (_isMobile && orientation == Orientation.landscape);

    final surface = _VideoSurface(
      video: _video,
      player: _player,
      title: widget.request.title ?? _item.name,
      subtitle: widget.request.subtitle,
      isLive: _isLive,
      error: _error,
      controlsVisible: _controlsVisible,
      fullscreen: videoOnly,
      onTap: () => _controlsVisible ? setState(() => _controlsVisible = false) : _bumpControls(),
      onInteract: _bumpControls,
      onBack: () => videoOnly && _fullscreen ? _setFullscreen(false) : Navigator.of(context).pop(),
      onFullscreen: () => _setFullscreen(!_fullscreen),
      onRetry: () => _open(_url, start: _player.state.position),
    );

    Widget body;
    if (videoOnly) {
      body = surface;
    } else if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Container(color: Colors.black, child: Center(child: surface))),
          SizedBox(width: 380, child: _InfoPanel(item: _item, request: widget.request, onZap: _zap)),
        ],
      );
    } else {
      body = Column(
        children: [
          ColoredBox(color: Colors.black, child: SafeArea(bottom: false, child: surface)),
          Expanded(child: _InfoPanel(item: _item, request: widget.request, onZap: _zap)),
        ],
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: videoOnly ? Colors.black : SlayerColors.canvas,
        body: body,
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.video,
    required this.player,
    required this.title,
    required this.subtitle,
    required this.isLive,
    required this.error,
    required this.controlsVisible,
    required this.fullscreen,
    required this.onTap,
    required this.onInteract,
    required this.onBack,
    required this.onFullscreen,
    required this.onRetry,
  });

  final VideoController video;
  final Player player;
  final String title;
  final String? subtitle;
  final bool isLive;
  final String? error;
  final bool controlsVisible;
  final bool fullscreen;
  final VoidCallback onTap;
  final VoidCallback onInteract;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        Video(controller: video, controls: NoVideoControls, fill: Colors.black),
        StreamBuilder<bool>(
          stream: player.stream.buffering,
          builder: (_, s) => (s.data ?? false) && error == null
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
              : const SizedBox.shrink(),
        ),
        if (error != null)
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.portable_wifi_off, color: SlayerColors.muted, size: 34),
                const SizedBox(height: 10),
                Text('This stream could not be played', style: t.titleMedium),
                const SizedBox(height: 4),
                Text(error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: t.bodySmall!.copyWith(color: SlayerColors.muted)),
                const SizedBox(height: 14),
                OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          onDoubleTap: onFullscreen,
          child: MouseRegion(onHover: (_) => onInteract()),
        ),
        IgnorePointer(
          ignoring: !controlsVisible,
          child: AnimatedOpacity(
            opacity: controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: _Controls(
              player: player,
              title: title,
              subtitle: subtitle,
              isLive: isLive,
              fullscreen: fullscreen,
              onBack: onBack,
              onFullscreen: onFullscreen,
              onInteract: onInteract,
            ),
          ),
        ),
      ],
    );
    return fullscreen ? stack : AspectRatio(aspectRatio: 16 / 9, child: stack);
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.player,
    required this.title,
    required this.subtitle,
    required this.isLive,
    required this.fullscreen,
    required this.onBack,
    required this.onFullscreen,
    required this.onInteract,
  });

  final Player player;
  final String title;
  final String? subtitle;
  final bool isLive;
  final bool fullscreen;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0x66000000)),
      child: SafeArea(
        top: fullscreen,
        bottom: fullscreen,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                if (isLive) const Padding(padding: EdgeInsets.only(right: 8), child: LiveBadge()),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium!.copyWith(color: Colors.white)),
                ),
                _TracksButton(player: player, onInteract: onInteract),
              ],
            ),
            Expanded(
              child: Center(
                child: StreamBuilder<bool>(
                  stream: player.stream.playing,
                  initialData: player.state.playing,
                  builder: (_, s) {
                    final playing = s.data ?? false;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isLive)
                          _RoundButton(
                            icon: Icons.replay_10,
                            tooltip: 'Back 10 seconds',
                            onPressed: () {
                              player.seek(player.state.position - const Duration(seconds: 10));
                              onInteract();
                            },
                          ),
                        const SizedBox(width: 20),
                        _RoundButton(
                          icon: playing ? Icons.pause : Icons.play_arrow,
                          tooltip: playing ? 'Pause' : 'Play',
                          big: true,
                          onPressed: () {
                            player.playOrPause();
                            onInteract();
                          },
                        ),
                        const SizedBox(width: 20),
                        if (!isLive)
                          _RoundButton(
                            icon: Icons.forward_10,
                            tooltip: 'Forward 10 seconds',
                            onPressed: () {
                              player.seek(player.state.position + const Duration(seconds: 10));
                              onInteract();
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: isLive
                        ? Text(subtitle ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall!.copyWith(color: Colors.white70))
                        : _SeekBar(player: player, onInteract: onInteract),
                  ),
                  IconButton(
                    tooltip: fullscreen ? 'Exit full screen' : 'Full screen',
                    onPressed: onFullscreen,
                    icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed, this.big = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: big ? 40 : 28,
      style: IconButton.styleFrom(
        backgroundColor: big ? SlayerColors.tally : const Color(0x33000000),
        foregroundColor: big ? SlayerColors.onTally : Colors.white,
        padding: EdgeInsets.all(big ? 12 : 8),
      ),
      icon: Icon(icon),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player, required this.onInteract});
  final Player player;
  final VoidCallback onInteract;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white, fontFeatures: tabular);
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: widget.player.state.position,
      builder: (_, snap) {
        final dur = widget.player.state.duration;
        final pos = snap.data ?? Duration.zero;
        final max = dur.inMilliseconds.toDouble().clamp(1.0, double.infinity);
        final value = (_drag ?? pos.inMilliseconds.toDouble()).clamp(0.0, max);
        return Row(
          children: [
            Text(_fmt(Duration(milliseconds: value.round())), style: style),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: SlayerColors.tally,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: SlayerColors.tally,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Slider(
                    value: value,
                    max: max,
                    onChanged: (v) {
                      setState(() => _drag = v);
                      widget.onInteract();
                    },
                    onChangeEnd: (v) {
                      widget.player.seek(Duration(milliseconds: v.round()));
                      setState(() => _drag = null);
                    },
                  ),
                ),
              ),
            ),
            Text(_fmt(dur), style: style),
          ],
        );
      },
    );
  }
}

/// Audio and subtitle track picker.
class _TracksButton extends StatelessWidget {
  const _TracksButton({required this.player, required this.onInteract});
  final Player player;
  final VoidCallback onInteract;

  String _label(dynamic t, int i) {
    final title = t.title as String?;
    final lang = t.language as String?;
    final parts = [if (title != null && title.isNotEmpty) title, if (lang != null && lang.isNotEmpty) lang];
    return parts.isEmpty ? 'Track ${i + 1}' : parts.join(' – ');
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Audio and subtitles',
      icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
      onPressed: () {
        onInteract();
        final tracks = player.state.tracks;
        final audio = tracks.audio.where((a) => a.id != 'auto' && a.id != 'no').toList();
        final subs = tracks.subtitle.where((s) => s.id != 'auto').toList();
        showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                _section(ctx, 'Audio'),
                if (audio.isEmpty) const ListTile(title: Text('Default')),
                for (final (i, a) in audio.indexed)
                  ListTile(
                    title: Text(_label(a, i)),
                    trailing: player.state.track.audio.id == a.id
                        ? const Icon(Icons.check, color: SlayerColors.tally)
                        : null,
                    onTap: () {
                      player.setAudioTrack(a);
                      Navigator.pop(ctx);
                    },
                  ),
                _section(ctx, 'Subtitles'),
                for (final (i, s) in subs.indexed)
                  ListTile(
                    title: Text(s.id == 'no' ? 'Off' : _label(s, i)),
                    trailing: player.state.track.subtitle.id == s.id
                        ? const Icon(Icons.check, color: SlayerColors.tally)
                        : null,
                    onTap: () {
                      player.setSubtitleTrack(s);
                      Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: SlayerColors.muted)),
      );
}

/// Channel details, now/next guide and zapping for live; title info for VOD.
class _InfoPanel extends ConsumerWidget {
  const _InfoPanel({required this.item, required this.request, required this.onZap});
  final MediaItem item;
  final PlayRequest request;
  final ValueChanged<int> onZap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final isLive = item.kind == ContentKind.live;
    final canZap = isLive && request.siblings.length > 1;
    final favorite = ref.watch(_favoriteProvider(item)).value ?? item.favorite;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            if (isLive) ...[ChannelLogo(name: item.name, url: item.logo, size: 52), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.title ?? item.name, style: t.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    request.subtitle ?? item.group,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall!.copyWith(color: SlayerColors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
              onPressed: () async {
                await ref.read(favoritesControllerProvider).toggle(item.copyWith(favorite: favorite));
                ref.invalidate(_favoriteProvider(item));
              },
              icon: Icon(favorite ? Icons.star : Icons.star_border,
                  color: favorite ? SlayerColors.tally : SlayerColors.muted),
            ),
          ],
        ),
        if (canZap) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onZap(-1),
                  icon: const Icon(Icons.keyboard_arrow_up),
                  label: const Text('Previous channel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onZap(1),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  label: const Text('Next channel'),
                ),
              ),
            ],
          ),
        ],
        if (isLive) ...[
          const SizedBox(height: 20),
          _Guide(item: item),
        ] else ...[
          const SizedBox(height: 16),
          if (request.description != null || item.kind != ContentKind.movie)
            VodInfoText(info: null, fallbackPlot: request.description ?? item.plot)
          else
            ref.watch(movieInfoProvider(item)).when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => VodInfoText(info: null, fallbackPlot: item.plot),
                  data: (info) => VodInfoText(info: info, fallbackPlot: item.plot),
                ),
        ],
      ],
    );
  }
}

final _favoriteProvider = FutureProvider.autoDispose.family<bool, MediaItem>((ref, item) async {
  final fresh = await ref.watch(databaseProvider).itemByKey(item.playlistId, item.key);
  return fresh?.favorite ?? item.favorite;
});

class _Guide extends ConsumerWidget {
  const _Guide({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final schedule = ref.watch(scheduleProvider(item));
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return schedule.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('$e'),
      data: (list) {
        if (list.isEmpty) {
          return Text('No guide data for this channel.', style: t.bodySmall!.copyWith(color: SlayerColors.muted));
        }
        final current = list.first.isLiveAt(now) ? list.first : null;
        final upcoming = current == null ? list : list.skip(1).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null)
              Container(
                decoration: BoxDecoration(
                  color: SlayerColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: SlayerColors.tally, width: 3)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Now', style: t.labelMedium!.copyWith(color: SlayerColors.tally)),
                        const SizedBox(width: 8),
                        Text('${formatTime(current.start)} – ${formatTime(current.stop)}',
                            style: t.labelMedium!.copyWith(color: SlayerColors.muted, fontFeatures: tabular)),
                        const Spacer(),
                        Text('${formatDuration(current.stop.difference(now))} left',
                            style: t.labelMedium!.copyWith(color: SlayerColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(current.title, style: t.titleLarge),
                    if (current.description != null) ...[
                      const SizedBox(height: 4),
                      Text(current.description!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium!.copyWith(color: SlayerColors.muted)),
                    ],
                    const SizedBox(height: 12),
                    TallyBar(value: current.progressAt(now), height: 4),
                  ],
                ),
              ),
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Up next', style: t.titleMedium),
              const SizedBox(height: 6),
              for (final p in upcoming.take(12))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 56,
                        child: Text(formatTime(p.start),
                            style: t.titleSmall!.copyWith(color: SlayerColors.tally, fontFeatures: tabular)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: t.titleSmall),
                            if (p.description != null)
                              Text(p.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall!.copyWith(color: SlayerColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
