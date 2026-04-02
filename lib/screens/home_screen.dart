import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';
import 'medications_tab.dart';
import 'contacts_tab.dart';
import 'notifications_tab.dart';


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
    _TabConfig(label: 'Medications',  icon: Icons.medical_services_outlined, activeIcon: Icons.medical_services),
    _TabConfig(label: 'Contacts',   icon: Icons.contacts_outlined,      activeIcon: Icons.contacts),
    _TabConfig(label: 'Alerts',  icon: Icons.notifications_none_outlined,       activeIcon: Icons.notifications),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? const Center(child: Text("Dashboard goes here"))
          : _currentIndex == 1
              ? const MedicationsTab()
              : _currentIndex == 2
                  ? const ContactsTab()
                  : const NotificationsTab(),
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
