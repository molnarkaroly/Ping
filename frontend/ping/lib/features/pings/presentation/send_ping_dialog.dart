import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/features/pings/domain/ping_model.dart';
import 'package:ping/features/pings/domain/pings_service.dart';
import 'package:ping/features/friends/domain/friend_model.dart';

/// Dialog for sending a ping with optional message (shown on long press)
class SendPingDialog extends ConsumerStatefulWidget {
  final Friend friend;
  final PingType pingType;
  final bool showMessageField;

  const SendPingDialog({
    super.key,
    required this.friend,
    required this.pingType,
    this.showMessageField = false,
  });

  /// Show quick ping (no message)
  static Future<bool?> showQuickPing(
    BuildContext context,
    WidgetRef ref, {
    required Friend friend,
    required PingType pingType,
  }) async {
    return _sendPing(context, ref, friend: friend, pingType: pingType);
  }

  /// Show ping dialog with message field (for long press)
  static Future<bool?> showWithMessage(
    BuildContext context, {
    required Friend friend,
    required PingType pingType,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendPingDialog(
        friend: friend,
        pingType: pingType,
        showMessageField: true,
      ),
    );
  }

  static Future<bool?> _sendPing(
    BuildContext context,
    WidgetRef ref, {
    required Friend friend,
    required PingType pingType,
    String? message,
  }) async {
    try {
      final pingsService = ref.read(pingsServiceProvider);
      await pingsService.sendPing(
        receiverId: friend.id,
        type: pingType,
        message: message,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  ConsumerState<SendPingDialog> createState() => _SendPingDialogState();
}

class _SendPingDialogState extends ConsumerState<SendPingDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendPing() async {
    setState(() => _isSending = true);

    try {
      final pingsService = ref.read(pingsServiceProvider);
      await pingsService.sendPing(
        receiverId: widget.friend.id,
        type: widget.pingType,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.pingType == PingType.emergency
                  ? 'Vészjelzés elküldve ${widget.friend.name} részére!'
                  : 'Ping elküldve ${widget.friend.name} részére!',
            ),
            backgroundColor: widget.pingType == PingType.emergency
                ? AppColors.emergency
                : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba történt: $e'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = widget.pingType == PingType.emergency;
    final accentColor = isEmergency ? AppColors.emergency : AppColors.accent;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withAlpha(30),
                  ),
                  child: Icon(
                    isEmergency
                        ? Icons.warning_rounded
                        : Icons.notifications_active_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEmergency ? 'Vészjelzés küldése' : 'Ping küldése',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.friend.name,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message field
            if (widget.showMessageField) ...[
              Text(
                'Üzenet (opcionális)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: isEmergency
                      ? 'Pl. "Segítségre van szükségem!"'
                      : 'Pl. "Hívj vissza!"',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withAlpha(100),
                  ),
                  filled: true,
                  fillColor: AppColors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                  counterStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Send button
            GestureDetector(
              onTap: _isSending ? null : _sendPing,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isSending
                        ? [AppColors.cardColor, AppColors.cardColor]
                        : [accentColor, accentColor.withAlpha(180)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isSending
                      ? []
                      : [
                          BoxShadow(
                            color: accentColor.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.textPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEmergency
                                  ? Icons.warning_rounded
                                  : Icons.send_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEmergency
                                  ? 'Vészjelzés küldése'
                                  : 'Ping küldése',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Mégse',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ping button widget with long-press for message
class PingButton extends ConsumerWidget {
  final Friend friend;
  final PingType pingType;
  final Widget child;
  final double size;

  const PingButton({
    super.key,
    required this.friend,
    required this.pingType,
    required this.child,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmergency = pingType == PingType.emergency;
    final color = isEmergency ? AppColors.emergency : AppColors.accent;

    return GestureDetector(
      onTap: () async {
        // Quick send without message
        HapticFeedback.lightImpact();
        final success = await SendPingDialog.showQuickPing(
          context,
          ref,
          friend: friend,
          pingType: pingType,
        );

        if (success == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEmergency ? 'Vészjelzés elküldve!' : 'Ping elküldve!',
              ),
              backgroundColor: isEmergency
                  ? AppColors.emergency
                  : AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onLongPress: () {
        // Show dialog with message field
        HapticFeedback.heavyImpact();
        SendPingDialog.showWithMessage(
          context,
          friend: friend,
          pingType: pingType,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(30),
          border: Border.all(color: color.withAlpha(100), width: 2),
        ),
        child: Center(child: child),
      ),
    );
  }
}
