import 'package:flutter/foundation.dart';

/// Chỉ dùng khi debug: ghi lại các sự kiện tap/callback để tìm thao tác gây assertion (mouse_tracker).
class DebugTapLogger {
  DebugTapLogger._();

  static const int _maxEntries = 40;
  static final List<String> _entries = [];
  static int _seq = 0;

  static void log(String message) {
    if (!kDebugMode) return;
    _seq++;
    final line = '[$_seq] ${DateTime.now().toIso8601String().substring(11, 23)} $message';
    _entries.add(line);
    if (_entries.length > _maxEntries) _entries.removeAt(0);
    debugPrint('🔵 $line');
  }

  static void dump(String prefix) {
    if (!kDebugMode) return;
    debugPrint('$prefix === DebugTapLogger (last ${_entries.length}) ===');
    for (final e in _entries) {
      debugPrint('  $e');
    }
    debugPrint('$prefix === end ===');
  }

  static List<String> get entries => List.unmodifiable(_entries);
}
