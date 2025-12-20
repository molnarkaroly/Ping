import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'package:ping/features/user/domain/user_service.dart';
import 'dart:async';

/// Safety Screen - Check-in timer with API integration (Dark Mode).
class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  bool _isLoading = false;
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

  Future<void> _start() async {
    setState(() => _isLoading = true);

    try {
      final userService = ref.read(userServiceProvider);
      await userService.startCheckIn(duration: _selectedDuration);

      HapticFeedback.mediumImpact();
      setState(() {
        _isActive = true;
        _remaining = _selectedDuration;
        _isLoading = false;
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

      _showFeedback('Check-in elindítva! ✓');
    } catch (e) {
      setState(() => _isLoading = false);
      _showFeedback('Hiba: $e', isError: true);
    }
  }

  Future<void> _markSafe() async {
    setState(() => _isLoading = true);

    try {
      final userService = ref.read(userServiceProvider);
      await userService.markSafe();

      HapticFeedback.mediumImpact();
      setState(() => _remaining = _selectedDuration);
      _showFeedback('Biztonságban! Időzítő frissítve ✓');
    } catch (e) {
      _showFeedback('Hiba: $e', isError: true);
    }

    setState(() => _isLoading = false);
  }

  void _cancel() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _remaining = Duration.zero;
    });
    _showFeedback('Check-in megszakítva');
  }

  void _emergency() {
    _timer?.cancel();
    setState(() => _isActive = false);

    HapticFeedback.heavyImpact();

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
            const Text('Lejárt az idő!'),
          ],
        ),
        content: const Text('Vészjelzés küldése a VIP kontaktjaidnak...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Rendben vagyok'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: const Text('Megerősítés'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.emergency : AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _label(Duration d) =>
      d.inHours > 0 ? '${d.inHours} óra' : '${d.inMinutes} perc';

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
                  'Biztonsági Check-in',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Gap(12),
            Text(
              'Állíts be egy időzítőt. Ha nem jelzel vissza, a VIP kontaktjaid értesítést kapnak.',
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
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  color: AppColors.accent,
                                )
                              : _isActive
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
                                      'Kész',
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
                    const Text(
                      'Válassz időtartamot',
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
                      onTap: _isLoading ? null : _markSafe,
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
                            Icon(Icons.check_circle, color: Colors.white),
                            Gap(10),
                            Text(
                              'Biztonságban vagyok',
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
                            'Mégsem',
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
                      onTap: _isLoading ? null : _start,
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
                              'Check-in indítása',
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
                      'Ha lejár az idő, a VIP kontaktjaid vészjelzést kapnak.',
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
