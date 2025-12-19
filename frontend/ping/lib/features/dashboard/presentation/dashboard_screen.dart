import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'package:ping/core/widgets/pulse_button.dart';

/// Dashboard Screen - The heart of the application (Dark Mode).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentStatus = 'Available';

  final List<Map<String, dynamic>> _statuses = [
    {'label': 'Available', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'Sleeping', 'icon': Icons.bedtime_rounded},
    {'label': 'Driving', 'icon': Icons.directions_car_rounded},
    {'label': 'Busy', 'icon': Icons.do_not_disturb_alt_rounded},
    {'label': 'At Work', 'icon': Icons.work_rounded},
  ];

  final List<Map<String, dynamic>> _friends = [
    {
      'name': 'Anna Kiss',
      'status': 'Available for coffee ☕',
      'isOnline': true,
      'isVip': true,
    },
    {
      'name': 'Peter Kovacs',
      'status': 'Driving home 🚗',
      'isOnline': true,
      'isVip': false,
    },
    {
      'name': 'Maria Nagy',
      'status': 'At the gym 💪',
      'isOnline': true,
      'isVip': true,
    },
    {
      'name': 'Balazs Toth',
      'status': 'Working late...',
      'isOnline': false,
      'isVip': false,
    },
    {
      'name': 'Julia Horvath',
      'status': 'Weekend vibes 🌴',
      'isOnline': true,
      'isVip': true,
    },
    {'name': 'David Molnar', 'status': '', 'isOnline': false, 'isVip': false},
  ];

  void _onStatusChanged(String status) {
    setState(() => _currentStatus = status);
  }

  void _onNudgePing(String friendName) {
    _showPingFeedback('Nudge sent to $friendName! 👋');
  }

  void _onEmergencyPing(String friendName) {
    _showPingFeedback('🚨 Emergency ping sent to $friendName!');
  }

  void _showPingFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(context),
          _buildStatusSelector(),
          const Gap(16),
          Expanded(child: _buildFriendList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Profile Picture
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 48,
              height: 48,
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
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.accent,
                  size: 26,
                ),
              ),
            ),
          ),
          const Gap(14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello! 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(2),
                const Text(
                  'My Friends',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Search
          NeumorphicContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const Gap(10),

          // Settings
          NeumorphicContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onTap: () => context.push('/settings'),
              child: Icon(
                Icons.settings_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const Gap(10),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final isActive = _currentStatus == status['label'];

          return GestureDetector(
            onTap: () => _onStatusChanged(status['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: isActive ? null : NeumorphicStyles.cardShadows,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status['icon'],
                    size: 18,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                  const Gap(8),
                  Text(
                    status['label'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 100,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemCount: _friends.length,
            itemBuilder: (context, index) => _FriendCard(
              friend: _friends[index],
              onNudge: () => _onNudgePing(_friends[index]['name']),
              onEmergency: () => _onEmergencyPing(_friends[index]['name']),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _friends.length,
          separatorBuilder: (_, __) => const Gap(14),
          itemBuilder: (context, index) => _FriendCard(
            friend: _friends[index],
            onNudge: () => _onNudgePing(_friends[index]['name']),
            onEmergency: () => _onEmergencyPing(_friends[index]['name']),
          ),
        );
      },
    );
  }
}

class _FriendCard extends StatefulWidget {
  final Map<String, dynamic> friend;
  final VoidCallback onNudge;
  final VoidCallback onEmergency;

  const _FriendCard({
    required this.friend,
    required this.onNudge,
    required this.onEmergency,
  });

  @override
  State<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<_FriendCard> {
  bool _showDelivered = false;

  void _handleNudge() {
    widget.onNudge();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showDelivered = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showDelivered = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final isOnline = friend['isOnline'] as bool;
    final isVip = friend['isVip'] as bool;

    return NeumorphicContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceColor,
                ),
                child: Center(
                  child: Text(
                    (friend['name'] as String).substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardColor, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        friend['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVip) ...[
                      const Gap(6),
                      Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    ],
                  ],
                ),
                if ((friend['status'] as String).isNotEmpty) ...[
                  const Gap(4),
                  Text(
                    friend['status'],
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_showDelivered)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const Gap(4),
                        Text(
                          'Delivered',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseButton(
                size: 42,
                onTap: _handleNudge,
                child: Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              if (isVip) ...[
                const Gap(8),
                PulseButton(
                  size: 48,
                  onTap: widget.onEmergency,
                  color: AppColors.emergency,
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.emergency,
                    size: 24,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
