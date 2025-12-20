import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/features/emergency/domain/emergency_service.dart';
import 'package:ping/features/emergency/presentation/emergency_overlay.dart';

/// Wrapper widget that listens for emergency alerts and shows the overlay
class EmergencyAlertListener extends ConsumerWidget {
  final Widget child;

  const EmergencyAlertListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to emergency alerts
    ref.listen<AsyncValue<EmergencyAlert?>>(emergencyAlertsProvider, (
      previous,
      next,
    ) {
      next.whenData((alert) {
        if (alert != null) {
          _showEmergencyAlert(context, ref, alert);
        }
      });
    });

    // Also check for active emergency on build
    ref.listen<EmergencyAlert?>(activeEmergencyProvider, (previous, next) {
      if (next != null && previous == null) {
        _showEmergencyAlert(context, ref, next);
      }
    });

    return child;
  }

  void _showEmergencyAlert(
    BuildContext context,
    WidgetRef ref,
    EmergencyAlert alert,
  ) {
    final emergencyService = ref.read(emergencyServiceProvider);

    showEmergencyOverlay(
      context,
      alert: alert,
      onImOkayPressed: () {
        emergencyService.respondImOkay(alert.id);
        ref.read(activeEmergencyProvider.notifier).clearAlert();
      },
      onCallPressed: () {
        // TODO: Implement call functionality
        // url_launcher: tel:+36...
      },
      onLocationPressed: () {
        // TODO: Implement location view
        // Open map with alert.latitude, alert.longitude
      },
      onDismiss: () {
        emergencyService.dismissAlert(alert.id);
        ref.read(activeEmergencyProvider.notifier).clearAlert();
      },
    );
  }
}

/// Static helper to manually trigger an emergency alert for testing
class EmergencyHelper {
  static void triggerTestEmergency(WidgetRef ref, {String? senderName}) {
    final service = ref.read(emergencyServiceProvider);
    final alert = createMockEmergency(senderName: senderName);
    service.triggerAlert(alert);
  }

  /// Show emergency overlay directly (for immediate use)
  static Future<void> showEmergency(
    BuildContext context,
    WidgetRef ref, {
    required String senderName,
    String? senderAvatarUrl,
    String? message,
    EmergencyType type = EmergencyType.emergency,
    double? latitude,
    double? longitude,
  }) {
    final alert = EmergencyAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      timestamp: DateTime.now(),
      message: message,
      type: type,
      latitude: latitude,
      longitude: longitude,
    );

    final emergencyService = ref.read(emergencyServiceProvider);

    return showEmergencyOverlay(
      context,
      alert: alert,
      onImOkayPressed: () {
        emergencyService.respondImOkay(alert.id);
      },
      onCallPressed: () {
        // TODO: Implement call
      },
      onLocationPressed: (latitude != null && longitude != null)
          ? () {
              // TODO: Open maps
            }
          : null,
      onDismiss: () {
        emergencyService.dismissAlert(alert.id);
      },
    );
  }
}
