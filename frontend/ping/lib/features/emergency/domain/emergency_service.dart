import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/features/emergency/presentation/emergency_overlay.dart';

/// Provider for emergency service
final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService();
});

/// Stream provider for emergency alerts
final emergencyAlertsProvider = StreamProvider<EmergencyAlert?>((ref) {
  final service = ref.watch(emergencyServiceProvider);
  return service.alertStream;
});

/// State notifier for active emergency
final activeEmergencyProvider =
    StateNotifierProvider<ActiveEmergencyNotifier, EmergencyAlert?>((ref) {
      return ActiveEmergencyNotifier();
    });

class ActiveEmergencyNotifier extends StateNotifier<EmergencyAlert?> {
  ActiveEmergencyNotifier() : super(null);

  void setAlert(EmergencyAlert alert) {
    state = alert;
  }

  void clearAlert() {
    state = null;
  }
}

/// Emergency service for managing emergency alerts
class EmergencyService {
  final _alertController = StreamController<EmergencyAlert?>.broadcast();

  Stream<EmergencyAlert?> get alertStream => _alertController.stream;

  /// Trigger an emergency alert (called when receiving from backend/websocket)
  void triggerAlert(EmergencyAlert alert) {
    _alertController.add(alert);
  }

  /// Respond to an emergency with "I'm okay"
  Future<void> respondImOkay(String alertId) async {
    // TODO: Implement API call to notify sender that user is okay
    // await api.respondToEmergency(alertId, status: 'okay');
    _alertController.add(null); // Clear the alert
  }

  /// Acknowledge/dismiss an alert without responding
  void dismissAlert(String alertId) {
    _alertController.add(null);
  }

  /// Send emergency to contacts
  Future<void> sendEmergencyToContacts({
    required List<String> contactIds,
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    // TODO: Implement API call to send emergency
    // await api.sendEmergency(
    //   contactIds: contactIds,
    //   message: message,
    //   latitude: latitude,
    //   longitude: longitude,
    // );
  }

  /// Send SOS to all emergency contacts
  Future<void> sendSOS({
    String? message,
    double? latitude,
    double? longitude,
  }) async {
    // TODO: Implement API call to send SOS
    // await api.sendSOS(
    //   message: message,
    //   latitude: latitude,
    //   longitude: longitude,
    // );
  }

  void dispose() {
    _alertController.close();
  }
}

/// Mock function for testing - simulates receiving an emergency
EmergencyAlert createMockEmergency({String? senderName, EmergencyType? type}) {
  return EmergencyAlert(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    senderName: senderName ?? 'Teszt Felhasználó',
    timestamp: DateTime.now(),
    message: 'Segítségre van szükségem!',
    type: type ?? EmergencyType.emergency,
    latitude: 47.4979,
    longitude: 19.0402,
  );
}
