import 'dart:math' as math;
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

/// Frequency bands for binaural/isochronic entrainment.
enum BrainwaveBand {
  delta,
  theta,
  alpha,
  beta,
}

extension BrainwaveBandInfo on BrainwaveBand {
  String get label {
    switch (this) {
      case BrainwaveBand.delta:
        return 'Delta';
      case BrainwaveBand.theta:
        return 'Theta';
      case BrainwaveBand.alpha:
        return 'Alpha';
      case BrainwaveBand.beta:
        return 'Beta';
    }
  }

  String get range {
    switch (this) {
      case BrainwaveBand.delta:
        return '0.5–4 Hz';
      case BrainwaveBand.theta:
        return '4–8 Hz';
      case BrainwaveBand.alpha:
        return '8–14 Hz';
      case BrainwaveBand.beta:
        return '14–30 Hz';
    }
  }

  String get use {
    switch (this) {
      case BrainwaveBand.delta:
        return 'Deep sleep · Recovery';
      case BrainwaveBand.theta:
        return 'Deep relaxation · Processing';
      case BrainwaveBand.alpha:
        return 'Calm focus · Grounded';
      case BrainwaveBand.beta:
        return 'Alert · Present';
    }
  }

  /// Default beat frequency in Hz for this band
  double get defaultBeatHz {
    switch (this) {
      case BrainwaveBand.delta:
        return 2.0;
      case BrainwaveBand.theta:
        return 6.0;
      case BrainwaveBand.alpha:
        return 10.0;
      case BrainwaveBand.beta:
        return 20.0;
    }
  }
}

/// Generates a loopable WAV audio source for binaural beats.
///
/// Binaural beats: left ear gets [carrierHz], right ear gets [carrierHz + beatHz].
/// The brain perceives the difference as a beat at [beatHz].
/// Requires stereo headphones.
class BinauralBeatSource extends StreamAudioSource {
  final double carrierHz;
  final double beatHz;
  final double amplitude;

  static const int _sampleRate = 44100;
  static const int _durationSeconds = 30; // loop chunk length

  BinauralBeatSource({
    required this.carrierHz,
    required this.beatHz,
    this.amplitude = 0.28,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final bytes = _buildWav();
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }

  Uint8List _buildWav() {
    final numSamples = _sampleRate * _durationSeconds;
    // 44-byte WAV header + stereo int16 samples (2 channels × 2 bytes)
    final buf = ByteData(44 + numSamples * 4);
    _writeHeader(buf, numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      // Fade in/out over first/last 0.1s to avoid clicks
      final env = _envelope(i, numSamples);
      final left = env * amplitude * math.sin(2 * math.pi * carrierHz * t);
      final right =
          env * amplitude * math.sin(2 * math.pi * (carrierHz + beatHz) * t);
      buf.setInt16(44 + i * 4, _clamp(left), Endian.little);
      buf.setInt16(44 + i * 4 + 2, _clamp(right), Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  static void _writeHeader(ByteData d, int numSamples) {
    const channels = 2;
    const bitsPerSample = 16;
    final dataSize = numSamples * channels * (bitsPerSample ~/ 8);
    // RIFF
    _writeAscii(d, 0, 'RIFF');
    d.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(d, 8, 'WAVE');
    // fmt
    _writeAscii(d, 12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little); // PCM
    d.setUint16(22, channels, Endian.little);
    d.setUint32(24, _sampleRate, Endian.little);
    d.setUint32(
        28, _sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    d.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    d.setUint16(34, bitsPerSample, Endian.little);
    // data
    _writeAscii(d, 36, 'data');
    d.setUint32(40, dataSize, Endian.little);
  }

  static void _writeAscii(ByteData d, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      d.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  static int _clamp(double v) =>
      (v * 32767).round().clamp(-32768, 32767);

  static double _envelope(int i, int total) {
    const fadeFrames = 4410; // 0.1s
    if (i < fadeFrames) return i / fadeFrames;
    if (i > total - fadeFrames) return (total - i) / fadeFrames;
    return 1.0;
  }
}

/// Generates isochronic tones — works without headphones.
///
/// A single carrier frequency with amplitude pulsed at [beatHz].
/// Sharper than binaural, audible on speakers.
class IsochronicToneSource extends StreamAudioSource {
  final double carrierHz;
  final double beatHz;
  final double amplitude;

  static const int _sampleRate = 44100;
  static const int _durationSeconds = 30;

  IsochronicToneSource({
    required this.carrierHz,
    required this.beatHz,
    this.amplitude = 0.32,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final bytes = _buildWav();
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/wav',
    );
  }

  Uint8List _buildWav() {
    final numSamples = _sampleRate * _durationSeconds;
    // Mono: 1 channel × 2 bytes per sample
    final buf = ByteData(44 + numSamples * 2);
    _writeMonoHeader(buf, numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      // Pulse: rectangular gate at beat frequency (50% duty cycle)
      final gate = math.sin(math.pi * beatHz * t) >= 0 ? 1.0 : 0.0;
      // Smooth the gate edges slightly to reduce harshness
      final smoothedGate = gate * _softgate(i, beatHz);
      final env = BinauralBeatSource._envelope(i, numSamples);
      final sample =
          env * amplitude * smoothedGate * math.sin(2 * math.pi * carrierHz * t);
      buf.setInt16(44 + i * 2, BinauralBeatSource._clamp(sample), Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  double _softgate(int i, double beatHz) {
    // Apply a very short cosine fade at each gate transition to avoid clicks
    final t = i / _sampleRate;
    final phaseInCycle = (t * beatHz) % 1.0;
    const fadeWidth = 0.05; // 5% of cycle
    if (phaseInCycle < fadeWidth) {
      return (1 - math.cos(math.pi * phaseInCycle / fadeWidth)) / 2;
    }
    if (phaseInCycle > 0.5 - fadeWidth && phaseInCycle < 0.5) {
      return (1 + math.cos(math.pi * (phaseInCycle - (0.5 - fadeWidth)) / fadeWidth)) / 2;
    }
    if (phaseInCycle >= 0.5) return 0.0;
    return 1.0;
  }

  static void _writeMonoHeader(ByteData d, int numSamples) {
    const channels = 1;
    const bitsPerSample = 16;
    final dataSize = numSamples * channels * (bitsPerSample ~/ 8);
    BinauralBeatSource._writeAscii(d, 0, 'RIFF');
    d.setUint32(4, 36 + dataSize, Endian.little);
    BinauralBeatSource._writeAscii(d, 8, 'WAVE');
    BinauralBeatSource._writeAscii(d, 12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, channels, Endian.little);
    d.setUint32(24, _sampleRate, Endian.little);
    d.setUint32(
        28, _sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    d.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    d.setUint16(34, bitsPerSample, Endian.little);
    BinauralBeatSource._writeAscii(d, 36, 'data');
    d.setUint32(40, dataSize, Endian.little);
  }
}
