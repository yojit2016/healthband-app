import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';
import '../providers/index.dart';
import '../widgets/metric_card.dart';
import '../widgets/system_pulse.dart';
import '../widgets/emergency_overlay.dart';
import '../services/foreground_service.dart';
import 'login_screen.dart';
import 'medications_tab.dart';
import 'contacts_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

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
  void initState() {
    super.initState();
    ForegroundService.start();
  }

  Future<void> _logout() async {
    await ForegroundService.stop();
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, anim1, anim2) => const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Scaffold(
            appBar: _buildAppBar(),
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

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.monitor_heart,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Health Band'),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Logout',
          onPressed: _logout,
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
      ],
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

// ── Dashboard Tab (Live Data) ────────────────────────────────────────────────

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final emergencyState = ref.watch(emergencyProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final data = state.latest;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    bool showOffline = state.isOffline;
    bool showServerError = state.isServerError;
    bool showMockData = state.isMockData;

    // 6. ADD FINAL SAFETY CHECK
    // If real data exists (isLive == true) and was recently updated, force hide all errors.
    if (data != null && state.lastUpdated != null) {
      final isRecent = DateTime.now().difference(state.lastUpdated!).inSeconds < 15;
      if (isRecent && state.isLive) {
        showOffline = false;
        showServerError = false;
        showMockData = false;
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Header row with pulse, time, & audio button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SystemPulse(isLive: state.isLive),
                    if (state.lastUpdated != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${state.lastUpdated!.hour.toString().padLeft(2, '0')}:${state.lastUpdated!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(audioSettingsProvider.notifier).toggle(),
                icon: Icon(
                  ref.watch(audioSettingsProvider)
                      ? Icons.volume_up
                      : Icons.volume_off,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  ref.watch(audioSettingsProvider) ? 'Audio: ON' : 'Audio: OFF',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subtle offline indicator
          if (showOffline)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Device offline',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else if (showServerError)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Unable to connect to server',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
          if (showMockData)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Mock Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Grid of metrics natively replaced by Row
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Heart Rate',
                    value: data.heartRate.toString(),
                    unit: 'bpm',
                    icon: Icons.favorite,
                    accentColor: AppColors.error,
                    sparklineData: state.heartRateHistory,
                    status: data.isNormal ? 'Normal' : 'High',
                    statusColor: data.isNormal
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Blood Oxygen',
                    value: data.spo2.toString(),
                    unit: '%',
                    icon: Icons.air,
                    accentColor: AppColors.primary,
                    sparklineData: state.spo2History,
                    status: data.spo2 >= 95 ? 'Normal' : 'Low',
                    statusColor: data.spo2 >= 95
                        ? AppColors.success
                        : AppColors.warning,
                    minY: 90,
                    maxY: 100,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Emergency event section
          const Text(
            'Recent Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (emergencyState.history.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No recent alerts',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...emergencyState.history.map((alert) {
              return _AlertTile(
                title: alert.summary.isEmpty
                    ? 'Unknown Anomaly'
                    : alert.summary,
                time: alert.timestamp,
                eventId: alert.eventId,
                isCritical: alert.hasCriticalOxygen || alert.types.isEmpty,
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.title,
    required this.time,
    required this.eventId,
    this.isCritical = false,
  });

  final String title;
  final DateTime time;
  final String eventId;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ID: $eventId',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDisabled,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      _formatTime(time),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
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
