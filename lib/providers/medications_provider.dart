import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_schedule.dart';
import '../services/api_service.dart';
import '../providers/health_data_provider.dart';
import '../services/notification_service.dart';

class MedicationsNotifier
    extends StateNotifier<AsyncValue<List<MedicationSchedule>>> {
  MedicationsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchMedications();
  }

  final ApiService _api;

  Future<void> fetchMedications() async {
    state = const AsyncValue.loading();
    final result = await _api.getMedications();
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
      
      // Schedule a demo reminder for each fetched medicine
      int delay = 5;
      for (final med in result.data!) {
        NotificationService.scheduleMedicationReminder(med.medicineName, delaySeconds: delay);
        delay += 5;
      }
    } else {
      // Fallback silently to mock/empty data on error
      state = const AsyncValue.data([]);
    }
  }

  Future<bool> addMedication(Map<String, dynamic> body) async {
    final result = await _api.createMedication(body);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, result.data!]);
      return true;
    }
    return false;
  }

  Future<bool> updateMedication(String id, Map<String, dynamic> body) async {
    final result = await _api.updateMedication(id, body);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data(
        currentList.map((m) => m.id == id ? result.data! : m).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteMedication(String id) async {
    final result = await _api.deleteMedication(id);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((m) => m.id != id).toList());
      return true;
    }
    return false;
  }

  Future<bool> markTaken(String id) async {
    final result = await _api.markMedicationTaken(id);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data(
        currentList
            .map((m) => m.id == id ? m.copyWith(isTaken: true) : m)
            .toList(),
      );
      return true;
    }
    return false;
  }
}

final medicationsProvider =
    StateNotifierProvider<
      MedicationsNotifier,
      AsyncValue<List<MedicationSchedule>>
    >((ref) {
      return MedicationsNotifier(ref.watch(apiServiceProvider));
    });
