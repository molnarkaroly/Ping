import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ping/features/requests/presentation/requests_screen.dart';
import 'package:ping/features/safety/presentation/safety_screen.dart';
import 'package:ping/features/profile/presentation/profile_screen.dart';
import 'package:ping/features/search/presentation/search_screen.dart';
import 'package:ping/features/settings/presentation/settings_screen.dart';
import 'package:ping/core/widgets/main_shell.dart';

void main() {
  runApp(const ProviderScope(child: PingApp()));
}

final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    // Main shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/requests',
          builder: (context, state) => const RequestsScreen(),
        ),
        GoRoute(
          path: '/safety',
          builder: (context, state) => const SafetyScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    // Standalone routes (no bottom nav)
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class PingApp extends StatelessWidget {
  const PingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ping',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
