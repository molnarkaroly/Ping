import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'package:ping/features/auth/domain/auth_service.dart';
import 'package:ping/features/friends/domain/friends_service.dart';
import 'package:ping/features/user/domain/user_service.dart';

/// Profile Screen - Shows user profile, stats, and daily limits from API.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.emergency : AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final friendsAsync = ref.watch(friendsListProvider);
    final limitsAsync = ref.watch(userLimitsProvider);

    // Update controller when user loads
    if (currentUser != null && _nicknameController.text.isEmpty) {
      _nicknameController.text = currentUser.name;
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.person_rounded, color: AppColors.accent, size: 28),
                const Gap(12),
                const Text(
                  'Profilom',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Logout button
                IconButton(
                  onPressed: _logout,
                  icon: Icon(Icons.logout_rounded, color: AppColors.emergency),
                  tooltip: 'Kijelentkezés',
                ),
              ],
            ),

            const Gap(24),

            // Profile Card
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withAlpha(100),
                          AppColors.accent.withAlpha(40),
                        ],
                      ),
                      boxShadow: NeumorphicStyles.cardShadows,
                      image: currentUser?.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(currentUser!.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: currentUser?.avatarUrl == null
                        ? Center(
                            child: Text(
                              (currentUser?.name ?? 'U')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          )
                        : null,
                  ),

                  const Gap(20),

                  // Name
                  if (_isEditing) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(100),
                        ),
                      ),
                      child: TextField(
                        controller: _nicknameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Add meg a neved',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: Text(
                            'Mégse',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const Gap(12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _showFeedback('Név frissítve! ✓');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Mentés'),
                        ),
                      ],
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentUser?.name ?? 'Felhasználó',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(8),
                          Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Gap(8),

                  Text(
                    currentUser?.email ?? '',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  if (currentUser?.phoneNumber != null) ...[
                    const Gap(4),
                    Text(
                      currentUser!.phoneNumber!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const Gap(24),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: friendsAsync.when(
                      data: (friends) {
                        final vipCount = friends.where((f) => f.isVip).length;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              label: 'Barátok',
                              value: friends.length.toString(),
                              icon: Icons.people_rounded,
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppColors.divider,
                            ),
                            _StatItem(
                              label: 'VIP',
                              value: vipCount.toString(),
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: AppColors.divider,
                            ),
                            _StatItem(
                              label: 'Tag óta',
                              value: _formatMemberSince(currentUser?.createdAt),
                              icon: Icons.calendar_today_rounded,
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Nem sikerült betölteni',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(28),

            // Daily Limits Section
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
                const Gap(8),
                const Text(
                  'Napi limitek',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Gap(16),

            limitsAsync.when(
              data: (limits) => Column(
                children: [
                  _LimitCard(
                    title: 'Emergency pingek',
                    icon: Icons.notifications_active_rounded,
                    used: limits.emergencySentToday,
                    limit: limits.emergencyLimitPerDay,
                    color: AppColors.emergency,
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Hiba: $error',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

            const Gap(24),

            // Info Card
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
                      'A napi limitek éjfélkor nullázódnak.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
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

  String _formatMemberSince(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'Jan',
      'Feb',
      'Már',
      'Ápr',
      'Máj',
      'Jún',
      'Júl',
      'Aug',
      'Szept',
      'Okt',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: iconColor ?? AppColors.textSecondary),
        const Gap(8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Gap(2),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _LimitCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int used;
  final int limit;
  final Color color;

  const _LimitCard({
    required this.title,
    required this.icon,
    required this.used,
    required this.limit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = limit > 0 ? used / limit : 0.0;

    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Gap(14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '$used / $limit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: progress > 0.8 ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
