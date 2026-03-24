import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';
import '../models/emergency_event.dart';
import '../providers/audio_settings_provider.dart';
import '../providers/emergency_provider.dart';

/// Full-screen flashing red overlay triggered by emergencyProvider.
/// Plays loops audio, shows notification, and simulates a contact alert.
class EmergencyOverlay extends ConsumerStatefulWidget {
  const EmergencyOverlay({super.key});

  @override
  ConsumerState<EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends ConsumerState<EmergencyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashCtrl;
  late final Animation<double> _opacityAnim;
  
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );
    _opacityAnim = Tween<double>(begin: 0.2, end: 0.85).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeInOut),
    );
  }

  /// Trigger side effects identically once per new emergency
  void _onEmergencyTriggered(EmergencyEvent event, bool audioEnabled) {
    debugPrint('[EmergencyOverlay] EMERGENCY EVENT DETECTED: ${event.eventId}');
    debugPrint('[EmergencyOverlay] Alert trigger function called for: ${event.summary}');

    // 1. Flash the screen continuously
    _flashCtrl.repeat(reverse: true);

    // 2. Play Audio in loop securely for release mode
    if (audioEnabled) {
      FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true, // Bypass DND natively if permissions allow
      );
      _isPlayingAudio = true;
    }

    // 3. Simulate sending SMS / API call to emergency contact
    debugPrint('\n'
               '=============================================\n'
               '[CONTACT ALERT SENT]\n'
               'Event ID:  ${event.eventId}\n'
               'Time:      ${event.timestamp}\n'
               'Issues:    ${event.summary}\n'
               '=============================================\n');
  }

  void _dismissAlarm() {
    // Stop the UI flashing and hide the overlay handled by Riverpod
    _flashCtrl.stop();
    
    // Stop audio
    if (_isPlayingAudio) {
      FlutterRingtonePlayer().stop();
      _isPlayingAudio = false;
    }
    
    // Tell the provider the user explicitly dismissed this alert
    ref.read(emergencyProvider.notifier).dismissAlarm();
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    if (_isPlayingAudio) {
      FlutterRingtonePlayer().stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We listen to the state changes to trigger one-shot effects like audio
    ref.listen<EmergencyState>(emergencyProvider, (prev, next) {
      final wasTriggered = prev?.isTriggered ?? false;
      if (!wasTriggered && next.isTriggered && next.latestEvent != null) {
        final isAudioEnabled = ref.read(audioSettingsProvider);
        _onEmergencyTriggered(next.latestEvent!, isAudioEnabled);
      }
    });

    final isTriggered = ref.watch(emergencyProvider.select((s) => s.isTriggered));
    
    if (isTriggered) {
      debugPrint('[EmergencyOverlay.build] UI Received ACTIVE emergency overlay state!');
    }
    
    if (!isTriggered) {
      return const SizedBox.shrink(); // Hide entirely when not active
    }

    final latestEvent = ref.read(emergencyProvider).latestEvent;
    
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _opacityAnim,
          builder: (context, child) {
            return Container(
              color: AppColors.error.withAlpha((255 * _opacityAnim.value).round()),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_rounded, size: 96, color: Colors.white),
                      const SizedBox(height: 24),
                      const Text(
                        'EMERGENCY DETECTED',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        latestEvent?.summary ?? 'Unknown critical alert',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      
                      // Dismiss Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _dismissAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'DISMISS ALARM',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'This alert has been simulated to your emergency contacts.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
