import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';

/// Profile Screen - Shows user profile, stats, and daily limits (Dark Mode).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, dynamic> _user = {
    'nickname': 'JohnDoe',
    'email': 'john.doe@example.com',
    'avatar': null,
    'memberSince': 'Jan 2024',
    'friendsCount': 12,
    'vipCount': 3,
  };

  final Map<String, dynamic> _limits = {
    'dailyPings': {'used': 15, 'limit': 50},
    'dailyEmergencies': {'used': 0, 'limit': 3},
    'vipSlots': {'used': 3, 'limit': 5},
  };

  bool _isEditing = false;
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: _user['nickname']);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _saveNickname() {
    setState(() {
      _user['nickname'] = _nicknameController.text;
      _isEditing = false;
    });
    _showFeedback('Nickname updated! ✓');
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'My Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Gap(24),

            // Profile Card
            NeumorphicContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar - NO CAMERA ICON
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
                    ),
                    child: Center(
                      child: Text(
                        _user['nickname'].substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),

                  const Gap(20),

                  // Nickname
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
                          hintText: 'Enter nickname',
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
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const Gap(12),
                        ElevatedButton(
                          onPressed: _saveNickname,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
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
                            _user['nickname'],
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
                    _user['email'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: 'Friends',
                          value: _user['friendsCount'].toString(),
                          icon: Icons.people_rounded,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.divider,
                        ),
                        _StatItem(
                          label: 'VIP',
                          value: _user['vipCount'].toString(),
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.divider,
                        ),
                        _StatItem(
                          label: 'Member',
                          value: _user['memberSince'],
                          icon: Icons.calendar_today_rounded,
                        ),
                      ],
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
                  'Daily Limits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Gap(16),

            _LimitCard(
              title: 'Nudge Pings',
              icon: Icons.touch_app_rounded,
              used: _limits['dailyPings']['used'],
              limit: _limits['dailyPings']['limit'],
              color: AppColors.accent,
            ),

            const Gap(12),

            _LimitCard(
              title: 'Emergency Pings',
              icon: Icons.notifications_active_rounded,
              used: _limits['dailyEmergencies']['used'],
              limit: _limits['dailyEmergencies']['limit'],
              color: AppColors.emergency,
            ),

            const Gap(12),

            _LimitCard(
              title: 'VIP Slots',
              icon: Icons.star_rounded,
              used: _limits['vipSlots']['used'],
              limit: _limits['vipSlots']['limit'],
              color: Colors.amber,
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
                      'Daily limits reset at midnight (local time).',
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
