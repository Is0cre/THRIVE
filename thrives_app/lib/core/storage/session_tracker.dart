import 'package:flutter/material.dart';
import 'session_log.dart';
import 'tier_service.dart';

/// Mixin that adds automatic session logging to any tool screen's State.
///
/// Usage:
///   class _MyScreenState extends State with SessionTracking {
///     void _start() {
///       beginTracking('Tool Name', 'Category');
///       // ...
///     }
///   }
///
/// The session is logged automatically in dispose() if at least 10 seconds
/// have elapsed since beginTracking() was called. Nothing to wire up at the
/// end — screens that end abruptly (back button, emergency) are still logged.
///
/// Minimum 10 second threshold prevents logging accidental screen opens.
mixin SessionTracking<T extends StatefulWidget> on State<T> {
  String? _trackTool;
  String? _trackCategory;
  DateTime? _trackStart;

  /// Call when the user actively starts using a tool.
  /// Safe to call multiple times — restarts the timer.
  void beginTracking(String tool, String category) {
    _trackTool = tool;
    _trackCategory = category;
    _trackStart = DateTime.now();
  }

  /// Flush without waiting for dispose — call when a session ends cleanly
  /// (e.g., timer complete, user taps stop) if you want more accurate duration.
  void endTracking() {
    _flush();
  }

  @override
  void dispose() {
    _flush();
    super.dispose();
  }

  void _flush() {
    final tool = _trackTool;
    final category = _trackCategory;
    final start = _trackStart;
    if (tool == null || start == null) return;
    _trackTool = null;
    _trackStart = null;
    final secs = DateTime.now().difference(start).inSeconds;
    if (secs < 10) return;
    // Fire and forget — local write, completes in <1ms
    SessionLog.logSession(SessionEntry(
      tool: tool,
      category: category ?? 'General',
      timestamp: start,
      durationSeconds: secs,
    )).then((_) => TierService.recheck());
  }
}
