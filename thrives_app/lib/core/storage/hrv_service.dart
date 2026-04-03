import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single camera-PPG heart rate variability reading.
/// All values are stored locally and never leave the device.
class HrvReading {
  final DateTime timestamp;
  final double hr; // beats per minute
  final double rmssd; // ms — root mean square successive differences
  final double sdnn; // ms — standard deviation of NN intervals
  final int rrCount; // number of R-R intervals used in calculation

  const HrvReading({
    required this.timestamp,
    required this.hr,
    required this.rmssd,
    required this.sdnn,
    required this.rrCount,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'hr': hr,
        'rmssd': rmssd,
        'sdnn': sdnn,
        'rrCount': rrCount,
      };

  static HrvReading fromJson(Map<String, dynamic> j) => HrvReading(
        timestamp: DateTime.parse(j['timestamp'] as String),
        hr: (j['hr'] as num).toDouble(),
        rmssd: (j['rmssd'] as num).toDouble(),
        sdnn: (j['sdnn'] as num).toDouble(),
        rrCount: j['rrCount'] as int,
      );

  /// Qualitative HRV label for display — intentionally imprecise.
  /// These thresholds are population averages; individual baselines vary widely.
  /// Shown purely for self-awareness, never as clinical guidance.
  String get rmssdLabel {
    if (rmssd >= 40) return 'good recovery';
    if (rmssd >= 20) return 'moderate';
    return 'low — rest or regulate';
  }
}

class HrvService {
  HrvService._();

  static const _key = 'hrv_readings';
  static const _maxReadings = 90; // ~3 months of daily readings

  static Future<List<HrvReading>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => HrvReading.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList(); // newest first
  }

  static Future<void> save(HrvReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final List<dynamic> list = raw != null ? jsonDecode(raw) : [];
    list.add(reading.toJson());
    if (list.length > _maxReadings) {
      list.removeRange(0, list.length - _maxReadings);
    }
    await prefs.setString(_key, jsonEncode(list));
  }
}
