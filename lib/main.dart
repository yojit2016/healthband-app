import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/foreground_service.dart';
import 'storage/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // ── Hive Initialization ───────────────────────────────────────────────────
  await HiveService.init();
  // ─────────────────────────────────────────────────────────────────────────

  ForegroundService.init();

  // Read persisted login status BEFORE runApp so the correct initial
  // route is determined synchronously.
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
      // Route directly to home shell if session exists, login otherwise
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
