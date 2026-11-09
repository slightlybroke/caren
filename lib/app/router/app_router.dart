import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/registration_screen.dart';
import '../../features/dashboard/presentation/main_scaffold_screen.dart';
import '../../features/diagnostics/presentation/diagnostics_screen.dart';
import '../../features/emergency/presentation/emergency_landing_screen.dart';
import '../../features/emergency/presentation/emergency_session_screen.dart';
import '../../features/family/presentation/daily_check_in_screen.dart';
import '../../features/family/presentation/family_dashboard_screen.dart';
import '../../features/family/presentation/family_member_detail_screen.dart';
import '../../features/family/presentation/family_member_list_screen.dart';
import '../../features/family/presentation/wellness_report_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/profile/presentation/privacy_permissions_screen.dart';
import '../../features/profile/presentation/profile_settings_screen.dart';
import '../../features/wellness/domain/wellness_activity.dart';
import '../../features/wellness/presentation/camera_positioning_screen.dart';
import '../../features/wellness/presentation/guided_activity_screen.dart';
import '../../features/wellness/presentation/guided_breathing_screen.dart';
import '../../features/wellness/presentation/me_dashboard_screen.dart';
import '../../features/wellness/presentation/personal_history_screen.dart';
import '../../services/vitals/vitals_models.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds routes list for CAREN
List<RouteBase> _buildRoutes() {
  return [
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

    // Legacy / Convenience Dashboard Redirect -> /family
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) => '/family',
    ),

    // Legacy / Convenience Assist Redirect -> /emergency
    GoRoute(
      path: '/assist',
      redirect: (context, state) => '/emergency',
    ),
    GoRoute(
      path: '/assist/session',
      redirect: (context, state) {
        final sessionId = state.uri.queryParameters['sessionId'];
        return sessionId != null ? '/emergency/session?sessionId=$sessionId' : '/emergency/session';
      },
    ),

    // Developer Diagnostics Screen (Direct SDK and Hardware Verification)
    GoRoute(
      path: '/diagnostics',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DiagnosticsScreen(),
    ),

    // Profile and Settings Screen
    GoRoute(
      path: '/profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSettingsScreen(),
      routes: [
        GoRoute(
          path: 'privacy',
          builder: (context, state) => const PrivacyPermissionsScreen(),
        ),
      ],
    ),

    // Child routes that can be pushed on top of root navigator
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
        final duration = int.tryParse(durationParam ?? '2') ?? 2;
        return GuidedBreathingScreen(initialDurationMinutes: duration);
      },
    ),
    GoRoute(
      path: '/me/activity/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final activity = WellnessCatalog.findById(id) ??
            WellnessCatalog.fiveSensesGrounding;
        return GuidedActivityScreen(activity: activity);
      },
    ),
    GoRoute(
      path: '/me/camera-check',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const CameraPositioningScreen(
          title: 'Camera Wellness Check',
          target: MeasurementTarget.pulseOnly,
        );
      },
    ),
    GoRoute(
      path: '/family/camera-check',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const CameraPositioningScreen(
          title: 'Family Spot-Check',
          target: MeasurementTarget.pulseOnly,
        );
      },
    ),
    GoRoute(
      path: '/me/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PersonalHistoryScreen(),
    ),
    GoRoute(
      path: '/emergency/session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sessionId = state.uri.queryParameters['sessionId'];
        return EmergencySessionScreen(sessionId: sessionId);
      },
    ),

    // Main Stateful Bottom Navigation Shell (Family, Me, Emergency)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffoldScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab Branch 0: Family Experience (Primary landing destination)
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

        // Tab Branch 2: Emergency Experience
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/emergency',
              builder: (context, state) => const EmergencyLandingScreen(),
            ),
          ],
        ),
      ],
    ),
  ];
}

/// Dynamic GoRouter configured with authentication guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authUser = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuth = authUser != null;

      final isPublic = loc == '/splash' ||
          loc == '/onboarding' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/diagnostics';

      // If unauthenticated and trying to access a protected screen, redirect to login
      if (!isAuth && !isPublic) {
        return '/login';
      }

      // If authenticated and trying to access login/register/dashboard, redirect to /family
      if (isAuth && (loc == '/login' || loc == '/register' || loc == '/dashboard')) {
        return '/family';
      }

      return null;
    },
    routes: _buildRoutes(),
  );
});

/// Direct compatibility instance of GoRouter without auth guards (e.g. for standalone widget tests)
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: _buildRoutes(),
);
