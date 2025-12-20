import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'package:ping/features/friends/domain/friend_model.dart';
import 'package:ping/features/friends/domain/friends_service.dart';

/// Requests Screen - Friend requests from API (Dark Mode).
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest(String id) async {
    try {
      final friendsService = ref.read(friendsServiceProvider);
      await friendsService.respondToRequest(id, accept: true);
      ref.invalidate(friendRequestsProvider);
      ref.invalidate(friendsListProvider);
      _showFeedback('Barátkérelem elfogadva! 🎉');
    } catch (e) {
      _showFeedback('Hiba: $e', isError: true);
    }
  }

  Future<void> _declineRequest(String id) async {
    try {
      final friendsService = ref.read(friendsServiceProvider);
      await friendsService.respondToRequest(id, accept: false);
      ref.invalidate(friendRequestsProvider);
      _showFeedback('Kérelem elutasítva');
    } catch (e) {
      _showFeedback('Hiba: $e', isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(friendRequestsProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Icon(Icons.mail_rounded, color: AppColors.accent, size: 28),
                const Gap(12),
                const Text(
                  'Kérelmek',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  onPressed: () => ref.invalidate(friendRequestsProvider),
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Beérkezett'),
                  Tab(text: 'Elküldött'),
                ],
              ),
            ),
          ),

          const Gap(20),

          // Content
          Expanded(
            child: requestsAsync.when(
              data: (requests) {
                // Split into received and sent
                // For now just show all - API should handle filtering
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRequestList(
                      requests
                          .where((r) => r.status == FriendRequestStatus.pending)
                          .toList(),
                      isReceived: true,
                    ),
                    _buildRequestList(
                      requests
                          .where((r) => r.status == FriendRequestStatus.pending)
                          .toList(),
                      isReceived: false,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(16),
                    Text(
                      'Hiba: $error',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const Gap(16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(friendRequestsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Újra'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(
    List<FriendRequest> requests, {
    required bool isReceived,
  }) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: AppColors.textSecondary.withAlpha(80),
            ),
            const Gap(20),
            Text(
              isReceived
                  ? 'Nincs beérkezett kérelem'
                  : 'Nincs elküldött kérelem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(100),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(friendRequestsProvider),
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const Gap(14),
        itemBuilder: (context, index) {
          final req = requests[index];
          return _RequestCard(
            request: req,
            isReceived: isReceived,
            onAccept: () => _acceptRequest(req.id),
            onDecline: () => _declineRequest(req.id),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final FriendRequest request;
  final bool isReceived;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.request,
    required this.isReceived,
    required this.onAccept,
    required this.onDecline,
  });

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} perce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} órája';
    } else {
      return '${diff.inDays} napja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = isReceived ? request.fromUserName : request.toUserName;
    final avatar = isReceived ? request.fromUserAvatar : request.toUserAvatar;

    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceColor,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      _formatTime(request.createdAt),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isReceived) ...[
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Elutasítás',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            Gap(8),
                            Text(
                              'Elfogadás',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Függőben...',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
