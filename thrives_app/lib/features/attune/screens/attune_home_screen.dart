import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/audio/tone_generator.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';

enum AttuneMode { none, binaural, isochronic }

class _NatureSound {
  final String id;
  final String label;
  final IconData icon;
  // Asset path — add mp3/ogg files to assets/audio/nature/ to enable
  final String assetPath;

  const _NatureSound({
    required this.id,
    required this.label,
    required this.icon,
    required this.assetPath,
  });
}

const _natureSounds = [
  _NatureSound(
    id: 'rain',
    label: 'Rain',
    icon: Icons.grain_rounded,
    assetPath: 'assets/audio/nature/rain.mp3',
  ),
  _NatureSound(
    id: 'ocean',
    label: 'Ocean',
    icon: Icons.waves_rounded,
    assetPath: 'assets/audio/nature/ocean.mp3',
  ),
  _NatureSound(
    id: 'forest',
    label: 'Forest',
    icon: Icons.forest_rounded,
    assetPath: 'assets/audio/nature/forest.mp3',
  ),
  _NatureSound(
    id: 'river',
    label: 'River',
    icon: Icons.water_rounded,
    assetPath: 'assets/audio/nature/river.mp3',
  ),
  _NatureSound(
    id: 'thunder',
    label: 'Thunder',
    icon: Icons.thunderstorm_rounded,
    assetPath: 'assets/audio/nature/thunder.mp3',
  ),
  _NatureSound(
    id: 'wind',
    label: 'Wind',
    icon: Icons.air_rounded,
    assetPath: 'assets/audio/nature/wind.mp3',
  ),
];

class AttuneHomeScreen extends StatefulWidget {
  const AttuneHomeScreen({super.key});

  @override
  State<AttuneHomeScreen> createState() => _AttuneHomeScreenState();
}

class _AttuneHomeScreenState extends State<AttuneHomeScreen>
    with SessionTracking {
  // ── tone state ────────────────────────────────────────────────────────────
  AttuneMode _mode = AttuneMode.none;
  BrainwaveBand _band = BrainwaveBand.alpha;
  double _carrierHz = 200.0;
  bool _toneLoading = false;
  bool _tonePlaying = false;
  String? _toneError;

  // ── nature sounds ─────────────────────────────────────────────────────────
  final Set<String> _activeSounds = {};
  final Map<String, AudioPlayer> _naturePlayers = {};
  // Tracks which nature assets are actually present
  final Set<String> _availableSounds = {};

  // ── audio players ─────────────────────────────────────────────────────────
  final AudioPlayer _tonePlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _checkAvailableSounds();
  }

  @override
  void dispose() {
    _tonePlayer.dispose();
    for (final p in _naturePlayers.values) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAvailableSounds() async {
    // Nature sounds require bundled audio files.
    // Add them to assets/audio/nature/ and declare in pubspec.yaml.
    // For now all show as unavailable until files are present.
    // When files are added, remove this stub and just attempt playback.
    if (mounted) setState(() => _availableSounds.clear());
  }

  // ── tone playback ──────────────────────────────────────────────────────────

  Future<void> _startTone() async {
    if (_mode == AttuneMode.none) return;
    setState(() {
      _toneLoading = true;
      _toneError = null;
    });

    try {
      final band = _band;
      final carrier = _carrierHz;
      final beatHz = band.defaultBeatHz;

      AudioSource source;
      if (_mode == AttuneMode.binaural) {
        source = BinauralBeatSource(carrierHz: carrier, beatHz: beatHz);
      } else {
        source = IsochronicToneSource(carrierHz: carrier, beatHz: beatHz);
      }

      await _tonePlayer.setAudioSource(source, preload: true);
      await _tonePlayer.setLoopMode(LoopMode.one);
      await _tonePlayer.play();

      if (mounted) {
        final label = _mode == AttuneMode.binaural
            ? 'Binaural Beats — ${_band.label}'
            : 'Isochronic Tones — ${_band.label}';
        beginTracking(label, 'Attune');
        setState(() {
          _toneLoading = false;
          _tonePlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _toneLoading = false;
          _toneError = 'Could not start audio. Try again.';
        });
      }
    }
  }

  Future<void> _stopTone() async {
    await _tonePlayer.stop();
    if (mounted) setState(() => _tonePlaying = false);
  }

  Future<void> _restartTone() async {
    await _stopTone();
    await _startTone();
  }

  // ── nature playback ────────────────────────────────────────────────────────

  Future<void> _toggleNature(String id, String assetPath) async {
    if (_activeSounds.contains(id)) {
      await _naturePlayers[id]?.stop();
      _naturePlayers[id]?.dispose();
      _naturePlayers.remove(id);
      if (mounted) setState(() => _activeSounds.remove(id));
    } else {
      final player = AudioPlayer();
      try {
        await player.setAsset(assetPath);
        await player.setLoopMode(LoopMode.one);
        await player.play();
        _naturePlayers[id] = player;
        if (mounted) setState(() => _activeSounds.add(id));
      } catch (_) {
        player.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio file not found: $assetPath'),
              backgroundColor: AppColors.surface,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attune',
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 6),
                    const Text(
                      'Sound and frequency tools for nervous system entrainment.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Mode selector ───────────────────────────────────────
                  _SectionLabel('Type'),
                  const SizedBox(height: 12),
                  _ModeRow(
                    selected: _mode,
                    onSelect: (m) {
                      if (_tonePlaying) _stopTone();
                      setState(() => _mode = m);
                    },
                  ),

                  if (_mode == AttuneMode.binaural) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.headphones_rounded,
                              color: AppColors.amber, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Binaural beats require stereo headphones to work.',
                              style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_mode != AttuneMode.none) ...[
                    const SizedBox(height: 24),

                    // ── Band selector ─────────────────────────────────────
                    _SectionLabel('Frequency band'),
                    const SizedBox(height: 12),
                    _BandGrid(
                      selected: _band,
                      onSelect: (b) {
                        setState(() => _band = b);
                        if (_tonePlaying) _restartTone();
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Carrier frequency ─────────────────────────────────
                    _SectionLabel('Carrier frequency'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('100 Hz',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            value: _carrierHz,
                            min: 100,
                            max: 400,
                            divisions: 30,
                            activeColor: const Color(0xFF7B68EE),
                            inactiveColor: AppColors.surfaceVariant,
                            onChanged: (v) {
                              setState(() => _carrierHz = v);
                              if (_tonePlaying) _restartTone();
                            },
                          ),
                        ),
                        Text('${_carrierHz.round()} Hz',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Play/stop ─────────────────────────────────────────
                    if (_toneError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_toneError!,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13)),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _toneLoading
                            ? null
                            : (_tonePlaying ? _stopTone : _startTone),
                        icon: _toneLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background,
                                ),
                              )
                            : Icon(_tonePlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded),
                        label: Text(
                          _toneLoading
                              ? 'Generating…'
                              : (_tonePlaying ? 'Stop' : 'Play'),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _tonePlaying
                              ? AppColors.surfaceVariant
                              : const Color(0xFF7B68EE),
                          foregroundColor: _tonePlaying
                              ? AppColors.textPrimary
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    if (_tonePlaying) ...[
                      const SizedBox(height: 12),
                      _PlayingBadge(band: _band, mode: _mode),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // ── Nature sounds ─────────────────────────────────────────
                  _SectionLabel('Nature sounds'),
                  const SizedBox(height: 4),
                  const Text(
                    'Layer ambient sound over any tone, or use on its own.',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _NatureSoundGrid(
                    sounds: _natureSounds,
                    active: _activeSounds,
                    available: _availableSounds,
                    onTap: _toggleNature,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nature sound files can be added to assets/audio/nature/ — '
                    'see the project README.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final AttuneMode selected;
  final ValueChanged<AttuneMode> onSelect;

  const _ModeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in [
          (AttuneMode.none, 'None', Icons.volume_off_rounded),
          (AttuneMode.binaural, 'Binaural', Icons.headphones_rounded),
          (AttuneMode.isochronic, 'Isochronic', Icons.graphic_eq_rounded),
        ]) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected == entry.$1
                      ? const Color(0xFF7B68EE).withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == entry.$1
                        ? const Color(0xFF7B68EE)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(entry.$3,
                        color: selected == entry.$1
                            ? const Color(0xFF7B68EE)
                            : AppColors.textMuted,
                        size: 20),
                    const SizedBox(height: 4),
                    Text(
                      entry.$2,
                      style: TextStyle(
                        color: selected == entry.$1
                            ? const Color(0xFF7B68EE)
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (entry.$1 != AttuneMode.isochronic) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _BandGrid extends StatelessWidget {
  final BrainwaveBand selected;
  final ValueChanged<BrainwaveBand> onSelect;

  const _BandGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final band in BrainwaveBand.values) ...[
          GestureDetector(
            onTap: () => onSelect(band),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected == band
                    ? const Color(0xFF7B68EE).withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == band
                      ? const Color(0xFF7B68EE)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${band.label}  ·  ${band.range}',
                          style: TextStyle(
                            color: selected == band
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          band.use,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${band.defaultBeatHz.toStringAsFixed(1)} Hz beat',
                    style: TextStyle(
                      color: selected == band
                          ? const Color(0xFF7B68EE)
                          : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selected == band)
                    const Icon(Icons.check_rounded,
                        color: Color(0xFF7B68EE), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _NatureSoundGrid extends StatelessWidget {
  final List<_NatureSound> sounds;
  final Set<String> active;
  final Set<String> available;
  final void Function(String id, String assetPath) onTap;

  const _NatureSoundGrid({
    required this.sounds,
    required this.active,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: sounds.map((s) {
        final isActive = active.contains(s.id);
        final isAvailable = available.contains(s.id);
        return GestureDetector(
          onTap: () => onTap(s.id, s.assetPath),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? AppColors.teal : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  s.icon,
                  color: isActive
                      ? AppColors.teal
                      : (isAvailable
                          ? AppColors.textSecondary
                          : AppColors.textMuted),
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  s.label,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.teal
                        : (isAvailable
                            ? AppColors.textSecondary
                            : AppColors.textMuted),
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (!isAvailable)
                  const Text(
                    'file needed',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 9),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PlayingBadge extends StatefulWidget {
  final BrainwaveBand band;
  final AttuneMode mode;
  const _PlayingBadge({required this.band, required this.mode});

  @override
  State<_PlayingBadge> createState() => _PlayingBadgeState();
}

class _PlayingBadgeState extends State<_PlayingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF7B68EE)
                .withValues(alpha: 0.08 + _pulse.value * 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF7B68EE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.mode == AttuneMode.binaural ? "Binaural" : "Isochronic"} · '
                '${widget.band.label} · ${widget.band.defaultBeatHz.toStringAsFixed(1)} Hz',
                style: const TextStyle(
                  color: Color(0xFF7B68EE),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
