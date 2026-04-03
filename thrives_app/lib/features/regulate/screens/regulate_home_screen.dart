import 'package:flutter/material.dart';
import '../../../core/models/tolerance_state.dart';
import '../../../core/state/wot_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/emergency_button.dart';
import 'breathing_screen.dart';
import 'physiological_sigh_screen.dart';
import 'grounding_521_screen.dart';
import 'cold_water_screen.dart';
import 'safe_place_screen.dart';
import 'vagal_screen.dart';
import 'wim_hof_screen.dart';

class RegulateHomeScreen extends StatelessWidget {
  const RegulateHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ToleranceState?>(
      valueListenable: WoTScope.of(context),
      builder: (context, wot, _) {
        return Scaffold(
          floatingActionButton: const EmergencyButton(),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Regulate',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Immediate nervous system tools. Use these now.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (wot != null) ...[
                          const SizedBox(height: 14),
                          _StateChip(wot: wot),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionLabel('Breathing'),
                      const SizedBox(height: 12),
                      _ToolCard(
                        icon: Icons.air_rounded,
                        title: 'Box Breathing',
                        subtitle: '4-4-4-4 · Calm the nervous system',
                        color: AppColors.teal,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BreathingScreen(
                              mode: BreathingMode.box,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.air_rounded,
                        title: 'Physiological sigh',
                        subtitle: 'Double inhale + long exhale · Fastest reset',
                        color: AppColors.teal,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const PhysiologicalSighScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.nights_stay_rounded,
                        title: '4-7-8 Breathing',
                        subtitle: 'Sleep & acute anxiety',
                        color: AppColors.teal,
                        locked: wot != null && !wot.can4_7_8,
                        lockedReason: wot?.lockedReason,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BreathingScreen(
                              mode: BreathingMode.fourSevenEight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.waves_rounded,
                        title: 'Wim Hof Breathing',
                        subtitle: 'Guided round protocol',
                        color: AppColors.teal,
                        locked: wot != null && !wot.canWimHof,
                        lockedReason: wot?.lockedReason,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WimHofScreen()),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Grounding'),
                      const SizedBox(height: 12),
                      _ToolCard(
                        icon: Icons.filter_5_rounded,
                        title: '5-4-3-2-1 Grounding',
                        subtitle: 'Sensory anchoring — bring yourself back',
                        color: AppColors.amber,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Grounding521Screen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.water_drop_rounded,
                        title: 'Cold Water',
                        subtitle: 'Diving reflex · Vagal activation',
                        color: AppColors.amber,
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ColdWaterScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ToolCard(
                        icon: Icons.landscape_rounded,
                        title: 'Safe Place',
                        subtitle: 'Guided visualisation with ambient sound',
                        color: AppColors.amber,
                        locked: wot != null && !wot.canSafePlace,
                        lockedReason: wot?.lockedReason,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SafePlaceScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel('Vagal Nerve Activation'),
                      const SizedBox(height: 12),
                      _ToolCard(
                        icon: Icons.self_improvement_rounded,
                        title: 'Vagal Prompts',
                        subtitle: 'Humming · Gargling · Extended exhale',
                        color: const Color(0xFF8B6FD4),
                        locked: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VagalScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StateChip extends StatelessWidget {
  final ToleranceState wot;
  const _StateChip({required this.wot});

  @override
  Widget build(BuildContext context) {
    final Color chipColor;
    switch (wot) {
      case ToleranceState.hyperaroused:
        chipColor = const Color(0xFFDA3633);
      case ToleranceState.regulated:
        chipColor = AppColors.teal;
      case ToleranceState.hypoaroused:
        chipColor = const Color(0xFF6B8EAD);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chipColor,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          wot.displayName,
          style: TextStyle(
            color: chipColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

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

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool locked;
  final String? lockedReason;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.locked,
    required this.onTap,
    this.lockedReason,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? AppColors.textMuted : color;
    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: locked ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        locked && lockedReason != null
                            ? lockedReason!
                            : subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (locked)
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textMuted, size: 16)
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
