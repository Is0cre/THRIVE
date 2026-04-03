import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/regulate/screens/panic_screen.dart';

// CLINICAL SAFETY — Emergency button
// What this does: Always-visible FAB that immediately launches the panic
//   sequence (physiological sigh × 3) without requiring navigation or
//   decision-making from the user.
// Why it exists: A person in acute distress cannot navigate. One tap, no
//   menus, no decisions, immediate intervention. Uses rootNavigator so it
//   works from any screen regardless of navigation stack depth.
// What happens if removed: Person in crisis has no immediate intervention
//   available.
// Informed by: Marit Leito, clinical advisor.

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key});

  static void trigger(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => const PanicScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => trigger(context),
      backgroundColor: AppColors.danger,
      foregroundColor: Colors.white,
      tooltip: 'Emergency grounding',
      heroTag: 'emergency_fab',
      child: const Icon(Icons.anchor_rounded, size: 28),
    );
  }
}
