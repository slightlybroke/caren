import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/assist/presentation/assist_landing_screen.dart';
import '../../features/assist/presentation/assist_session_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/registration_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/main_scaffold_screen.dart';
import '../../features/family/presentation/daily_check_in_screen.dart';
import '../../features/family/presentation/family_dashboard_screen.dart';
import '../../features/family/presentation/family_member_detail_screen.dart';
import '../../features/family/presentation/family_member_list_screen.dart';
import '../../features/family/presentation/wellness_report_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/profile/presentation/privacy_permissions_screen.dart';
import '../../features/profile/presentation/profile_settings_screen.dart';
import '../../features/wellness/presentation/guided_breathing_screen.dart';
import '../../features/wellness/presentation/me_dashboard_screen.dart';
import '../../features/wellness/presentation/personal_history_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // 1. Splash Screen
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // 2. Welcome / Onboarding Screen
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // 3. Login Screen
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // 4. Registration Screen
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),

    // 5. Main CAREN Dashboard Screen (Home Entry)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),

    // 16. Profile and Settings Screen
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSettingsScreen(),
      routes: [
        // 17. Privacy and Sharing Permissions Screen
        GoRoute(
          path: 'privacy',
          builder: (context, state) => const PrivacyPermissionsScreen(),
        ),
      ],
    ),

    // Subroutes that can be pushed on top of root navigator
    GoRoute(
      path: '/family/check-in',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DailyCheckInScreen(),
    ),
    GoRoute(
      path: '/family/members',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FamilyMemberListScreen(),
    ),
    GoRoute(
      path: '/family/member/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return FamilyMemberDetailScreen(memberId: id);
      },
    ),
    GoRoute(
      path: '/family/report/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return WellnessReportScreen(reportId: id);
      },
    ),
    GoRoute(
      path: '/me/breathing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final durationParam = state.uri.queryParameters['duration'];
        final duration = int.tryParse(durationParam ?? '3') ?? 3;
        return GuidedBreathingScreen(initialDurationMinutes: duration);
      },
    ),
    GoRoute(
      path: '/me/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PersonalHistoryScreen(),
    ),
    GoRoute(
      path: '/assist/session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sessionId = state.uri.queryParameters['sessionId'];
        return AssistSessionScreen(sessionId: sessionId);
      },
    ),

    // Main Stateful Bottom Navigation Shell (Family, Me, Assist)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffoldScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab Branch 0: Family Experience
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/family',
              builder: (context, state) => const FamilyDashboardScreen(),
            ),
          ],
        ),

        // Tab Branch 1: Me Experience
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/me',
              builder: (context, state) => const MeDashboardScreen(),
            ),
          ],
        ),

        // Tab Branch 2: Assist Experience
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/assist',
              builder: (context, state) => const AssistLandingScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

