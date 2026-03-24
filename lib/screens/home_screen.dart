import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';

/// Root shell screen that hosts the bottom-navigation tabs.
/// Business logic will be added per-tab screen later.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Placeholder pages — replace each with real screen widgets as developed
  static const List<_TabConfig> _tabs = [
    _TabConfig(label: 'Dashboard', icon: Icons.monitor_heart_outlined, activeIcon: Icons.monitor_heart),
    _TabConfig(label: 'Activity',  icon: Icons.directions_run_outlined, activeIcon: Icons.directions_run),
    _TabConfig(label: 'Reports',   icon: Icons.bar_chart_outlined,      activeIcon: Icons.bar_chart),
    _TabConfig(label: 'Settings',  icon: Icons.settings_outlined,       activeIcon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _PlaceholderPage(tabIndex: _currentIndex, label: _tabs[_currentIndex].label),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                activeIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Simple placeholder page shown while screens are not yet implemented.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.tabIndex, required this.label});

  final int tabIndex;
  final String label;

  static const List<IconData> _icons = [
    Icons.monitor_heart,
    Icons.directions_run,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(89),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(_icons[tabIndex], size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Screen coming soon',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabConfig {
  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
