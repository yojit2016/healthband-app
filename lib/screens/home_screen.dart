import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';
import '../widgets/emergency_overlay.dart';
import 'dashboard_screen.dart';
import 'medications_tab.dart';
import 'contacts_tab.dart';

/// Root shell screen that hosts the bottom-navigation tabs.
/// Emergency overlay is global and controlled by Riverpod state.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Placeholder pages — replace each with real screen widgets as developed
  static const List<_TabConfig> _tabs = [
    _TabConfig(
      label: 'Dashboard',
      icon: Icons.monitor_heart_outlined,
      activeIcon: Icons.monitor_heart,
    ),
    _TabConfig(
      label: 'Medications',
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services,
    ),
    _TabConfig(
      label: 'Contacts',
      icon: Icons.contacts_outlined,
      activeIcon: Icons.contacts,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            body: _currentIndex == 0
                ? const DashboardTab()
                : _currentIndex == 1
                ? const MedicationsTab()
                : const ContactsTab(),
            bottomNavigationBar: _buildBottomNav(),
          ),
          const EmergencyOverlay(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
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
