import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'package:ping/core/widgets/pulse_button.dart';
import 'package:ping/features/auth/domain/auth_service.dart';
import 'package:ping/features/friends/domain/friend_model.dart';
import 'package:ping/features/friends/domain/friends_service.dart';
import 'package:ping/features/pings/domain/ping_model.dart';
import 'package:ping/features/pings/domain/pings_service.dart';
import 'package:ping/features/pings/presentation/send_ping_dialog.dart';
import 'package:ping/features/user/domain/user_service.dart';

/// Dashboard Screen - The heart of the application (Dark Mode).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _currentStatus = 'Available';

  final List<Map<String, dynamic>> _statuses = [
    {'label': 'Available', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'Sleeping', 'icon': Icons.bedtime_rounded},
    {'label': 'Driving', 'icon': Icons.directions_car_rounded},
    {'label': 'Busy', 'icon': Icons.do_not_disturb_alt_rounded},
    {'label': 'At Work', 'icon': Icons.work_rounded},
  ];

  Future<void> _onStatusChanged(String status) async {
    setState(() => _currentStatus = status);

    try {
      final userService = ref.read(userServiceProvider);
      await userService.updateStatus(status);
    } catch (e) {
      // Ignore errors for now
    }
  }

  void _showPingFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.emergency : AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final currentUser = ref.watch(currentUserProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(context, currentUser?.name ?? 'User'),
          _buildStatusSelector(),
          const Gap(16),
          Expanded(
            child: friendsAsync.when(
              data: (friends) => _buildFriendList(friends),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
          const Gap(16),
          Text(
            'Hiba történt',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            error,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(friendsListProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Újrapróbálás'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
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
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
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
                  'Szia, $userName! 👋',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(2),
                const Text(
                  'Barátaim',
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

  Widget _buildFriendList(List<Friend> friends) {
    if (friends.isEmpty) {
      return _buildEmptyState();
    }

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
            itemCount: friends.length,
            itemBuilder: (context, index) => _FriendCard(
              friend: friends[index],
              onPingSent: (message) => _showPingFeedback(message),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(friendsListProvider);
          },
          color: AppColors.accent,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: friends.length,
            separatorBuilder: (_, __) => const Gap(14),
            itemBuilder: (context, index) => _FriendCard(
              friend: friends[index],
              onPingSent: (message) => _showPingFeedback(message),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: AppColors.textSecondary.withAlpha(100),
          ),
          const Gap(16),
          Text(
            'Még nincsenek barátaid',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            'Keress új embereket a + gombbal!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.person_add),
            label: const Text('Barát keresése'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends ConsumerStatefulWidget {
  final Friend friend;
  final void Function(String message) onPingSent;

  const _FriendCard({required this.friend, required this.onPingSent});

  @override
  ConsumerState<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends ConsumerState<_FriendCard> {
  bool _showDelivered = false;
  bool _isSending = false;

  Future<void> _handleNudge() async {
    if (_isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.lightImpact();

    try {
      final pingsService = ref.read(pingsServiceProvider);
      await pingsService.sendPing(
        receiverId: widget.friend.id,
        type: PingType.nudge,
      );

      if (mounted) {
        setState(() => _showDelivered = true);
        widget.onPingSent('Ping elküldve: ${widget.friend.name}! 👋');

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showDelivered = false);
        });
      }
    } catch (e) {
      widget.onPingSent('Hiba: $e');
    }

    if (mounted) setState(() => _isSending = false);
  }

  void _handleNudgeLongPress() {
    HapticFeedback.heavyImpact();
    SendPingDialog.showWithMessage(
      context,
      friend: widget.friend,
      pingType: PingType.nudge,
    );
  }

  void _handleEmergency() {
    HapticFeedback.heavyImpact();
    SendPingDialog.showWithMessage(
      context,
      friend: widget.friend,
      pingType: PingType.emergency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final isVip = friend.isVip;

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
                  image: friend.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(friend.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: friend.avatarUrl == null
                    ? Center(
                        child: Text(
                          friend.name.isNotEmpty
                              ? friend.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color:
                        friend.lastSeen != null &&
                            DateTime.now()
                                    .difference(friend.lastSeen!)
                                    .inMinutes <
                                5
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
                        friend.name,
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
                if (friend.status != null && friend.status!.isNotEmpty) ...[
                  const Gap(4),
                  Text(
                    friend.status!,
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
                          'Elküldve',
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
              GestureDetector(
                onTap: _isSending ? null : _handleNudge,
                onLongPress: _handleNudgeLongPress,
                child: PulseButton(
                  size: 42,
                  onTap: _handleNudge,
                  child: _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Icon(
                          Icons.touch_app_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                ),
              ),
              if (isVip) ...[
                const Gap(8),
                GestureDetector(
                  onTap: _handleEmergency,
                  onLongPress: _handleEmergency,
                  child: PulseButton(
                    size: 48,
                    onTap: _handleEmergency,
                    color: AppColors.emergency,
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.emergency,
                      size: 24,
                    ),
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
