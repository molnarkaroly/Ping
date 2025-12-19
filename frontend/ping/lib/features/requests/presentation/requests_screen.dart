import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';

/// Requests Screen - Friend and VIP requests (Dark Mode).
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _friendRequests = [
    {
      'id': 1,
      'name': 'Emma Wilson',
      'message': 'Hey! Let\'s connect 👋',
      'time': '2 hours ago',
    },
    {'id': 2, 'name': 'James Brown', 'message': null, 'time': '5 hours ago'},
    {
      'id': 3,
      'name': 'Sophie Martinez',
      'message': 'We met at the conference!',
      'time': '1 day ago',
    },
  ];

  final List<Map<String, dynamic>> _vipRequests = [
    {
      'id': 1,
      'name': 'Anna Kiss',
      'message': 'Please add me as VIP',
      'time': '30 min ago',
    },
  ];

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

  void _acceptRequest(int id, bool isVip) {
    setState(() {
      if (isVip) {
        _vipRequests.removeWhere((r) => r['id'] == id);
      } else {
        _friendRequests.removeWhere((r) => r['id'] == id);
      }
    });
    _showFeedback(
      isVip ? 'VIP request accepted! ⭐' : 'Friend request accepted! 🎉',
    );
  }

  void _declineRequest(int id, bool isVip) {
    setState(() {
      if (isVip) {
        _vipRequests.removeWhere((r) => r['id'] == id);
      } else {
        _friendRequests.removeWhere((r) => r['id'] == id);
      }
    });
    _showFeedback('Request declined');
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
                  'Requests',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Friends'),
                        if (_friendRequests.isNotEmpty) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emergency,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _friendRequests.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('VIP'),
                        if (_vipRequests.isNotEmpty) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _vipRequests.length.toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Gap(20),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_friendRequests, false),
                _buildList(_vipRequests, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> requests, bool isVip) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVip ? Icons.star_outline_rounded : Icons.people_outline_rounded,
              size: 80,
              color: AppColors.textSecondary.withAlpha(80),
            ),
            const Gap(20),
            Text(
              isVip ? 'No VIP requests' : 'No friend requests',
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const Gap(14),
      itemBuilder: (context, index) {
        final req = requests[index];
        return _RequestCard(
          name: req['name'],
          message: req['message'],
          time: req['time'],
          isVip: isVip,
          onAccept: () => _acceptRequest(req['id'], isVip),
          onDecline: () => _declineRequest(req['id'], isVip),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String name;
  final String? message;
  final String time;
  final bool isVip;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.name,
    this.message,
    required this.time,
    required this.isVip,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isVip
                    ? Colors.amber.withAlpha(40)
                    : AppColors.surfaceColor,
                child: isVip
                    ? const Icon(Icons.star_rounded, color: Colors.amber)
                    : Text(
                        name.substring(0, 1),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      time,
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
          if (message != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$message"',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
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
                        'Decline',
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
                      color: isVip ? Colors.amber : AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isVip ? Icons.star_rounded : Icons.check_rounded,
                            color: isVip ? Colors.black87 : Colors.white,
                            size: 18,
                          ),
                          const Gap(8),
                          Text(
                            isVip ? 'Accept VIP' : 'Accept',
                            style: TextStyle(
                              color: isVip ? Colors.black87 : Colors.white,
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
        ],
      ),
    );
  }
}
