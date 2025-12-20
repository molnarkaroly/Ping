import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ping/core/theme/app_theme.dart';
import 'package:ping/features/auth/domain/auth_service.dart';
import 'package:ping/features/auth/presentation/login_screen.dart';
import 'package:ping/features/auth/presentation/register_screen.dart';
import 'package:ping/features/dashboard/presentation/dashboard_screen.dart';
import 'package:ping/features/requests/presentation/requests_screen.dart';
import 'package:ping/features/safety/presentation/safety_screen.dart';
import 'package:ping/features/profile/presentation/profile_screen.dart';
import 'package:ping/features/search/presentation/search_screen.dart';
import 'package:ping/features/settings/presentation/settings_screen.dart';
import 'package:ping/core/widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with actual instance
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PingApp(),
    ),
  );
}

/// Global key for navigation
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider that depends on auth state
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn();
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and trying to access auth route
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null; // No redirect needed
    },
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

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
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class PingApp extends ConsumerWidget {
  const PingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ping',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
