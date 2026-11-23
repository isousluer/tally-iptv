import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../platform/device.dart';
import '../state/providers.dart';
import 'theme.dart';
import 'series_screen.dart' show episodeRequest;
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
    configuration: const PlayerConfiguration(title: 'Tally', bufferSize: 64 * 1024 * 1024),
  );
  late final VideoController _video = VideoController(_player);
  // Read once: ref must not be used in dispose(), where progress is saved.
  late final AppDatabase _db = ref.read(databaseProvider);
  late final SettingsNotifier _settings = ref.read(settingsProvider.notifier);

  /// What is playing now; changes when the next episode starts.
  late PlayRequest _req = widget.request;
  late MediaItem _item = widget.request.item;
  late String _url = widget.request.url;

  bool _fullscreen = Device.isTv;
  bool _controlsVisible = true;
  bool _pip = Device.inPip;
  bool _pipSupported = false;
  Timer? _hideTimer;
  Timer? _saveTimer;
  String? _error;
  bool _hasVideo = false;
  bool _tracksApplied = false;
  double _rate = 1;

  Timer? _sleepTimer;
  DateTime? _sleepAt;

  /// Live TV: waits for the viewer to stop on a channel before loading it.
  Timer? _zapTimer;
  final _keys = FocusNode(debugLabel: 'player keys');

  /// Live TV: the channel card shown for a few seconds after a change.
  bool _banner = false;
  Timer? _bannerTimer;

  /// Live TV: channel number being typed on a remote or keyboard.
  String _digits = '';
  bool _digitsMissing = false;
  Timer? _digitTimer;

  /// Seconds left before the next episode starts, or null when hidden.
  int? _nextIn;
  bool _nextCancelled = false;

  final _subs = <StreamSubscription<Object?>>[];

  bool get _isLive => _item.kind == ContentKind.live;
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _db;
    _settings;
    // mpv reports warnings (e.g. "cannot seek in this stream" on live TV)
    // through the same error stream. Only treat a message as a failure when
    // no picture has arrived yet.
    _subs.add(
      _player.stream.error.listen((e) {
        if (!mounted || _hasVideo || e.toLowerCase().contains('seek')) return;
        // Stream addresses often carry the account name and password.
        setState(() => _error = e.replaceAll(RegExp(r'\w+://\S+?(?=\.?(\s|$))'), 'the stream'));
      }),
    );
    _subs.add(
      _player.stream.width.listen((w) {
        if (w != null && w > 0) {
          _hasVideo = true;
          if (mounted && _error != null) setState(() => _error = null);
          _updatePip();
        }
      }),
    );
    _subs.add(_player.stream.tracks.listen(_applyTrackPrefs));
    _subs.add(_player.stream.position.listen(_watchForNext));
    _subs.add(
      _player.stream.completed.listen((done) {
        if (done && _req.upNext.isNotEmpty && !_nextCancelled && ref.read(settingsProvider).autoNext) _playNext();
      }),
    );
    _subs.add(
      Device.pipChanges.listen((v) {
        if (mounted) setState(() => _pip = v);
      }),
    );
    Device.pipSupported().then((v) {
      if (!mounted) return;
      setState(() => _pipSupported = v);
      _updatePip();
    });
    _open(_url, start: _req.startAt);
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
    if (_fullscreen) _setFullscreen(true);
    _bumpControls();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showChannelInfo();
    });
  }

  void _updatePip() {
    if (!_pipSupported) return;
    final w = _player.state.width ?? 16;
    final h = _player.state.height ?? 9;
    Device.setAutoPip(true, width: w, height: h);
  }

  Future<void> _open(String url, {Duration start = Duration.zero}) async {
    _hasVideo = false;
    _tracksApplied = false;
    _nextCancelled = false;
    setState(() {
      _error = null;
      _nextIn = null;
    });
    await _player.open(Media(url, start: start > Duration.zero ? start : null));
    if (_rate != 1 && !_isLive) await _player.setRate(_rate);
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
      historyKey: _req.historyKey ?? _item.key,
      itemKey: _item.key,
      title: _req.title,
      url: _url,
      positionMs: done ? 0 : pos.inMilliseconds,
      durationMs: dur.inMilliseconds,
    );
  }

  // ------------------------------------------------------------ next episode

  void _watchForNext(Duration pos) {
    if (_isLive || _req.upNext.isEmpty || _nextCancelled || !ref.read(settingsProvider).autoNext) return;
    final dur = _player.state.duration;
    if (dur <= const Duration(minutes: 1)) return;
    final left = (dur - pos).inSeconds;
    final show = left <= 15 && left >= 0;
    final value = show ? left : null;
    if (value != _nextIn && mounted) setState(() => _nextIn = value);
  }

  Future<void> _playNext() async {
    if (_req.upNext.isEmpty) return;
    await _playOther(_req.upNext.first.copyWith(upNext: _req.upNext.skip(1).toList()));
  }

  /// Switches to another episode or movie, resuming where it was left.
  Future<void> _playOther(PlayRequest next) async {
    await _saveProgress();
    final key = next.historyKey ?? next.item.key;
    final ms = await _db.progressOf(next.item.playlistId, key);
    if (!mounted) return;
    setState(() {
      _req = next.copyWith(historyKey: key);
      _item = next.item;
      _url = next.url;
    });
    await _open(_url, start: Duration(milliseconds: ms));
    if (!mounted) return;
    ref.invalidate(historyProvider);
    _bumpControls();
  }

  // ------------------------------------------------------- track preferences

  void _applyTrackPrefs(Tracks tracks) {
    if (_tracksApplied) return;
    final audio = tracks.audio.where((a) => a.id != 'auto' && a.id != 'no').toList();
    if (audio.isEmpty) return;
    _tracksApplied = true;
    final prefs = ref.read(settingsProvider);
    final wantAudio = prefs.audioLanguage;
    if (wantAudio != null && audio.length > 1) {
      final match = audio.where((a) => sameLanguage(a.language, wantAudio)).firstOrNull;
      if (match != null) _player.setAudioTrack(match);
    }
    final wantSub = prefs.subtitleLanguage;
    if (wantSub == 'off') {
      _player.setSubtitleTrack(SubtitleTrack.no());
    } else if (wantSub != null) {
      final subs = tracks.subtitle.where((s) => s.id != 'auto' && s.id != 'no');
      final match = subs.where((s) => sameLanguage(s.language, wantSub)).firstOrNull;
      if (match != null) _player.setSubtitleTrack(match);
    }
  }

  void _pickAudio(AudioTrack a) {
    _player.setAudioTrack(a);
    if (a.language != null && a.language!.isNotEmpty) _settings.setAudioLanguage(a.language);
  }

  void _pickSubtitle(SubtitleTrack s) {
    _player.setSubtitleTrack(s);
    if (s.id == 'no') {
      _settings.setSubtitleLanguage('off');
    } else if (s.language != null && s.language!.isNotEmpty) {
      _settings.setSubtitleLanguage(s.language);
    }
  }

  // ------------------------------------------------------------- sleep timer

  void _setSleep(Duration? d) {
    _sleepTimer?.cancel();
    setState(() => _sleepAt = d == null ? null : DateTime.now().add(d));
    if (d == null) return;
    _sleepTimer = Timer(d, () async {
      await _player.pause();
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  // ---------------------------------------------------------------- controls

  // --------------------------------------------------------- channel changes

  bool get _canZap => _isLive && _req.siblings.length > 1;

  /// Moves [delta] channels through the list the viewer came from (the open
  /// category, favorites or search results), wrapping at both ends.
  void _zap(int delta) {
    if (!_canZap) return;
    final list = _req.siblings;
    final i = list.indexWhere((c) => c.key == _item.key);
    _switchTo(list[((i < 0 ? 0 : i) + delta) % list.length]);
  }

  /// Shows [channel] right away but only loads it once the viewer stops on
  /// it, so flicking through five channels doesn't open five streams.
  void _switchTo(MediaItem channel, {bool now = false}) {
    if (channel.url == null) return;
    setState(() {
      _item = channel;
      _url = channel.url!;
    });
    _showChannelInfo();
    _zapTimer?.cancel();
    _zapTimer = Timer(now ? Duration.zero : const Duration(milliseconds: 400), () {
      if (mounted) _open(_url);
    });
  }

  void _pickChannel(MediaItem c) {
    if (c.key != _item.key) _switchTo(c, now: true);
  }

  /// Lists the channels the viewer came from while the current one keeps
  /// playing: a bottom sheet on portrait phones, a side panel otherwise.
  Future<void> _showChannelList() async {
    if (!_canZap) return;
    _hideTimer?.cancel();
    setState(() => _controlsVisible = false);
    final portrait = !Device.isTv && MediaQuery.orientationOf(context) == Orientation.portrait;
    final list = _ChannelPicker(channels: _req.siblings, current: _item);
    final MediaItem? picked;
    if (portrait) {
      picked = await showModalBottomSheet<MediaItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.canvas,
        builder: (ctx) => SizedBox(height: MediaQuery.sizeOf(ctx).height * 0.6, child: list),
      );
    } else {
      picked = await showGeneralDialog<MediaItem>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close channel list',
        barrierColor: Colors.black38,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (ctx, _, _) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: AppColors.canvas,
            child: SizedBox(
              width: min(420, MediaQuery.sizeOf(ctx).width * 0.45),
              height: double.infinity,
              child: SafeArea(left: false, child: list),
            ),
          ),
        ),
        transitionBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0.3, 0), end: Offset.zero).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
      );
    }
    _takeKeys();
    if (picked != null && mounted && picked.key != _item.key) _switchTo(picked, now: true);
  }

  void _showChannelInfo() {
    if (!_isLive) return;
    _bannerTimer?.cancel();
    setState(() => _banner = true);
    _bannerTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _banner = false);
    });
  }

  /// Collects channel number digits from a remote or keyboard, then jumps
  /// once the viewer pauses.
  void _typeDigit(int digit) {
    if (!_isLive) return;
    _digitTimer?.cancel();
    setState(() {
      _digitsMissing = false;
      _digits = '$_digits$digit';
      if (_digits.length > 4) _digits = _digits.substring(_digits.length - 4);
    });
    _digitTimer = Timer(const Duration(milliseconds: 1500), _jumpToTyped);
  }

  Future<void> _jumpToTyped() async {
    final n = int.tryParse(_digits);
    if (n == null || !mounted) return;
    var target = _req.siblings.where((c) => c.number == n).firstOrNull;
    target ??= await _db.liveByNumber(_item.playlistId, n, includeLocked: ref.read(lockedContentOpenProvider));
    if (!mounted) return;
    if (target == null) {
      setState(() => _digitsMissing = true);
      _digitTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _digits = '');
      });
      return;
    }
    setState(() => _digits = '');
    if (target.key != _item.key) _switchTo(target, now: true);
  }

  void _bumpControls() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _player.state.playing) setState(() => _controlsVisible = false);
    });
  }

  bool? _barsHidden;

  /// Hides the status and navigation bars whenever only the video shows,
  /// including when a phone is simply turned sideways.
  void _hideSystemBars(bool hide) {
    if (!_isMobile || _barsHidden == hide) return;
    _barsHidden = hide;
    SystemChrome.setEnabledSystemUIMode(hide ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Future<void> _setFullscreen(bool value) async {
    setState(() => _fullscreen = value);
    if (_isMobile) {
      // build() hides the system bars to match.
      if (value) {
        if (!Device.isTv) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      } else {
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }

  void _showOptions() {
    _bumpControls();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OptionsSheet(
        isLive: _isLive,
        smallPlayer: !(_fullscreen || (_isMobile && MediaQuery.orientationOf(context) == Orientation.landscape)),
        rate: _rate,
        sleepAt: _sleepAt,
        pipSupported: _pipSupported,
        onRate: (r) {
          setState(() => _rate = r);
          _player.setRate(r);
        },
        onSleep: _setSleep,
        onPip: Device.enterPip,
      ),
    ).then((_) => _takeKeys());
  }

  /// Puts remote and keyboard keys back on the player after a sheet closes.
  void _takeKeys() {
    if (mounted) _keys.requestFocus();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _sleepTimer?.cancel();
    _zapTimer?.cancel();
    _bannerTimer?.cancel();
    _digitTimer?.cancel();
    _keys.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    _saveProgress();
    Device.setAutoPip(false);
    Device.resetBrightness();
    if (_fullscreen && _isMobile) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _player.dispose();
    super.dispose();
  }

  static final _digitKeys = {
    for (final (i, k) in [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ].indexed)
      k: i,
    for (final (i, k) in [
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ].indexed)
      k: i,
  };

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    final k = e.logicalKey;
    // Holding a channel key keeps flicking through channels.
    if (e is KeyRepeatEvent && _isLive) {
      if (k == LogicalKeyboardKey.channelUp || k == LogicalKeyboardKey.pageUp) {
        _zap(1);
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.channelDown || k == LogicalKeyboardKey.pageDown) {
        _zap(-1);
        return KeyEventResult.handled;
      }
    }
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final digit = _digitKeys[k];
    if (digit != null && _isLive) {
      _typeDigit(digit);
      return KeyEventResult.handled;
    }
    // On a TV the arrows move between buttons while the controls show.
    final arrowsZap = _isLive && (!_controlsVisible || !Device.isTv);
    if (_isLive && (k == LogicalKeyboardKey.channelUp || k == LogicalKeyboardKey.pageUp)) {
      _zap(1);
      return KeyEventResult.handled;
    }
    if (_isLive && (k == LogicalKeyboardKey.channelDown || k == LogicalKeyboardKey.pageDown)) {
      _zap(-1);
      return KeyEventResult.handled;
    }
    if (arrowsZap && (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowDown)) {
      _zap(k == LogicalKeyboardKey.arrowUp ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space ||
        k == LogicalKeyboardKey.mediaPlayPause ||
        k == LogicalKeyboardKey.select ||
        k == LogicalKeyboardKey.enter) {
      if (!_controlsVisible && (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter)) {
        // OK on live TV opens the channel list, like a TV remote.
        _canZap ? _showChannelList() : _bumpControls();
        return KeyEventResult.handled;
      }
      _player.playOrPause();
    } else if (k == LogicalKeyboardKey.keyF) {
      _setFullscreen(!_fullscreen);
    } else if (k == LogicalKeyboardKey.escape && _fullscreen && !Device.isTv) {
      _setFullscreen(false);
    } else if (k == LogicalKeyboardKey.contextMenu || k == LogicalKeyboardKey.keyM) {
      _showOptions();
    } else if (_canZap && k == LogicalKeyboardKey.keyL) {
      _showChannelList();
      return KeyEventResult.handled;
    } else if (_isLive &&
        !_controlsVisible &&
        (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowRight)) {
      // With OK taken by the channel list, the side arrows bring up the controls.
      _bumpControls();
      return KeyEventResult.handled;
    } else if (!_isLive && (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.mediaFastForward)) {
      _player.seek(_player.state.position + const Duration(seconds: 10));
    } else if (!_isLive && (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.mediaRewind)) {
      _player.seek(_player.state.position - const Duration(seconds: 10));
    } else {
      return KeyEventResult.ignored;
    }
    _bumpControls();
    return KeyEventResult.handled;
  }

  BoxFit get _fit => switch (ref.watch(settingsProvider).videoFit) {
    VideoFit.fit => BoxFit.contain,
    VideoFit.fill => BoxFit.cover,
    VideoFit.stretch => BoxFit.fill,
  };

  @override
  Widget build(BuildContext context) {
    final fit = _fit;
    if (_pip) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Video(controller: _video, controls: NoVideoControls, fill: Colors.black, fit: fit),
      );
    }

    final orientation = MediaQuery.orientationOf(context);
    final wide = isWide(context);
    final videoOnly = _fullscreen || (_isMobile && orientation == Orientation.landscape);
    _hideSystemBars(videoOnly);
    final next = _req.upNext.firstOrNull;

    final surface = _VideoSurface(
      video: _video,
      player: _player,
      fit: fit,
      title: _req.title ?? _item.name,
      subtitle: _req.subtitle,
      isLive: _isLive,
      error: _error,
      controlsVisible: _controlsVisible,
      fullscreen: videoOnly,
      sleepAt: _sleepAt,
      onTap: () => _controlsVisible ? setState(() => _controlsVisible = false) : _bumpControls(),
      onInteract: _bumpControls,
      onBack: () => videoOnly && _fullscreen && !Device.isTv ? _setFullscreen(false) : Navigator.of(context).pop(),
      onFullscreen: () => _setFullscreen(!_fullscreen),
      onRetry: () => _open(_url, start: _player.state.position),
      onOptions: _showOptions,
      onPip: _pipSupported ? Device.enterPip : null,
      onAudio: _pickAudio,
      onSubtitle: _pickSubtitle,
      onPrevChannel: _canZap ? () => _zap(-1) : null,
      onNextChannel: _canZap ? () => _zap(1) : null,
      // Outside full screen the channel list already shows next to the video.
      onChannels: _canZap && videoOnly ? _showChannelList : null,
      // The small player has the same details right below it.
      channelCard: _isLive && _banner && videoOnly ? _ChannelCard(item: _item) : null,
      digitsCard: _digits.isEmpty ? null : _DigitsCard(digits: _digits, missing: _digitsMissing),
      nextCard: next == null || _nextIn == null
          ? null
          : _NextEpisodeCard(
              title: next.title ?? next.item.name,
              seconds: _nextIn!,
              onPlay: _playNext,
              onCancel: () => setState(() {
                _nextCancelled = true;
                _nextIn = null;
              }),
            ),
    );

    Widget body;
    if (videoOnly) {
      body = surface;
    } else if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(child: surface),
            ),
          ),
          SizedBox(
            width: 380,
            child: _InfoPanel(item: _item, request: _req, onPickChannel: _pickChannel, onPlay: _playOther),
          ),
        ],
      );
    } else {
      body = Column(
        children: [
          ColoredBox(
            color: Colors.black,
            child: SafeArea(bottom: false, child: surface),
          ),
          Expanded(
            child: _InfoPanel(item: _item, request: _req, onPickChannel: _pickChannel, onPlay: _playOther),
          ),
        ],
      );
    }

    return Focus(
      focusNode: _keys,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(backgroundColor: videoOnly ? Colors.black : AppColors.canvas, body: body),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.video,
    required this.player,
    required this.fit,
    required this.title,
    required this.subtitle,
    required this.isLive,
    required this.error,
    required this.controlsVisible,
    required this.fullscreen,
    required this.sleepAt,
    required this.onTap,
    required this.onInteract,
    required this.onBack,
    required this.onFullscreen,
    required this.onRetry,
    required this.onOptions,
    required this.onPip,
    required this.onAudio,
    required this.onSubtitle,
    required this.onPrevChannel,
    required this.onNextChannel,
    required this.onChannels,
    required this.channelCard,
    required this.digitsCard,
    required this.nextCard,
  });

  final VoidCallback? onPrevChannel;
  final VoidCallback? onNextChannel;
  final VoidCallback? onChannels;
  final Widget? channelCard;
  final Widget? digitsCard;
  final VideoController video;
  final Player player;
  final BoxFit fit;
  final String title;
  final String? subtitle;
  final bool isLive;
  final String? error;
  final bool controlsVisible;
  final bool fullscreen;
  final DateTime? sleepAt;
  final VoidCallback onTap;
  final VoidCallback onInteract;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;
  final VoidCallback onRetry;
  final VoidCallback onOptions;
  final VoidCallback? onPip;
  final ValueChanged<AudioTrack> onAudio;
  final ValueChanged<SubtitleTrack> onSubtitle;
  final Widget? nextCard;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        Video(controller: video, controls: NoVideoControls, fill: Colors.black, fit: fit),
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
                const Icon(Icons.portable_wifi_off, color: AppColors.muted, size: 34),
                const SizedBox(height: 10),
                Text('This stream could not be played', style: t.titleMedium),
                const SizedBox(height: 4),
                Text(
                  error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: t.bodySmall!.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        _GestureLayer(player: player, onTap: onTap, onDoubleTap: onFullscreen, onInteract: onInteract),
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
              sleepAt: sleepAt,
              onBack: onBack,
              onFullscreen: onFullscreen,
              onInteract: onInteract,
              onOptions: onOptions,
              onPip: onPip,
              onAudio: onAudio,
              onSubtitle: onSubtitle,
              onPrevChannel: onPrevChannel,
              onNextChannel: onNextChannel,
              onChannels: onChannels,
            ),
          ),
        ),
        if (channelCard != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: controlsVisible ? 60 : 12,
            child: IgnorePointer(
              child: Align(alignment: Alignment.bottomLeft, child: channelCard!),
            ),
          ),
        if (digitsCard != null) Positioned(top: 12, right: 16, child: IgnorePointer(child: digitsCard!)),
        if (nextCard != null) Positioned(right: 12, bottom: 56, child: nextCard!),
      ],
    );
    return fullscreen ? stack : AspectRatio(aspectRatio: 16 / 9, child: stack);
  }
}

/// Tap to show controls, double tap for full screen, and vertical swipes:
/// left half for brightness (phones), right half for volume.
class _GestureLayer extends StatefulWidget {
  const _GestureLayer({required this.player, required this.onTap, required this.onDoubleTap, required this.onInteract});
  final Player player;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onInteract;

  @override
  State<_GestureLayer> createState() => _GestureLayerState();
}

enum _Adjust { brightness, volume }

class _GestureLayerState extends State<_GestureLayer> {
  _Adjust? _adjusting;
  double _value = 0;
  double _brightness = 0.5;
  double _volume = 0.5;
  Timer? _hide;

  bool get _android => Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_android) {
      _brightness = await Device.brightness();
      _volume = await Device.volume();
    } else {
      _volume = widget.player.state.volume / 100;
    }
  }

  void _start(DragStartDetails d, double width) {
    _hide?.cancel();
    final left = d.localPosition.dx < width / 2;
    final kind = left && _android ? _Adjust.brightness : _Adjust.volume;
    setState(() {
      _adjusting = kind;
      _value = kind == _Adjust.brightness ? _brightness : _volume;
    });
    // Volume may have changed with the hardware buttons since last time.
    if (kind == _Adjust.volume && _android) {
      Device.volume().then((v) {
        if (mounted && _adjusting == _Adjust.volume) setState(() => _value = _volume = v);
      });
    }
  }

  void _update(DragUpdateDetails d, double height) {
    if (_adjusting == null) return;
    // A swipe over ~70% of the picture height covers the full range.
    final v = (_value - d.delta.dy / (height * 0.7)).clamp(0.0, 1.0);
    setState(() => _value = v);
    if (_adjusting == _Adjust.brightness) {
      _brightness = v;
      Device.setBrightness(v);
    } else {
      _volume = v;
      if (_android) {
        Device.setVolume(v);
      } else {
        widget.player.setVolume(v * 100);
      }
    }
  }

  void _end() {
    _hide = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _adjusting = null);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onVerticalDragStart: (d) => _start(d, box.maxWidth),
        onVerticalDragUpdate: (d) => _update(d, box.maxHeight),
        onVerticalDragEnd: (_) => _end(),
        onVerticalDragCancel: _end,
        child: MouseRegion(
          onHover: (_) => widget.onInteract(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_adjusting != null)
                Align(
                  alignment: _adjusting == _Adjust.brightness ? const Alignment(-0.75, 0) : const Alignment(0.75, 0),
                  child: _LevelIndicator(
                    icon: _adjusting == _Adjust.brightness
                        ? (_value < 0.3
                              ? Icons.brightness_low
                              : _value < 0.7
                              ? Icons.brightness_medium
                              : Icons.brightness_high)
                        : (_value == 0
                              ? Icons.volume_off
                              : _value < 0.5
                              ? Icons.volume_down
                              : Icons.volume_up),
                    value: _value,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  const _LevelIndicator({required this.icon, required this.value});
  final IconData icon;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            width: 4,
            child: RotatedBox(
              quarterTurns: 3,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                color: AppColors.tally,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(value * 100).round()}',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white, fontFeatures: tabular),
          ),
        ],
      ),
    );
  }
}

const _cardDecoration = BoxDecoration(
  color: Color(0xE616292E),
  borderRadius: BorderRadius.all(Radius.circular(10)),
  border: Border(left: BorderSide(color: AppColors.tally, width: 3)),
);

/// Shown for a few seconds after a channel change: number, name, what's on
/// now with its progress, and what comes next.
class _ChannelCard extends ConsumerWidget {
  const _ChannelCard({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final guide = ref.watch(scheduleProvider(item)).value ?? const <EpgProgram>[];
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final current = guide.where((p) => p.isLiveAt(now)).firstOrNull;
    final next = guide.where((p) => !p.start.isBefore(current?.stop ?? now)).firstOrNull;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
      decoration: _cardDecoration,
      child: Row(
        children: [
          ChannelLogo(name: item.name, url: item.logo, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.number != null) ...[
                      Text(
                        item.number.toString().padLeft(3, '0'),
                        style: t.labelMedium!.copyWith(color: AppColors.tally, fontFeatures: tabular),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    ),
                  ],
                ),
                if (current != null) ...[
                  const SizedBox(height: 4),
                  Text(current.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
                  const SizedBox(height: 6),
                  TallyBar(value: current.progressAt(now)),
                ],
                if (next != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Next  ${formatTime(next.start)}  ${next.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall!.copyWith(color: AppColors.muted),
                  ),
                ],
                if (current == null && next == null && item.group.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.group, style: t.bodySmall!.copyWith(color: AppColors.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Channel number being typed on a remote or keyboard.
class _DigitsCard extends StatelessWidget {
  const _DigitsCard({required this.digits, required this.missing});
  final String digits;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: _cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            digits,
            style: t.headlineMedium!.copyWith(
              color: missing ? AppColors.muted : Colors.white,
              fontFeatures: tabular,
              letterSpacing: 2,
            ),
          ),
          if (missing) Text('No channel $digits', style: t.labelSmall!.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _NextEpisodeCard extends StatelessWidget {
  const _NextEpisodeCard({required this.title, required this.seconds, required this.onPlay, required this.onCancel});
  final String title;
  final int seconds;
  final VoidCallback onPlay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: 260,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xE616292E),
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: AppColors.tally, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Next episode in $seconds s', style: t.labelMedium!.copyWith(color: AppColors.tally)),
          const SizedBox(height: 4),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              const SizedBox(width: 4),
              FilledButton(onPressed: onPlay, child: const Text('Play now')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Picture size, speed, sleep timer and picture-in-picture.
class _OptionsSheet extends ConsumerStatefulWidget {
  const _OptionsSheet({
    required this.isLive,
    required this.smallPlayer,
    required this.rate,
    required this.sleepAt,
    required this.pipSupported,
    required this.onRate,
    required this.onSleep,
    required this.onPip,
  });
  final bool isLive;

  /// The video sits in a 16:9 box above the details, where size choices
  /// rarely make a visible difference.
  final bool smallPlayer;
  final double rate;
  final DateTime? sleepAt;
  final bool pipSupported;
  final ValueChanged<double> onRate;
  final ValueChanged<Duration?> onSleep;
  final Future<bool> Function() onPip;

  @override
  ConsumerState<_OptionsSheet> createState() => _OptionsSheetState();
}

class _OptionsSheetState extends ConsumerState<_OptionsSheet> {
  late double _rate = widget.rate;
  late DateTime? _sleepAt = widget.sleepAt;

  static const _rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _sleeps = [15, 30, 45, 60, 90, 120];

  String _rateLabel(double r) => r == 1 ? 'Normal' : '${r.toString().replaceAll(RegExp(r'\.0$'), '')}×';

  Widget _choices<T>(List<T> values, T? selected, String Function(T) label, ValueChanged<T> onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              showCheckmark: false,
              onSelected: (_) => onTap(v),
              labelStyle: Theme.of(context).textTheme.labelMedium!
                  .copyWith(color: v == selected ? AppColors.onTally : AppColors.text),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fit = ref.watch(settingsProvider).videoFit;
    final left = _sleepAt?.difference(DateTime.now());

    Widget heading(String text, [String? trailing]) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: t.titleSmall!.copyWith(color: AppColors.muted)),
          ),
          if (trailing != null) Text(trailing, style: t.labelMedium!.copyWith(color: AppColors.tally)),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Picture size'),
            if (widget.smallPlayer)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  'You see the difference in full screen. The small player keeps the original shape, so most videos look the same here.',
                  style: t.bodySmall!.copyWith(color: AppColors.muted),
                ),
              ),
            _choices<VideoFit>(
              VideoFit.values,
              fit,
              (f) => switch (f) {
                VideoFit.fit => 'Fit',
                VideoFit.fill => 'Fill screen',
                VideoFit.stretch => 'Stretch',
              },
              (f) => ref.read(settingsProvider.notifier).setVideoFit(f),
            ),
            if (!widget.isLive) ...[
              heading('Playback speed'),
              _choices<double>(_rates, _rate, _rateLabel, (r) {
                setState(() => _rate = r);
                widget.onRate(r);
              }),
            ],
            heading(
              'Sleep timer',
              left == null || left.isNegative ? null : 'Stops in ${formatDuration(left + const Duration(seconds: 59))}',
            ),
            _choices<int?>(
              [null, ..._sleeps],
              null,
              (m) => m == null ? 'Off' : (m < 60 ? '$m min' : '${m ~/ 60} h${m % 60 == 0 ? '' : ' ${m % 60} min'}'),
              (m) {
                widget.onSleep(m == null ? null : Duration(minutes: m));
                setState(() => _sleepAt = m == null ? null : DateTime.now().add(Duration(minutes: m)));
              },
            ),
            if (widget.pipSupported)
              ListTile(
                leading: const Icon(Icons.picture_in_picture_alt_outlined),
                title: const Text('Picture in picture'),
                subtitle: const Text('Keep watching in a small window. Pressing Home does this too.'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPip();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.player,
    required this.title,
    required this.subtitle,
    required this.isLive,
    required this.fullscreen,
    required this.sleepAt,
    required this.onBack,
    required this.onFullscreen,
    required this.onInteract,
    required this.onOptions,
    required this.onPip,
    required this.onAudio,
    required this.onSubtitle,
    required this.onPrevChannel,
    required this.onNextChannel,
    required this.onChannels,
  });

  final VoidCallback? onPrevChannel;
  final VoidCallback? onNextChannel;
  final VoidCallback? onChannels;
  final Player player;
  final String title;
  final String? subtitle;
  final bool isLive;
  final bool fullscreen;
  final DateTime? sleepAt;
  final VoidCallback onBack;
  final VoidCallback onFullscreen;
  final VoidCallback onInteract;
  final VoidCallback onOptions;
  final VoidCallback? onPip;
  final ValueChanged<AudioTrack> onAudio;
  final ValueChanged<SubtitleTrack> onSubtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // The scrim lets touches through, so swipes work while controls show.
    return Stack(
      fit: StackFit.expand,
      children: [
        const IgnorePointer(child: ColoredBox(color: Color(0x66000000))),
        SafeArea(
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
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium!.copyWith(color: Colors.white),
                    ),
                  ),
                  if (sleepAt != null)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.bedtime_outlined, color: AppColors.tally, size: 20),
                    ),
                  if (onChannels != null)
                    IconButton(
                      tooltip: 'Channels',
                      onPressed: onChannels,
                      icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
                    ),
                  _TracksButtons(player: player, onInteract: onInteract, onAudio: onAudio, onSubtitle: onSubtitle),
                  IconButton(
                    tooltip: 'Player options',
                    onPressed: onOptions,
                    icon: const Icon(Icons.tune, color: Colors.white),
                  ),
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
                          // Live TV can't be rewound; the side buttons change
                          // channel instead.
                          if (onPrevChannel != null)
                            _RoundButton(
                              icon: Icons.skip_previous,
                              tooltip: 'Previous channel',
                              onPressed: () {
                                onPrevChannel!();
                                onInteract();
                              },
                            ),
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
                          if (onNextChannel != null)
                            _RoundButton(
                              icon: Icons.skip_next,
                              tooltip: 'Next channel',
                              onPressed: () {
                                onNextChannel!();
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
                          ? Text(
                              subtitle ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall!.copyWith(color: Colors.white70),
                            )
                          : _SeekBar(player: player, onInteract: onInteract),
                    ),
                    if (onPip != null)
                      IconButton(
                        tooltip: 'Picture in picture',
                        onPressed: onPip,
                        icon: const Icon(Icons.picture_in_picture_alt_outlined, color: Colors.white),
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
      ],
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
        backgroundColor: big ? AppColors.tally : const Color(0x33000000),
        foregroundColor: big ? AppColors.onTally : Colors.white,
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
                  activeTrackColor: AppColors.tally,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.tally,
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

/// Separate audio and subtitle pickers. Each button only appears when the
/// stream actually offers a choice: several audio tracks, or any subtitles.
class _TracksButtons extends StatelessWidget {
  const _TracksButtons({
    required this.player,
    required this.onInteract,
    required this.onAudio,
    required this.onSubtitle,
  });
  final Player player;
  final VoidCallback onInteract;

  /// Also remember the language for the next video.
  final ValueChanged<AudioTrack> onAudio;
  final ValueChanged<SubtitleTrack> onSubtitle;

  static bool _real(String id) => id != 'auto' && id != 'no';

  static String _label(String? rawTitle, String? lang, int i) {
    final name = lang == null || lang.isEmpty ? null : _languageName(lang);
    // Files often shout their track titles ("FORCED"); show them as "Forced".
    // Only plain words, so names like "DTS-HD MA 5.1" stay as they are.
    final title = rawTitle != null && RegExp(r'^[A-Z]{4,}$').hasMatch(rawTitle)
        ? rawTitle[0] + rawTitle.substring(1).toLowerCase()
        : rawTitle;
    final parts = [
      ?name,
      // Skip a title that only repeats the language ("English").
      if (title != null && title.isNotEmpty && (name == null || title.toLowerCase() != name.toLowerCase())) title,
    ];
    return parts.isEmpty ? 'Track ${i + 1}' : parts.join(' · ');
  }

  static String _channels(int? count) => switch (count) {
    null || 0 => '',
    1 => 'Mono',
    2 => 'Stereo',
    6 => '5.1',
    8 => '7.1',
    _ => '$count ch',
  };

  /// Audio label with the format, so two English tracks can be told apart.
  static String _audioLabel(AudioTrack a, int i) {
    final details = [
      if (a.codec != null && a.codec!.isNotEmpty) a.codec!.toUpperCase(),
      _channels(a.channelscount),
    ].where((s) => s.isNotEmpty).join(' ');
    final base = _label(a.title, a.language, i);
    return details.isEmpty ? base : '$base · $details';
  }

  /// Gives identical labels a track number so every row is distinct.
  static List<String> _distinct(List<String> labels) {
    return [for (final (i, l) in labels.indexed) labels.where((o) => o == l).length > 1 ? '$l · Track ${i + 1}' : l];
  }

  /// The track actually playing. Before the viewer picks one the player
  /// reports "auto", so ask mpv which track it chose.
  Future<String> _current(String reported, String property) async {
    if (reported != 'auto') return reported;
    final native = player.platform;
    if (native is NativePlayer) {
      try {
        return await native.getProperty(property);
      } catch (_) {}
    }
    return reported;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      initialData: player.state.tracks,
      builder: (context, snap) {
        final tracks = snap.data ?? const Tracks();
        final audio = tracks.audio.where((a) => _real(a.id)).toList();
        final subs = tracks.subtitle.where((s) => _real(s.id)).toList();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (audio.length > 1)
              IconButton(
                tooltip: 'Audio',
                icon: const Icon(Icons.audiotrack_outlined, color: Colors.white),
                onPressed: () => _pick<AudioTrack>(
                  context,
                  title: 'Audio',
                  options: [
                    for (final (i, label) in _distinct([for (final (i, a) in audio.indexed) _audioLabel(a, i)]).indexed)
                      (audio[i], label),
                  ],
                  selectedId: _current(player.state.track.audio.id, 'aid'),
                  id: (a) => a.id,
                  onSelect: onAudio,
                ),
              ),
            if (subs.isNotEmpty)
              IconButton(
                tooltip: 'Subtitles',
                icon: const Icon(Icons.closed_caption_outlined, color: Colors.white),
                onPressed: () => _pick<SubtitleTrack>(
                  context,
                  title: 'Subtitles',
                  options: [
                    (SubtitleTrack.no(), 'Off'),
                    for (final (i, label) in _distinct([
                      for (final (i, s) in subs.indexed) _label(s.title, s.language, i),
                    ]).indexed)
                      (subs[i], label),
                  ],
                  selectedId: _current(player.state.track.subtitle.id, 'sid'),
                  id: (s) => s.id,
                  onSelect: onSubtitle,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pick<T>(
    BuildContext context, {
    required String title,
    required List<(T, String)> options,
    required Future<String> selectedId,
    required String Function(T) id,
    required void Function(T) onSelect,
  }) async {
    onInteract();
    final selected = await selectedId;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              for (final (track, label) in options)
                ListTile(
                  title: Text(label),
                  trailing: id(track) == selected ? const Icon(Icons.check, color: AppColors.tally) : null,
                  onTap: () {
                    onSelect(track);
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether two language codes ("tr", "tur", "Turkish") mean the same language.
bool sameLanguage(String? a, String b) {
  if (a == null || a.isEmpty) return false;
  return _languageName(a).toLowerCase() == _languageName(b).toLowerCase();
}

/// Readable names for the language codes streams usually carry.
String languageName(String code) => _languageName(code);

String _languageName(String code) {
  const names = {
    'tur': 'Turkish',
    'tr': 'Turkish',
    'eng': 'English',
    'en': 'English',
    'ger': 'German',
    'deu': 'German',
    'de': 'German',
    'fre': 'French',
    'fra': 'French',
    'fr': 'French',
    'spa': 'Spanish',
    'es': 'Spanish',
    'ita': 'Italian',
    'it': 'Italian',
    'ara': 'Arabic',
    'ar': 'Arabic',
    'rus': 'Russian',
    'ru': 'Russian',
    'por': 'Portuguese',
    'pt': 'Portuguese',
    'dut': 'Dutch',
    'nld': 'Dutch',
    'nl': 'Dutch',
    'pol': 'Polish',
    'pl': 'Polish',
    'gre': 'Greek',
    'ell': 'Greek',
    'jpn': 'Japanese',
    'ja': 'Japanese',
    'kor': 'Korean',
    'ko': 'Korean',
    'chi': 'Chinese',
    'zho': 'Chinese',
    'zh': 'Chinese',
    'hin': 'Hindi',
    'per': 'Persian',
    'fas': 'Persian',
    'kur': 'Kurdish',
    'aze': 'Azerbaijani',
    'swe': 'Swedish',
    'nor': 'Norwegian',
    'dan': 'Danish',
    'fin': 'Finnish',
    'ron': 'Romanian',
    'rum': 'Romanian',
    'bul': 'Bulgarian',
    'hun': 'Hungarian',
    'cze': 'Czech',
    'ces': 'Czech',
    'ukr': 'Ukrainian',
    'heb': 'Hebrew',
    'und': 'Unknown',
  };
  return names[code.toLowerCase()] ?? code;
}

/// The channels the viewer came from, as a sheet or side panel over the
/// video. Pops the picked channel.
class _ChannelPicker extends StatelessWidget {
  const _ChannelPicker({required this.channels, required this.current});
  final List<MediaItem> channels;
  final MediaItem current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Row(
            children: [
              Expanded(child: Text('Channels', style: t.titleMedium)),
              IconButton(tooltip: 'Close', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        Expanded(
          child: _ChannelList(
            channels: channels,
            current: current,
            autofocus: true,
            onPick: (c) => Navigator.of(context).pop(c),
          ),
        ),
      ],
    );
  }
}

/// Channel rows with what's on now. The playing channel is highlighted and
/// kept in view as the viewer zaps.
class _ChannelList extends ConsumerStatefulWidget {
  const _ChannelList({required this.channels, required this.current, required this.onPick, this.autofocus = false});
  final List<MediaItem> channels;
  final MediaItem current;
  final ValueChanged<MediaItem> onPick;

  /// Puts remote focus on the playing channel (sheet and side panel).
  final bool autofocus;

  @override
  ConsumerState<_ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends ConsumerState<_ChannelList> {
  static const _rowHeight = 68.0;
  late final _scroll = ScrollController(initialScrollOffset: _offsetFor(_index));

  int get _index => widget.channels.indexWhere((c) => c.key == widget.current.key);
  double _offsetFor(int i) => max(0, i - 2) * _rowHeight;

  @override
  void didUpdateWidget(_ChannelList old) {
    super.didUpdateWidget(old);
    final i = _index;
    if (old.current.key == widget.current.key || i < 0 || !_scroll.hasClients) return;
    final top = i * _rowHeight;
    final pos = _scroll.position;
    if (top >= pos.pixels && top + _rowHeight <= pos.pixels + pos.viewportDimension) return;
    _scroll.animateTo(
      min(_offsetFor(i), pos.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final guide = ref.watch(nowPlayingProvider).value ?? const {};
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final channels = widget.channels;
    final current = _index;
    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.only(bottom: 12 + MediaQuery.paddingOf(context).bottom),
      itemCount: channels.length,
      itemExtent: _rowHeight,
      itemBuilder: (context, i) {
        final c = channels[i];
        final active = i == current;
        final program = c.tvgId == null ? null : guide[c.tvgId!.toLowerCase()];
        return Material(
          color: active ? AppColors.tally.withAlpha(0x1F) : Colors.transparent,
          child: InkWell(
            autofocus: widget.autofocus && active,
            onTap: () => widget.onPick(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      c.number?.toString() ?? '',
                      style: t.labelMedium!.copyWith(
                        color: active ? AppColors.tally : AppColors.muted,
                        fontFeatures: tabular,
                      ),
                    ),
                  ),
                  ChannelLogo(name: c.name, url: c.logo, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall!.copyWith(color: active ? AppColors.tally : null),
                        ),
                        if (program != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            program.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall!.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 5),
                          TallyBar(value: program.progressAt(now)),
                        ],
                      ],
                    ),
                  ),
                  if (active)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.equalizer, color: AppColors.tally, size: 20),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What sits under the player: the channel list for live TV, the season's
/// episodes for series and more from the same category for movies.
class _InfoPanel extends ConsumerWidget {
  const _InfoPanel({required this.item, required this.request, required this.onPickChannel, required this.onPlay});
  final MediaItem item;
  final PlayRequest request;
  final ValueChanged<MediaItem> onPickChannel;

  /// Switches the player to another episode or movie.
  final ValueChanged<PlayRequest> onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final isLive = item.kind == ContentKind.live;
    final favorite = ref.watch(_favoriteProvider(item)).value ?? item.favorite;

    final header = Row(
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
                style: t.bodySmall!.copyWith(color: AppColors.muted),
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
          icon: Icon(favorite ? Icons.star : Icons.star_border, color: favorite ? AppColors.tally : AppColors.muted),
        ),
      ],
    );

    if (isLive && request.siblings.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: header),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _Guide(item: item, compact: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Channels', style: t.titleMedium),
          ),
          Expanded(
            child: _ChannelList(channels: request.siblings, current: item, onPick: onPickChannel),
          ),
        ],
      );
    }

    final description = request.description ?? item.plot;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        header,
        const SizedBox(height: 16),
        switch (item.kind) {
          ContentKind.live => _Guide(item: item),
          ContentKind.series => VodInfoText(info: null, fallbackPlot: description),
          ContentKind.movie =>
            request.description != null
                ? VodInfoText(info: null, fallbackPlot: description)
                : ref
                      .watch(movieInfoProvider(item))
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => VodInfoText(info: null, fallbackPlot: item.plot),
                        data: (info) => VodInfoText(info: info, fallbackPlot: item.plot),
                      ),
        },
        if (item.kind == ContentKind.series) _Episodes(series: item, playingKey: request.historyKey, onPlay: onPlay),
        if (item.kind == ContentKind.movie) _MoreMovies(movie: item, onPlay: onPlay),
      ],
    );
  }
}

/// The episodes of the playing season, with watch progress. Other seasons
/// are a chip away.
class _Episodes extends ConsumerStatefulWidget {
  const _Episodes({required this.series, required this.playingKey, required this.onPlay});
  final MediaItem series;
  final String? playingKey;
  final ValueChanged<PlayRequest> onPlay;

  @override
  ConsumerState<_Episodes> createState() => _EpisodesState();
}

class _EpisodesState extends ConsumerState<_Episodes> {
  int? _season;

  @override
  void didUpdateWidget(_Episodes old) {
    super.didUpdateWidget(old);
    // Follow the player into the next season.
    if (old.playingKey != widget.playingKey) _season = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final details = ref.watch(seriesDetailsProvider(widget.series)).value;
    if (details == null || details.seasons.isEmpty) return const SizedBox.shrink();
    final history = ref.watch(historyProvider).value ?? const [];
    final progress = <String, WatchEntry>{
      for (final (e, _) in history)
        if (e.item.key == widget.series.key) e.historyKey: e,
    };
    final all = details.seasons.values.expand((e) => e).toList();
    final playing = all.where((e) => e.key == widget.playingKey).firstOrNull;
    final seasons = details.seasons.keys.toList();
    final season = _season ?? playing?.season ?? seasons.first;
    final episodes = details.seasons[season] ?? const <Episode>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    labelStyle: t.labelMedium!.copyWith(color: active ? AppColors.onTally : AppColors.text),
                  ),
                );
              },
            ),
          )
        else
          Text('Season $season', style: t.titleMedium),
        const SizedBox(height: 8),
        for (final e in episodes)
          _EpisodeTile(
            episode: e,
            playing: e.key == widget.playingKey,
            progress: progress[e.key],
            fallbackImage: widget.series.logo,
            onTap: () => widget.onPlay(episodeRequest(widget.series, e, all)),
          ),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.playing,
    required this.progress,
    required this.fallbackImage,
    required this.onTap,
  });
  final Episode episode;
  final bool playing;
  final WatchEntry? progress;
  final String? fallbackImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final started = progress != null && progress!.positionMs > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: playing ? AppColors.tally.withAlpha(0x1F) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: playing ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Poster(title: episode.title, url: episode.image ?? fallbackImage, aspectRatio: 16 / 9),
                      if (started && !playing)
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
                      Text(
                        '${episode.number}. ${episode.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall!.copyWith(color: playing ? AppColors.tally : null),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        playing ? 'Playing' : episode.duration ?? '',
                        style: t.labelSmall!.copyWith(
                          color: playing ? AppColors.tally : AppColors.muted,
                          fontFeatures: tabular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Other movies from the same category, starting after the playing one.
class _MoreMovies extends ConsumerWidget {
  const _MoreMovies({required this.movie, required this.onPlay});
  final MediaItem movie;
  final ValueChanged<PlayRequest> onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final all = ref.watch(itemsProvider((kind: ContentKind.movie, group: movie.group, search: ''))).value;
    if (all == null) return const SizedBox.shrink();
    final i = all.indexWhere((m) => m.key == movie.key);
    final others = [...all.skip(i + 1), ...all.take(max(i, 0))].where((m) => m.url != null).take(20).toList();
    if (others.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('More from ${movie.group}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: others.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = others[i];
              return SizedBox(
                width: 104,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPlay(PlayRequest(item: m, url: m.url!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Poster(title: m.name, url: m.logo),
                      const SizedBox(height: 6),
                      Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final _favoriteProvider = FutureProvider.autoDispose.family<bool, MediaItem>((ref, item) async {
  final fresh = await ref.watch(databaseProvider).itemByKey(item.playlistId, item.key);
  return fresh?.favorite ?? item.favorite;
});

class _Guide extends ConsumerWidget {
  const _Guide({required this.item, this.compact = false});
  final MediaItem item;

  /// Only what's on now and next, and nothing at all without guide data.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final schedule = ref.watch(scheduleProvider(item));
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    return schedule.when(
      loading: () => compact ? const SizedBox.shrink() : const LinearProgressIndicator(),
      error: (e, _) => compact ? const SizedBox.shrink() : Text('$e'),
      data: (list) {
        if (list.isEmpty) {
          if (compact) return const SizedBox.shrink();
          return Text('No guide data for this channel.', style: t.bodySmall!.copyWith(color: AppColors.muted));
        }
        final current = list.first.isLiveAt(now) ? list.first : null;
        final upcoming = current == null ? list : list.skip(1).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current != null)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: AppColors.tally, width: 3)),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Now', style: t.labelMedium!.copyWith(color: AppColors.tally)),
                        const SizedBox(width: 8),
                        Text(
                          '${formatTime(current.start)} – ${formatTime(current.stop)}',
                          style: t.labelMedium!.copyWith(color: AppColors.muted, fontFeatures: tabular),
                        ),
                        const Spacer(),
                        Text(
                          '${formatDuration(current.stop.difference(now))} left',
                          style: t.labelMedium!.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(current.title, style: t.titleLarge),
                    if (current.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        current.description!,
                        maxLines: compact ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium!.copyWith(color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TallyBar(value: current.progressAt(now), height: 4),
                  ],
                ),
              ),
            if (compact && upcoming.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Next  ${formatTime(upcoming.first.start)}  ${upcoming.first.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall!.copyWith(color: AppColors.muted),
                ),
              ),
            if (!compact && upcoming.isNotEmpty) ...[
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
                        child: Text(
                          formatTime(p.start),
                          style: t.titleSmall!.copyWith(color: AppColors.tally, fontFeatures: tabular),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: t.titleSmall),
                            if (p.description != null)
                              Text(
                                p.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall!.copyWith(color: AppColors.muted),
                              ),
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
