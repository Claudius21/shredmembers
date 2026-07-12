import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/plans/plans_screen.dart';
import '../screens/plans/plan_edit_screen.dart';
import '../screens/workout/workout_detail_screen.dart';
import '../screens/workout/workout_tracking_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/progress/personal_records_screen.dart';
import '../screens/progress/pr_diary_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/subscription/paywall_screen.dart';
import '../screens/subscription/payment_success_screen.dart';
import '../screens/subscription/payment_cancel_screen.dart';
import '../screens/subscription/subscription_management_screen.dart';
import '../screens/auth/auth_callback_screen.dart';
import '../widgets/layout/main_scaffold.dart';
import '../models/workout_plan.dart';
import '../providers/subscription_provider.dart';

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String plans = '/plans';
  static const String workoutDetail = '/plans/detail';
  static const String planEdit = '/plans/edit';
  static const String workoutTracking = '/tracking';
  static const String progress = '/progress';
  static const String personalRecords = '/progress/personal-records';
  static const String prDiary = '/progress/pr-diary';
  static const String profile = '/profile';
  static const String paywall = '/subscription/paywall';
  static const String subscriptionManage = '/subscription/manage';
  static const String paymentSuccess = '/payment/success';
  static const String paymentCancel = '/payment/cancel';
  static const String authCallback = '/auth/callback';
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen<SubscriptionState>(subscriptionProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    refreshListenable: notifier,
    redirect: (context, state) {
      // Normalize custom scheme deep links (e.g. shredmembers://payment/success?session_id=...)
      final uri = state.uri;
      if (uri.scheme == 'shredmembers' && uri.host.isNotEmpty) {
        final deepLinkPath = '/${uri.host}${uri.path.isEmpty ? '' : uri.path}';
        if (deepLinkPath != state.matchedLocation) {
          return Uri(
            path: deepLinkPath,
            queryParameters: uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
          ).toString();
        }
      }

      final authState = ref.read(authProvider);

      // Still restoring session – don't redirect yet
      if (authState.status == AuthStatus.loading) return null;

      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.onboarding;

      // Subscription-Check: Bei abgelaufenem Trial zu Paywall
      if (isAuthenticated) {
        final subState = ref.read(subscriptionProvider);
        final isPaywallRoute = state.matchedLocation == AppRoutes.paywall;
        
        // Wenn kein Zugriff und nicht auf Paywall -> redirect zu Paywall
        if (!subState.hasAccess && !isPaywallRoute) {
          return AppRoutes.paywall;
        }
        
        // Wenn aktives (bezahltes) Abo und auf Paywall -> redirect zu Home
        if (subState.isActiveSubscription && isPaywallRoute) {
          return AppRoutes.home;
        }
      }

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.plans,
            builder: (context, state) => const PlansScreen(),
          ),
          GoRoute(
            path: AppRoutes.progress,
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: AppRoutes.personalRecords,
            builder: (context, state) => const PersonalRecordsScreen(),
          ),
          GoRoute(
            path: AppRoutes.prDiary,
            builder: (context, state) => const PRDiaryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.planEdit,
        builder: (context, state) {
          final plan = state.extra as WorkoutPlan;
          return PlanEditScreen(plan: plan);
        },
      ),
      GoRoute(
        path: AppRoutes.workoutDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WorkoutDetailScreen(
            plan: extra['plan'] as WorkoutPlan,
            dayIndex: extra['dayIndex'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.workoutTracking,
        builder: (context, state) => const WorkoutTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionManage,
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) => PaymentSuccessScreen(
          sessionId: state.uri.queryParameters['session_id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentCancel,
        builder: (context, state) => const PaymentCancelScreen(),
      ),
      GoRoute(
        path: AppRoutes.authCallback,
        builder: (context, state) => AuthCallbackScreen(
          token: state.uri.queryParameters['token'],
          type: state.uri.queryParameters['type'],
          accessToken: state.uri.queryParameters['access_token'],
          refreshToken: state.uri.queryParameters['refresh_token'],
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
