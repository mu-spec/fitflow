import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/main/presentation/main_shell.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fitflow/features/profile/presentation/profile_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.create();
});

class AppRouter {
  AppRouter._();

  static GoRouter create() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.workouts,
                  builder: (context, state) => const WorkoutsScreen(),
                  routes: [
                    GoRoute(
                      path: 'exercise-library',
                      builder: (context, state) => const ExerciseLibraryScreen(),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.progress,
                  builder: (context, state) => const ProgressScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => const SettingsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
