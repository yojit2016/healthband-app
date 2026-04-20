import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact.dart';
import '../services/api_service.dart';
import 'health_data_provider.dart';

class EmergencyContactsNotifier extends StateNotifier<AsyncValue<List<EmergencyContact>>> {
  EmergencyContactsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchContacts();
  }

  final ApiService _api;

  Future<void> fetchContacts() async {
    state = const AsyncValue.loading();
    final result = await _api.getEmergencyContacts();
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<bool> addContact(Map<String, dynamic> body) async {
    final result = await _api.createEmergencyContact(body);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data([...currentList, result.data!]);
      return true;
    }
    return false;
  }

  Future<bool> updateContact(String id, Map<String, dynamic> body) async {
    final result = await _api.updateEmergencyContact(id, body);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data(
        currentList.map((c) => c.id == id ? result.data! : c).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> deleteContact(String id) async {
    final result = await _api.deleteEmergencyContact(id);
    if (result.isSuccess) {
      final currentList = state.value ?? [];
      state = AsyncValue.data(currentList.where((c) => c.id != id).toList());
      return true;
    }
    return false;
  }
}

final emergencyContactsProvider = StateNotifierProvider<EmergencyContactsNotifier, AsyncValue<List<EmergencyContact>>>((ref) {
  return EmergencyContactsNotifier(ref.watch(apiServiceProvider));
});
