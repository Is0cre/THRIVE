import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import '../../../core/storage/session_tracker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';

enum EmdrMode { visual, audio, tactile, visualAudio, visualTactile, all }

enum EmdrSpeed { slow, medium, fast }

// Session length options in minutes; 0 = unlimited
const _sessionOptions = [0, 5, 10, 15, 20, 30];

class EmdrScreen extends StatefulWidget {
  const EmdrScreen({super.key});

  @override
  State<EmdrScreen> createState() => _EmdrScreenState();
}

class _EmdrScreenState extends State<EmdrScreen>
    with TickerProviderStateMixin, SessionTracking {
  // ── settings ──────────────────────────────────────────────────────────────
  EmdrMode _mode = EmdrMode.visual;
  EmdrSpeed _speed = EmdrSpeed.medium;
  int _sessionMinutes = 0;
  double _dotSize = 28;
  Color _dotColor = AppColors.teal;

  // ── state ─────────────────────────────────────────────────────────────────
  bool _running = false;
  bool _showSettings = true; // start on settings before first run
  int _sessionSecondsLeft = 0;
  Timer? _sessionTimer;

  // ── animation ─────────────────────────────────────────────────────────────
  late AnimationController _dotController;
  late Animation<double> _dotAnimation; // 0.0 = left edge, 1.0 = right edge
  // _goingRight tracks direction for audio cue future use

  // ── audio ─────────────────────────────────────────────────────────────────
  final AudioPlayer _leftPlayer = AudioPlayer();
  final AudioPlayer _rightPlayer = AudioPlayer();
  // _audioReady: reserved for when audio assets are bundled

  // ── vibration ────────────────────────────────────────────────────────────
  bool _canVibrate = false;

  // ── colour presets ───────────────────────────────────────────────────────
  final _colorOptions = const [
    AppColors.teal,
    AppColors.amber,
    Color(0xFF8B6FD4),
    Color(0xFF4A9EDA),
    Colors.white,
  ];

  int get _durationMs {
    switch (_speed) {
      case EmdrSpeed.slow:
        return 2000;
      case EmdrSpeed.medium:
        return 1200;
      case EmdrSpeed.fast:
        return 700;
    }
  }

  bool get _useVisual =>
      _mode == EmdrMode.visual ||
      _mode == EmdrMode.visualAudio ||
      _mode == EmdrMode.visualTactile ||
      _mode == EmdrMode.all;

  bool get _useTactile =>
      _mode == EmdrMode.tactile ||
      _mode == EmdrMode.visualTactile ||
      _mode == EmdrMode.all;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _durationMs),
    );
    _dotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOut),
    );
    _dotController.addStatusListener(_onDotStatus);
    _initAudio();
    _checkVibration();
  }

  Future<void> _initAudio() async {
    // Audio assets will be bundled in a future session.
    // just_audio players are initialised and ready.
  }

  Future<void> _checkVibration() async {
    _canVibrate = (await Vibration.hasVibrator()) == true;
  }

  @override
  void dispose() {
    _dotController.removeStatusListener(_onDotStatus);
    _dotController.dispose();
    _sessionTimer?.cancel();
    _leftPlayer.dispose();
    _rightPlayer.dispose();
    super.dispose();
  }

  void _onDotStatus(AnimationStatus status) {
    if (!_running) return;
    if (status == AnimationStatus.completed) {
      _triggerSide(right: false);
      _dotController.reverse();
    } else if (status == AnimationStatus.dismissed) {
      _triggerSide(right: true);
      _dotController.forward();
    }
  }

  void _triggerSide({required bool right}) {
    if (_useTactile && _canVibrate) {
      Vibration.vibrate(duration: 40, amplitude: 80);
    }
    // Audio bilateral — left/right channel cue
    // Actual stereo panning requires just_audio's AudioSource with channel routing.
    // For now a haptic distinguishes sides until audio assets are ready.
    if (!_useTactile) {
      // Light haptic as audio stand-in when no vibration mode selected
      HapticFeedback.selectionClick();
    }
  }

  void _start() {
    beginTracking('Bilateral Stimulation', 'Process');
    _dotController.duration = Duration(milliseconds: _durationMs);
    setState(() {
      _running = true;
      _showSettings = false;
      if (_sessionMinutes > 0) {
        _sessionSecondsLeft = _sessionMinutes * 60;
      }
    });
    _triggerSide(right: true);
    _dotController.forward(from: 0);
    if (_sessionMinutes > 0) {
      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _sessionSecondsLeft--;
          if (_sessionSecondsLeft <= 0) {
            _stop();
            _showCompletionMessage();
          }
        });
      });
    }
  }

  void _stop() {
    _dotController.stop();
    _sessionTimer?.cancel();
    if (mounted) setState(() => _running = false);
  }

  void _showCompletionMessage() {
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Session complete',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Take a moment. Notice what came up, if anything.\n\n'
          'There is no right way to feel.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  String get _sessionDisplay {
    final m = _sessionSecondsLeft ~/ 60;
    final s = _sessionSecondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilateral Stimulation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_showSettings)
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Settings',
              onPressed: () {
                _stop();
                setState(() => _showSettings = true);
              },
            ),
        ],
      ),
      floatingActionButton: const EmergencyButton(),
      body: SafeArea(
        child: _showSettings ? _buildSettings() : _buildSession(),
      ),
    );
  }

  // ── Settings panel ─────────────────────────────────────────────────────────

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
      children: [
        _SettingsSection('Mode'),
        _ModeSelector(selected: _mode, onSelect: (m) => setState(() => _mode = m)),
        const SizedBox(height: 24),

        _SettingsSection('Speed'),
        _SpeedSelector(selected: _speed, onSelect: (s) => setState(() => _speed = s)),
        const SizedBox(height: 24),

        _SettingsSection('Session length'),
        _SessionSelector(
            selected: _sessionMinutes,
            onSelect: (m) => setState(() => _sessionMinutes = m)),
        const SizedBox(height: 24),

        if (_useVisual) ...[
          _SettingsSection('Dot size'),
          _SizeSlider(
            value: _dotSize,
            onChanged: (v) => setState(() => _dotSize = v),
          ),
          const SizedBox(height: 24),
          _SettingsSection('Dot colour'),
          _ColorPicker(
            colors: _colorOptions,
            selected: _dotColor,
            onSelect: (c) => setState(() => _dotColor = c),
          ),
          const SizedBox(height: 24),
        ],

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _start,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EDA),
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            child: const Text('Begin session'),
          ),
        ),
      ],
    );
  }

  // ── Session panel ─────────────────────────────────────────────────────────

  Widget _buildSession() {
    return Column(
      children: [
        // Session timer
        if (_sessionMinutes > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _sessionDisplay,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),

        // Bilateral dot area
        if (_useVisual)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Track line
                    Positioned(
                      left: 24,
                      right: 24,
                      child: Container(
                        height: 1,
                        color: AppColors.surfaceVariant,
                      ),
                    ),
                    // Moving dot
                    AnimatedBuilder(
                      animation: _dotAnimation,
                      builder: (context, _) {
                        final usableWidth = trackWidth - 48 - _dotSize;
                        final left = 24 + (_dotAnimation.value * usableWidth);
                        return Positioned(
                          left: left,
                          child: Container(
                            width: _dotSize,
                            height: _dotSize,
                            decoration: BoxDecoration(
                              color: _dotColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _dotColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          )
        else
          const Spacer(),

        // Audio/tactile only — just show the rhythm
        if (!_useVisual) ...[
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _dotAnimation,
                builder: (context, _) {
                  final pulse = math.sin(_dotAnimation.value * math.pi);
                  return Opacity(
                    opacity: 0.3 + pulse * 0.4,
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF4A9EDA),
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
          child: Column(
            children: [
              // Mode chips
              Wrap(
                spacing: 8,
                children: [
                  _ModeChip(label: _modeName, color: const Color(0xFF4A9EDA)),
                  _ModeChip(label: _speedName, color: AppColors.textMuted),
                  if (_sessionMinutes > 0)
                    _ModeChip(
                        label: '${_sessionMinutes}m',
                        color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _running ? _stop : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: _running
                        ? AppColors.surfaceVariant
                        : const Color(0xFF4A9EDA),
                    foregroundColor: _running
                        ? AppColors.textPrimary
                        : AppColors.background,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  child: Text(_running ? 'Pause' : 'Resume'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _modeName {
    switch (_mode) {
      case EmdrMode.visual:
        return 'Visual';
      case EmdrMode.audio:
        return 'Audio';
      case EmdrMode.tactile:
        return 'Tactile';
      case EmdrMode.visualAudio:
        return 'Visual + Audio';
      case EmdrMode.visualTactile:
        return 'Visual + Tactile';
      case EmdrMode.all:
        return 'Visual + Audio + Tactile';
    }
  }

  String get _speedName {
    switch (_speed) {
      case EmdrSpeed.slow:
        return 'Slow';
      case EmdrSpeed.medium:
        return 'Medium';
      case EmdrSpeed.fast:
        return 'Fast';
    }
  }
}

// ─── Settings widgets ─────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label;
  const _SettingsSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final EmdrMode selected;
  final ValueChanged<EmdrMode> onSelect;

  const _ModeSelector({required this.selected, required this.onSelect});

  static const _modes = [
    (EmdrMode.visual, 'Visual only', Icons.visibility_rounded),
    (EmdrMode.audio, 'Audio only', Icons.headphones_rounded),
    (EmdrMode.tactile, 'Tactile only', Icons.vibration_rounded),
    (EmdrMode.visualAudio, 'Visual + Audio', Icons.multitrack_audio_rounded),
    (EmdrMode.visualTactile, 'Visual + Tactile', Icons.touch_app_rounded),
    (EmdrMode.all, 'All three', Icons.layers_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final mode in _modes) ...[
          GestureDetector(
            onTap: () => onSelect(mode.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: selected == mode.$1
                    ? const Color(0xFF4A9EDA).withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected == mode.$1
                      ? const Color(0xFF4A9EDA)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(mode.$3,
                      color: selected == mode.$1
                          ? const Color(0xFF4A9EDA)
                          : AppColors.textMuted,
                      size: 18),
                  const SizedBox(width: 12),
                  Text(mode.$2,
                      style: TextStyle(
                          color: selected == mode.$1
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14)),
                  const Spacer(),
                  if (selected == mode.$1)
                    const Icon(Icons.check_rounded,
                        color: Color(0xFF4A9EDA), size: 16),
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

class _SpeedSelector extends StatelessWidget {
  final EmdrSpeed selected;
  final ValueChanged<EmdrSpeed> onSelect;

  const _SpeedSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in EmdrSpeed.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected == s
                      ? const Color(0xFF4A9EDA).withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == s
                        ? const Color(0xFF4A9EDA)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  s.name[0].toUpperCase() + s.name.substring(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected == s
                        ? const Color(0xFF4A9EDA)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          if (s != EmdrSpeed.fast) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _SessionSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _SessionSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in _sessionOptions)
          GestureDetector(
            onTap: () => onSelect(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected == m
                    ? const Color(0xFF4A9EDA).withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected == m
                      ? const Color(0xFF4A9EDA)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                m == 0 ? 'Open' : '${m}m',
                style: TextStyle(
                  color: selected == m
                      ? const Color(0xFF4A9EDA)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _SizeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, color: AppColors.textMuted, size: 10),
        Expanded(
          child: Slider(
            value: value,
            min: 16,
            max: 52,
            divisions: 9,
            activeColor: const Color(0xFF4A9EDA),
            inactiveColor: AppColors.surfaceVariant,
            onChanged: onChanged,
          ),
        ),
        const Icon(Icons.circle, color: AppColors.textSecondary, size: 22),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const _ColorPicker(
      {required this.colors, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final c in colors) ...[
          GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected == c ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected == c
                    ? [
                        BoxShadow(
                            color: c.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ModeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
