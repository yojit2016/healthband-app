import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/foreground_service.dart';
import 'services/notification_service.dart';
import 'storage/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications (timezone + channels + POST_NOTIFICATIONS request)
  await NotificationService.init();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await HiveService.init();
  ForegroundService.init();

  final bool isLoggedIn = HiveService.getLoginState();

  runApp(ProviderScope(child: HealthBandApp(isLoggedIn: isLoggedIn)));
}

class HealthBandApp extends StatelessWidget {
  const HealthBandApp({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Band',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _ExactAlarmPermissionGuard(
        child: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}

/// On Android 12+ checks whether SCHEDULE_EXACT_ALARM is granted.
/// If not, shows a non-dismissible bottom banner with a button to fix it.
class _ExactAlarmPermissionGuard extends StatefulWidget {
  const _ExactAlarmPermissionGuard({required this.child});
  final Widget child;

  @override
  State<_ExactAlarmPermissionGuard> createState() =>
      _ExactAlarmPermissionGuardState();
}

class _ExactAlarmPermissionGuardState
    extends State<_ExactAlarmPermissionGuard> with WidgetsBindingObserver {
  bool _permissionGranted = true; // assume granted until checked

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when the user returns from system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.canScheduleExactAlarms();
    if (mounted && granted != _permissionGranted) {
      setState(() => _permissionGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_permissionGranted) _buildPermissionBanner(context),
      ],
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Material(
          elevation: 8,
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2340),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_off, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allow Exact Alarms',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Required for medication reminders to work when app is closed.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await NotificationService.openExactAlarmSettings();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Fix', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
