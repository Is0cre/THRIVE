import 'package:flutter/material.dart';
import '../../../core/storage/session_log.dart';
import '../../../core/theme/app_theme.dart';
import 'crisis_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onResetOnboarding;
  const SettingsScreen({super.key, required this.onResetOnboarding});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all data?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will delete your check-in history and session log. '
          'Your safe place description will also be cleared.\n\n'
          'This cannot be undone.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SessionLog.clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data cleared.'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            // About
            _Section('About'),
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THRIVES',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Version 0.1.0',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Built from lived experience. For everyone who is still here.\n\n'
                    'Open source. No ads. No data collection. Free forever.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'github.com/Is0cre/THRIVE',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Safety
            _Section('Safety'),
            _TileButton(
              icon: Icons.emergency_rounded,
              iconColor: AppColors.danger,
              label: 'Crisis resources',
              subtitle: 'Crisis lines for Malta and internationally',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrisisScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // Privacy
            _Section('Privacy'),
            _InfoCard(
              child: const Text(
                'THRIVES collects no data. Zero analytics. Zero crash reporting. '
                'Zero network requests from the core app.\n\n'
                'Everything you enter — check-ins, session history, your safe place '
                'description — lives only on this device. '
                'We cannot provide your data to third parties, law enforcement, '
                'or intelligence agencies because we do not have it.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Disclaimer
            _Section('Disclaimer'),
            _InfoCard(
              child: const Text(
                'THRIVES is a wellness tool, not a replacement for therapy or '
                'medical care. It does not diagnose, assess, or treat any condition.\n\n'
                'If you are in crisis, please reach out to a professional or '
                'use the crisis resources above.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Psychology advisors
            _Section('Advisory'),
            _InfoCard(
              child: const Text(
                'Psychology advisors — coming soon.\n\n'
                'THRIVES is seeking named psychology professionals to review '
                'content and protocols. Advisory credits will appear here.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data
            _Section('Your data'),
            _TileButton(
              icon: Icons.delete_outline_rounded,
              iconColor: AppColors.danger,
              label: 'Clear session history',
              subtitle: 'Deletes check-ins and session log',
              onTap: () => _confirmClearData(context),
            ),

            const SizedBox(height: 8),

            _TileButton(
              icon: Icons.refresh_rounded,
              iconColor: AppColors.textMuted,
              label: 'Redo onboarding',
              subtitle: 'Reset your profile questionnaire',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Redo onboarding?',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text(
                      'Your profile will be reset and you\'ll go through the '
                      'questionnaire again. Your history is not affected.',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset',
                            style: TextStyle(color: AppColors.teal)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) widget.onResetOnboarding();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _TileButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _TileButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
