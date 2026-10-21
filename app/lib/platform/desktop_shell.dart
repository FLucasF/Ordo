import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Windows window around the app (windows/runner/flutter_window.cpp): the tray icon, the
/// "Despertador" sound, bringing the window back and starting with Windows. Elsewhere (Android,
/// tests) every call does nothing.
abstract final class DesktopShell {
  static const _channel = MethodChannel('tarefas/window');

  /// Whether this platform has the shell (Windows, outside tests).
  static bool get available => !kIsWeb && Platform.isWindows && !Platform.environment.containsKey('FLUTTER_TEST');

  static bool _ringing = false;
  static Timer? _stopAfter;

  /// Whether the alarm sound is playing (touching the app silences it).
  static bool get ringing => _ringing;

  static Future<void> _call(String method, [Object? arguments]) async {
    if (!available) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on Object catch (e) {
      debugPrint('Window call $method failed: $e');
    }
  }

  /// "Manter na bandeja": closing the window hides it; the tray icon opens it, the mini calendar, or quits.
  static Future<void> configureTray({
    required bool enabled,
    required String tooltip,
    required String open,
    required String mini,
    required String quit,
  }) => _call('configureTray', {'enabled': enabled, 'tooltip': tooltip, 'open': open, 'mini': mini, 'quit': quit});

  /// Plays the "Despertador": [loop] rings until [stopAlarm] (at most [maxRing]), else once.
  static Future<void> playAlarm({required bool loop, Duration maxRing = const Duration(minutes: 3)}) async {
    if (!available) return;
    _ringing = true;
    _stopAfter?.cancel();
    _stopAfter = Timer(loop ? maxRing : const Duration(seconds: 4), () => _ringing = false);
    if (loop) _stopAfter = Timer(maxRing, () => unawaited(stopAlarm()));
    await _call('playAlarm', loop);
  }

  static Future<void> stopAlarm() async {
    _stopAfter?.cancel();
    if (!_ringing) return;
    _ringing = false;
    await _call('stopAlarm');
  }

  /// Brings the window back (from the tray or behind others).
  static Future<void> show() => _call('show');

  /// "Iniciar com o Windows": the app starts hidden in the tray when the user signs in.
  static Future<void> setAutostart(bool enabled) => _call('setAutostart', enabled);

  /// Whether the desktop mini calendar (windows/runner/mini_window.cpp) is open; the runner tells when
  /// it opens or closes, from the tray or its own ×.
  static final miniCalendarOpen = ValueNotifier<bool>(false);

  /// Opens or closes the mini calendar; open, it also comes back when the app starts.
  static Future<void> setMiniCalendar({required bool open}) async {
    miniCalendarOpen.value = open;
    await _call(open ? 'openMini' : 'closeMini');
  }

  /// Taps on the mini calendar that open the app ("open|2026-10-09|d" or "create|2026-10-09|d"; the
  /// runner shows the window first), and its opening and closing.
  static void listenWidgetActions(void Function(String action) onAction) {
    if (!available) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'widgetAction' when call.arguments is String:
          onAction(call.arguments as String);
        case 'miniOpen' when call.arguments is bool:
          miniCalendarOpen.value = call.arguments as bool;
      }
    });
    unawaited(
      _channel.invokeMethod<bool>('isMiniOpen').then((open) => miniCalendarOpen.value = open ?? false, onError: (Object e) => debugPrint('$e')),
    );
  }
}
