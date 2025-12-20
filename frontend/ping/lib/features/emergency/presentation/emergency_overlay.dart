import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Emergency alert model
class EmergencyAlert {
  final String id;
  final String senderName;
  final String? senderAvatarUrl;
  final DateTime timestamp;
  final String? message;
  final EmergencyType type;
  final double? latitude;
  final double? longitude;

  const EmergencyAlert({
    required this.id,
    required this.senderName,
    this.senderAvatarUrl,
    required this.timestamp,
    this.message,
    this.type = EmergencyType.emergency,
    this.latitude,
    this.longitude,
  });
}

enum EmergencyType { emergency, sos, checkIn, lowBattery }

/// Full-screen emergency overlay that appears when receiving an emergency alert
class EmergencyOverlay extends StatefulWidget {
  final EmergencyAlert alert;
  final VoidCallback onImOkayPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onLocationPressed;
  final VoidCallback onDismiss;

  const EmergencyOverlay({
    super.key,
    required this.alert,
    required this.onImOkayPressed,
    this.onCallPressed,
    this.onLocationPressed,
    required this.onDismiss,
  });

  @override
  State<EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends State<EmergencyOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startVibration();
  }

  void _initAnimations() {
    // Pulse animation for the alert icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Shake animation for urgency
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(_shakeController);
  }

  void _startVibration() {
    // Vibrate pattern for emergency
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    _stopVibration();
    super.dispose();
  }

  void _handleImOkay() {
    _stopVibration();
    _fadeController.reverse().then((_) {
      widget.onImOkayPressed();
    });
  }

  void _handleDismiss() {
    _stopVibration();
    _fadeController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'Most';
    if (diff.inMinutes < 60) return '${diff.inMinutes} perce';
    if (diff.inHours < 24) return '${diff.inHours} órája';
    return '${diff.inDays} napja';
  }

  String _getEmergencyTypeText(EmergencyType type) {
    switch (type) {
      case EmergencyType.emergency:
        return 'VÉSZHELYZET';
      case EmergencyType.sos:
        return 'SOS RIASZTÁS';
      case EmergencyType.checkIn:
        return 'BEJELENTKEZÉS SZÜKSÉGES';
      case EmergencyType.lowBattery:
        return 'ALACSONY AKKUMULÁTOR';
    }
  }

  IconData _getEmergencyIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.emergency:
        return Icons.warning_rounded;
      case EmergencyType.sos:
        return Icons.sos_rounded;
      case EmergencyType.checkIn:
        return Icons.access_time_rounded;
      case EmergencyType.lowBattery:
        return Icons.battery_alert_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFB71C1C),
                const Color(0xFF8B0000),
                Colors.black.withAlpha(230),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar with dismiss
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimeAgo(widget.alert.timestamp),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleDismiss,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Emergency icon with pulse
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(25),
                                border: Border.all(
                                  color: Colors.white.withAlpha(50),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF0000,
                                    ).withAlpha(100),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getEmergencyIcon(widget.alert.type),
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Emergency type label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getEmergencyTypeText(widget.alert.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sender info
                _buildSenderInfo(),

                const SizedBox(height: 16),

                // Optional message
                if (widget.alert.message != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.alert.message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Spacer(flex: 1),

                // Action buttons
                _buildActionButtons(),

                const SizedBox(height: 32),

                // Main "I'm Okay" button
                _buildImOkayButton(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 20),
            ],
          ),
          child: ClipOval(
            child: widget.alert.senderAvatarUrl != null
                ? Image.network(
                    widget.alert.senderAvatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        const SizedBox(height: 16),
        // Sender name
        Text(
          widget.alert.senderName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'riasztást küldött neked',
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white.withAlpha(50),
      child: Center(
        child: Text(
          widget.alert.senderName.isNotEmpty
              ? widget.alert.senderName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Call button
          if (widget.onCallPressed != null)
            _buildActionButton(
              icon: Icons.phone_rounded,
              label: 'Hívás',
              onTap: widget.onCallPressed!,
            ),
          if (widget.onCallPressed != null && widget.onLocationPressed != null)
            const SizedBox(width: 32),
          // Location button
          if (widget.onLocationPressed != null &&
              widget.alert.latitude != null &&
              widget.alert.longitude != null)
            _buildActionButton(
              icon: Icons.location_on_rounded,
              label: 'Helyzet',
              onTap: widget.onLocationPressed!,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(25),
              border: Border.all(color: Colors.white.withAlpha(50), width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImOkayButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: _handleImOkay,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'RENDBEN VAGYOK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show emergency overlay as a full-screen dialog
Future<void> showEmergencyOverlay(
  BuildContext context, {
  required EmergencyAlert alert,
  required VoidCallback onImOkayPressed,
  VoidCallback? onCallPressed,
  VoidCallback? onLocationPressed,
  required VoidCallback onDismiss,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) {
      return EmergencyOverlay(
        alert: alert,
        onImOkayPressed: () {
          Navigator.of(context).pop();
          onImOkayPressed();
        },
        onCallPressed: onCallPressed != null
            ? () {
                onCallPressed();
              }
            : null,
        onLocationPressed: onLocationPressed,
        onDismiss: () {
          Navigator.of(context).pop();
          onDismiss();
        },
      );
    },
  );
}
