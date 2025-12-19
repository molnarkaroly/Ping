import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'dart:async';

/// Safety Screen - Check-in timer (Dark Mode).
class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  Duration _selectedDuration = const Duration(hours: 1);
  Duration _remaining = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseController;

  final List<Duration> _durations = [
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(hours: 1),
    const Duration(hours: 2),
    const Duration(hours: 4),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isActive = true;
      _remaining = _selectedDuration;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(
          () => _remaining = Duration(seconds: _remaining.inSeconds - 1),
        );
      } else {
        _emergency();
      }
    });
  }

  void _refresh() {
    setState(() => _remaining = _selectedDuration);
    _showFeedback('Timer refreshed! ✓');
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remaining = Duration.zero;
    });
    _showFeedback('Check-in cancelled');
  }

  void _emergency() {
    _timer?.cancel();
    setState(() => _isActive = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.emergency),
            const Gap(12),
            const Text('Time\'s Up!'),
          ],
        ),
        content: const Text(
          'Emergency alerts are being sent to your VIP contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I\'m OK'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _label(Duration d) =>
      d.inHours > 0 ? '${d.inHours}h' : '${d.inMinutes}min';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_rounded, color: AppColors.accent, size: 28),
                const Gap(12),
                const Text(
                  'Safety Check-in',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(12),
            Text(
              'Set a timer. If you don\'t check back, your VIP contacts will be notified.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Gap(32),
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Timer Display
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isActive
                              ? AppColors.success.withAlpha(20)
                              : AppColors.surfaceColor,
                          boxShadow: _isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withAlpha(
                                      (40 + _pulseController.value * 30)
                                          .toInt(),
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: _pulseController.value * 15,
                                  ),
                                ]
                              : NeumorphicStyles.cardShadows,
                        ),
                        child: Center(
                          child: _isActive
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 32,
                                      color: AppColors.success,
                                    ),
                                    const Gap(8),
                                    Text(
                                      _format(_remaining),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 48,
                                      color: AppColors.textSecondary,
                                    ),
                                    const Gap(12),
                                    Text(
                                      'Ready',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const Gap(28),
                  // Duration Selector
                  if (!_isActive) ...[
                    Text(
                      'Select Duration',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Gap(16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _durations.map((d) {
                        final selected = _selectedDuration == d;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDuration = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _label(d),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Gap(28),
                  ],
                  // Buttons
                  if (_isActive) ...[
                    GestureDetector(
                      onTap: _refresh,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.refresh, color: Colors.white),
                            Gap(10),
                            Text(
                              'I\'m Safe - Refresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(12),
                    GestureDetector(
                      onTap: _cancel,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.emergency.withAlpha(100),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.emergency,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _start,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            Gap(8),
                            Text(
                              'Start Check-in',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.accent),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'If the timer runs out, your VIP contacts will receive an emergency alert.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
