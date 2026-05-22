import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/pin_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/savings/presentation/screens/savings_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/planning/presentation/screens/planning_screen.dart';
import '../../features/time_tracking/presentation/screens/time_tracking_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/learning/presentation/screens/learning_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/skills/presentation/screens/skills_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/diary/presentation/screens/diary_screen.dart';
import '../../features/vault/presentation/screens/vault_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../storage/hive_storage.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: HiveStorage.isLoggedIn ? '/dashboard' : '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/pin', builder: (_, __) => const PinScreen()),
      GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/finance', builder: (_, __) => const FinanceScreen()),
          GoRoute(path: '/savings', builder: (_, __) => const SavingsScreen()),
          GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
          GoRoute(path: '/planning', builder: (_, __) => const PlanningScreen()),
          GoRoute(path: '/time', builder: (_, __) => const TimeTrackingScreen()),
          GoRoute(path: '/health', builder: (_, __) => const HealthScreen()),
          GoRoute(path: '/rewards', builder: (_, __) => const RewardsScreen()),
          GoRoute(path: '/learning', builder: (_, __) => const LearningScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/skills', builder: (_, __) => const SkillsScreen()),
          GoRoute(path: '/nutrition', builder: (_, __) => const NutritionScreen()),
          GoRoute(path: '/diary', builder: (_, __) => const DiaryScreen()),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = HiveStorage.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
  );
});
