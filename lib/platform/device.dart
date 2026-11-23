import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Screen brightness, system volume, picture-in-picture and TV detection.
/// Backed by `MainActivity.kt` on Android; other platforms get safe no-ops.
class Device {
  Device._();

  static const _ch = MethodChannel('slayer/device');
  static bool get _android => Platform.isAndroid;

  /// Set once in `main()`.
  static bool isTv = false;

  static final _pip = StreamController<bool>.broadcast();

  /// Emits when the app enters or leaves picture-in-picture.
  static Stream<bool> get pipChanges => _pip.stream;
  static bool inPip = false;

  static Future<void> init() async {
    if (!_android) return;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'pipChanged') {
        inPip = call.arguments == true;
        _pip.add(inPip);
      }
    });
    isTv = await _safe(() => _ch.invokeMethod<bool>('isTv'), false) ?? false;
  }

  static Future<double> brightness() async =>
      _android ? (await _safe(() => _ch.invokeMethod<double>('getBrightness'), 0.5) ?? 0.5) : 0.5;

  static Future<void> setBrightness(double v) async {
    if (_android) await _safe(() => _ch.invokeMethod('setBrightness', v), null);
  }

  /// Gives control back to the system brightness setting.
  static Future<void> resetBrightness() async {
    if (_android) await _safe(() => _ch.invokeMethod('resetBrightness'), null);
  }

  static Future<double> volume() async =>
      _android ? (await _safe(() => _ch.invokeMethod<double>('getVolume'), 0.5) ?? 0.5) : 0.5;

  static Future<void> setVolume(double v) async {
    if (_android) await _safe(() => _ch.invokeMethod('setVolume', v), null);
  }

  static Future<bool> pipSupported() async =>
      _android && !isTv && (await _safe(() => _ch.invokeMethod<bool>('pipSupported'), false) ?? false);

  /// While enabled, pressing Home during playback continues in a small window.
  static Future<void> setAutoPip(bool enabled, {int width = 16, int height = 9}) async {
    if (!_android) return;
    await _safe(() => _ch.invokeMethod('setAutoPip', {'enabled': enabled, 'width': width, 'height': height}), null);
  }

  static Future<bool> enterPip() async =>
      _android && (await _safe(() => _ch.invokeMethod<bool>('enterPip'), false) ?? false);

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
