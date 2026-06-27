import 'dart:async';
import 'package:flutter/services.dart';

// Handles sensitive-field clipboard clearing.
// Android 10+ silently drops Clipboard.setData from a background process,
// so clearing is attempted twice:
//   1. Via a 30s timer — works if the user is still in the app.
//   2. Via onResumed() — catches the case where the app was backgrounded
//      when the timer fired and the write was dropped.
class ClipboardService {
  static DateTime? _sensitiveCopyTime;
  static Timer? _timer;
  static Duration _clearDelay = const Duration(seconds: 45);

  static void configure(int seconds) =>
      _clearDelay = Duration(seconds: seconds);

  static int get clearDelaySeconds => _clearDelay.inSeconds;

  static void copySensitive(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _sensitiveCopyTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_clearDelay, () {
      Clipboard.setData(const ClipboardData(text: ''));
      // Do NOT null _sensitiveCopyTime here — if Android silently dropped
      // this background write, onResumed() needs the timestamp to retry.
    });
  }

  // Call this from the app lifecycle resumed handler.
  static void onResumed() {
    final t = _sensitiveCopyTime;
    if (t == null) return;
    if (DateTime.now().difference(t) >= _clearDelay) {
      Clipboard.setData(const ClipboardData(text: ''));
      _sensitiveCopyTime = null;
      _timer?.cancel();
      _timer = null;
    }
  }
}
