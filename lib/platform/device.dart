import 'dart:async';

import 'package:flutter/services.dart';

/// Screen brightness, system volume, picture-in-picture and handing a stream
/// to another app. Backed by `MainActivity.kt`.
class Device {
  Device._();

  static const _ch = MethodChannel('tally/device');
  static final _pip = StreamController<bool>.broadcast();

  /// Emits when the app enters or leaves picture-in-picture.
  static Stream<bool> get pipChanges => _pip.stream;
  static bool inPip = false;

  static final _audioStopped = StreamController<void>.broadcast();

  /// Emits when the viewer presses Stop on the audio-only notification.
  static Stream<void> get audioStopped => _audioStopped.stream;

  static Future<void> init() async {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') {
        inPip = call.arguments == true;
        _pip.add(inPip);
      } else if (call.method == 'audioStopped') {
        _audioStopped.add(null);
      }
    });
  }

  static Future<double> brightness() async => await _safe(() => _ch.invokeMethod<double>('getBrightness'), 0.5) ?? 0.5;

  static Future<void> setBrightness(double v) async {
    await _safe(() => _ch.invokeMethod('setBrightness', v), null);
  }

  /// Gives control back to the system brightness setting.
  static Future<void> resetBrightness() async {
    await _safe(() => _ch.invokeMethod('resetBrightness'), null);
  }

  static Future<double> volume() async => await _safe(() => _ch.invokeMethod<double>('getVolume'), 0.5) ?? 0.5;

  static Future<void> setVolume(double v) async {
    await _safe(() => _ch.invokeMethod('setVolume', v), null);
  }

  static Future<bool> pipSupported() async => await _safe(() => _ch.invokeMethod<bool>('pipSupported'), false) ?? false;

  /// While enabled, pressing Home during playback continues in a small window.
  static Future<void> setAutoPip(bool enabled, {int width = 16, int height = 9}) async {
    await _safe(() => _ch.invokeMethod('setAutoPip', {'enabled': enabled, 'width': width, 'height': height}), null);
  }

  static Future<bool> enterPip() async => await _safe(() => _ch.invokeMethod<bool>('enterPip'), false) ?? false;

  /// Lets the viewer play [url] in another app such as VLC or MX Player.
  /// False when no app can open it.
  static Future<bool> openExternally(String url, {String? title}) async =>
      await _safe(() => _ch.invokeMethod<bool>('openExternally', {'url': url, 'title': title}), false) ?? false;

  /// Keeps sound going with the screen off, with a notification that shows
  /// [title] and a Stop button labelled [stop].
  static Future<void> startAudioOnly({required String title, required String text, required String stop}) async {
    await _safe(() => _ch.invokeMethod('startAudioOnly', {'title': title, 'text': text, 'stop': stop}), null);
  }

  static Future<void> stopAudioOnly() async {
    await _safe(() => _ch.invokeMethod('stopAudioOnly'), null);
  }

  /// True when the phone is online through mobile data, not Wi-Fi.
  static Future<bool> onMobileData() async => await _safe(() => _ch.invokeMethod<bool>('onMobileData'), false) ?? false;

  static Future<T?> _safe<T>(Future<T?> Function() run, T? fallback) async {
    try {
      return await run();
    } on PlatformException {
      return fallback;
    } on MissingPluginException {
      return fallback;
    }
  }
}
