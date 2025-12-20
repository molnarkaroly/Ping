import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';
import 'package:ping/features/user/domain/user_service.dart';
import 'package:ping/features/friends/domain/friends_service.dart';

/// Search Screen with API integration (Dark Mode).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _searching = false;
  List<UserSearchResult> _results = [];
  String? _errorMessage;

  Future<void> _search(String q) async {
    if (q.isEmpty || q.length < 2) {
      setState(() {
        _results = [];
        _searching = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final results = await userService.searchUsers(q);

      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _errorMessage = 'Keresés sikertelen';
        });
      }
    }
  }

  Future<void> _sendFriendRequest(UserSearchResult user) async {
    try {
      final friendsService = ref.read(friendsServiceProvider);
      await friendsService.sendFriendRequest(user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barátkérelem elküldve: ${user.name}!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Re-search to update UI
        _search(_controller.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.emergency,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: NeumorphicContainer(
                      padding: const EdgeInsets.all(12),
                      borderRadius: BorderRadius.circular(14),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors.textSecondary),
                          const Gap(12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              onChanged: _search,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Felhasználók keresése...',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _search('');
                              },
                              child: Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.text.isEmpty) {
      return _empty(
        Icons.search_rounded,
        'Barátok keresése',
        'Keresés név vagy felhasználónév alapján.',
      );
    }

    if (_controller.text.length < 2) {
      return _empty(
        Icons.search_rounded,
        'Írj legalább 2 karaktert',
        'A kereséshez adj meg több karaktert.',
      );
    }

    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_errorMessage != null) {
      return _empty(Icons.error_outline, 'Hiba', _errorMessage!);
    }

    if (_results.isEmpty) {
      return _empty(
        Icons.person_search_outlined,
        'Nincs találat',
        'Nem található felhasználó.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, i) {
        final user = _results[i];
        return _UserCard(user: user, onAdd: () => _sendFriendRequest(user));
      },
    );
  }

  Widget _empty(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textSecondary.withAlpha(60)),
          const Gap(20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(8),
          Text(
            sub,
            style: TextStyle(color: AppColors.textSecondary.withAlpha(150)),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserSearchResult user;
  final VoidCallback onAdd;

  const _UserCard({required this.user, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceColor,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Gap(4),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (user.isFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.check, color: AppColors.success, size: 16),
                  const Gap(6),
                  Text(
                    'Barát',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (user.isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Függőben',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 16),
                    Gap(6),
                    Text(
                      'Hozzáadás',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
