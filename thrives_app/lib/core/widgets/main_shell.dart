import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/attune/screens/attune_home_screen.dart';
import '../../features/build/screens/build_home_screen.dart';
import '../../features/monitor/screens/monitor_home_screen.dart';
import '../../features/process/screens/process_home_screen.dart';
import '../../features/reflect/screens/reflect_home_screen.dart';
import '../../features/regulate/screens/regulate_home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'emergency_button.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onResetOnboarding;

  const MainShell({
    super.key,
    required this.onResetOnboarding,
  });

  @override
  State<MainShell> createState() => _MainShellState();

  /// Switches to the Regulate tab from anywhere.
  /// Called after the panic sequence completes to land on Regulate tools.
  static void emergencyJumpToRegulate(BuildContext context) {
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    _MainShellState._current?.jumpToRegulate();
  }
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static _MainShellState? _current;

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  void jumpToRegulate() => setState(() => _index = 0);

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          onResetOnboarding: widget.onResetOnboarding,
        ),
      ),
    );
  }

  static const _screens = [
    RegulateHomeScreen(),
    ProcessHomeScreen(),
    AttuneHomeScreen(),
    MonitorHomeScreen(),
    BuildHomeScreen(),
    ReflectHomeScreen(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.waves_rounded, label: 'Regulate'),
    _NavItem(icon: Icons.swap_horiz_rounded, label: 'Process'),
    _NavItem(icon: Icons.music_note_rounded, label: 'Attune'),
    _NavItem(icon: Icons.favorite_border_rounded, label: 'Monitor'),
    _NavItem(icon: Icons.eco_rounded, label: 'Build'),
    _NavItem(icon: Icons.auto_stories_rounded, label: 'Reflect'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          // Settings button — top right, always accessible
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: AppColors.textMuted,
              iconSize: 22,
              tooltip: 'Settings',
              onPressed: _openSettings,
            ),
          ),
        ],
      ),
      floatingActionButton: const EmergencyButton(),
      bottomNavigationBar: _ThriveNavBar(
        currentIndex: _index,
        items: _navItems,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _ThriveNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _ThriveNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          color: currentIndex == i
                              ? AppColors.teal
                              : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            color: currentIndex == i
                                ? AppColors.teal
                                : AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: currentIndex == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
