import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/main/presentation/main_shell.dart';
import 'package:fitflow/features/profile/presentation/profile_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:go_router/go_router.dart';

/// Centralized route definitions for the app.
class AppRouter {
  AppRouter._();

  /// The app-wide router instance.
  static final GoRouter router = _createRouter();

  static GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
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
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
