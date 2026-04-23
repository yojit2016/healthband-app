import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_theme.dart';
import '../providers/index.dart';
import '../services/notification_service.dart';
import '../widgets/add_medication_dialog.dart';

class MedicationsTab extends ConsumerWidget {
  const MedicationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationsProvider);

    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.error),
            ),
          ],
        ),
      ),
      data: (medications) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // ── DEBUG BANNER ──────────────────────────────────────────────
              _DebugBanner(),
              // ── Medication list ───────────────────────────────────────────
              Expanded(
                child: medications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              color: AppColors.textSecondary,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No medications yet.\nTap + to add one.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(medicationsProvider.notifier).fetchMedications(),
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceVariant,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            final med = medications[index];
                            return _MedicationCard(
                              med: med,
                              onMarkTaken: () async {
                                final success = await ref
                                    .read(medicationsProvider.notifier)
                                    .markTaken(med.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Medication marked as taken'
                                          : 'Failed to mark as taken',
                                    ),
                                    backgroundColor: success
                                        ? AppColors.success
                                        : AppColors.error,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddMedicationDialog(),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

// ── Debug banner ─────────────────────────────────────────────────────────────

class _DebugBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Test notification button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await NotificationService.showTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '🔔 Test notification sent — check your notification shade'),
                      backgroundColor: AppColors.primary,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active,
                  size: 16, color: AppColors.primary),
              label: const Text(
                'Test Notification',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Realme battery fix button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRealmeBatteryDialog(context),
              icon: const Icon(Icons.battery_alert,
                  size: 16, color: Colors.orange),
              label: const Text(
                'Fix Battery',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRealmeBatteryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phone_android, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Realme / OEM Fix',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background notifications are blocked by default on Realme, '
                'OnePlus, Xiaomi, and similar devices.\n\nFollow these steps:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 12),
              _Step(
                number: '1',
                text:
                    'Settings → Apps → Health Band → Battery\n→ Set to "No restrictions"',
              ),
              _Step(
                number: '2',
                text:
                    'Settings → Battery → Battery Optimization\n→ Find Health Band → "Don\'t optimize"',
              ),
              _Step(
                number: '3',
                text:
                    'Settings → Apps → Health Band → Notifications\n→ Enable ALL notification categories',
              ),
              _Step(
                number: '4',
                text:
                    'Settings → Apps → Health Band → Permissions\n→ Alarms & Reminders → Allow',
              ),
              SizedBox(height: 8),
              Text(
                'After completing all steps, add a medication reminder\n'
                '2 minutes in the future and swipe the app away to test.',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary,
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medication card ──────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.med, required this.onMarkTaken});
  final dynamic med;
  final VoidCallback onMarkTaken;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha((255 * 0.3).round()),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((255 * 0.1).round()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.medicineName as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${med.amount} ${med.unit} • ${med.form}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Times: ${(med.times as List).join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: (med.isTaken as bool) ? null : onMarkTaken,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 0),
                      backgroundColor: (med.isTaken as bool)
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    child: Text(
                      (med.isTaken as bool) ? 'Taken' : 'Mark as Taken',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (med.isTaken as bool)
                            ? AppColors.surfaceVariant
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
