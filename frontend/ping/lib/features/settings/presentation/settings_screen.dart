import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/core/widgets/neumorphic_container.dart';

/// Settings Screen (Dark Mode).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _location = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  const Gap(16),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Section(title: 'NOTIFICATIONS'),
                  const Gap(12),
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _Toggle(
                          icon: Icons.notifications_rounded,
                          title: 'Push Notifications',
                          value: _notifications,
                          onChanged: (v) => setState(() => _notifications = v),
                        ),
                        _Divider(),
                        _Toggle(
                          icon: Icons.volume_up_rounded,
                          title: 'Sound',
                          value: _sound,
                          onChanged: (v) => setState(() => _sound = v),
                        ),
                        _Divider(),
                        _Toggle(
                          icon: Icons.vibration,
                          title: 'Vibration',
                          value: _vibration,
                          onChanged: (v) => setState(() => _vibration = v),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  _Section(title: 'PRIVACY'),
                  const Gap(12),
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _Toggle(
                          icon: Icons.location_on_rounded,
                          title: 'Location Sharing',
                          value: _location,
                          onChanged: (v) => setState(() => _location = v),
                        ),
                        _Divider(),
                        _Item(
                          icon: Icons.block,
                          title: 'Blocked Users',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  _Section(title: 'ACCOUNT'),
                  const Gap(12),
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _Item(
                          icon: Icons.password,
                          title: 'Change Password',
                          onTap: () {},
                        ),
                        _Divider(),
                        _Item(
                          icon: Icons.email_rounded,
                          title: 'Change Email',
                          onTap: () {},
                        ),
                        _Divider(),
                        _Item(
                          icon: Icons.logout,
                          title: 'Log Out',
                          titleColor: AppColors.emergency,
                          onTap: () => _showLogout(),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  _Section(title: 'ABOUT'),
                  const Gap(12),
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        _Item(
                          icon: Icons.info_outline_rounded,
                          title: 'About Ping',
                          subtitle: 'Version 1.0.0',
                          onTap: () {},
                        ),
                        _Divider(),
                        _Item(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const Gap(32),
                  GestureDetector(
                    onTap: _showDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.emergency.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.emergency.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.emergency,
                          ),
                          const Gap(8),
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              color: AppColors.emergency,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.emergency),
            const Gap(12),
            const Text('Delete Account'),
          ],
        ),
        content: const Text(
          'This action is permanent. All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _Item({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: titleColor ?? AppColors.textSecondary, size: 22),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Gap(2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary.withAlpha(100),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const Gap(14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withAlpha(80),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}
