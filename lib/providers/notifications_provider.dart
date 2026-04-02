import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import 'health_data_provider.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<Notification>>> {
  NotificationsNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  final ApiService _api;

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    final result = await _api.getNotifications();
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.error ?? 'Failed to fetch notifications', StackTrace.current);
    }
  }

  Future<void> fetchForEmergency(String emergencyId) async {
    state = const AsyncValue.loading();
    final result = await _api.getNotificationsForEmergency(emergencyId);
    if (result.isSuccess) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(result.error ?? 'Failed to fetch', StackTrace.current);
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<Notification>>>((ref) {
  return NotificationsNotifier(ref.watch(apiServiceProvider));
});
