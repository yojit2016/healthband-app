import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_schedule.dart';
import '../services/api_service.dart';
import '../providers/health_data_provider.dart';
import '../services/notification_service.dart';
import '../storage/index.dart';

class MedicationsNotifier extends StateNotifier<AsyncValue<List<MedicationSchedule>>> {
  MedicationsNotifier(this._api) : super(const AsyncValue.loading()) {
    _init();
  }

  final ApiService _api;

  Future<void> _init() async {
    // 1. Load from Hive immediately for "Instant UI"
    final cachedMeds = HiveService.getMedications();
    if (cachedMeds.isNotEmpty) {
      final meds = cachedMeds.map((e) => MedicationSchedule.fromJson(e)).toList();
      state = AsyncValue.data(meds);
      // Re-schedule alarms from cache just in case
      for (final med in meds) {
        if (med.isActive) {
          NotificationService.scheduleMedicationReminder(med);
        }
      }
    }
    
    // 2. Fetch from server to sync
    await fetchMedications();
  }

  Future<void> fetchMedications() async {
    final result = await _api.getMedications();
    if (result.isSuccess) {
      final medications = result.data!;
      
      // Update state and persistence
      state = AsyncValue.data(medications);
      await HiveService.saveMedications(medications);
      
      // Schedule all active medications
      for (final med in medications) {
        if (med.isActive) {
          await NotificationService.scheduleMedicationReminder(med);
        }
      }
    } else {
      // If server fails, keep the cached data
      if (state.value == null) {
        state = const AsyncValue.data([]);
      }
    }
  }

  Future<bool> addMedication(Map<String, dynamic> body) async {
    // ── LOCAL FIRST FOR DEMONSTRATION ────────────────────────────────────────
    
    // 1. Create a local temporary medication object
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMed = MedicationSchedule.fromJson({
      '_id': tempId,
      ...body,
    });

    // 2. Add to UI state immediately
    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, tempMed]);

    // 3. Save to Local Persistence
    await HiveService.saveMedications(state.value!);

    // 4. SCHEDULE ALARM IMMEDIATELY (This is the most critical for demo)
    try {
      await NotificationService.scheduleMedicationReminder(tempMed);
    } catch (e) {
      debugPrint('[MedicationsNotifier] Local scheduling failed: $e');
    }

    // ── SYNC TO SERVER IN BACKGROUND ─────────────────────────────────────────
    
    final result = await _api.createMedication(body);
    if (result.isSuccess) {
      final serverMed = result.data!;
      
      // Replace the temp medication with the server version (which has a real ID)
      final updatedList = (state.value ?? []).map((m) {
        return m.id == tempId ? serverMed : m;
      }).toList();
      
      state = AsyncValue.data(updatedList);
      await HiveService.saveMedications(updatedList);
      
      // Schedule the real ID version as well
      await NotificationService.scheduleMedicationReminder(serverMed);
      return true;
    }
    
    // If server fails, we still keep the local one for the demo, 
    // but the user should know it's "local only".
    return true; // Return true because it was successfully added locally
  }

  Future<bool> updateMedication(String id, Map<String, dynamic> body) async {
    final result = await _api.updateMedication(id, body);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      final updatedMed = result.data!;
      
      state = AsyncValue.data(
        currentList.map((m) => m.id == id ? updatedMed : m).toList(),
      );
      
      await HiveService.saveMedications(state.value!);
      
      if (updatedMed.isActive) {
        await NotificationService.scheduleMedicationReminder(updatedMed);
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteMedication(String id) async {
    final result = await _api.deleteMedication(id);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      final newList = currentList.where((m) => m.id != id).toList();
      state = AsyncValue.data(newList);
      await HiveService.saveMedications(newList);
      
      // Find the med to cancel its reminders
      final medToCancel = currentList.firstWhere((m) => m.id == id, orElse: () => MedicationSchedule.fromJson({}));
      if (medToCancel.id.isNotEmpty) {
        await NotificationService.cancelMedicationReminders(medToCancel);
      }
      return true;
    }
    return false;
  }

  Future<bool> markTaken(String id) async {
    final result = await _api.markMedicationTaken(id);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      final updatedList = currentList.map((m) => m.id == id ? m.copyWith(isTaken: true) : m).toList();
      state = AsyncValue.data(updatedList);
      await HiveService.saveMedications(updatedList);
      return true;
    }
    return false;
  }
}

final medicationsProvider = StateNotifierProvider<MedicationsNotifier, AsyncValue<List<MedicationSchedule>>>((ref) {
  return MedicationsNotifier(ref.watch(apiServiceProvider));
});
