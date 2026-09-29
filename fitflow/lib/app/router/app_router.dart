import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_screen.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/main/presentation/main_shell.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fitflow/features/profile/presentation/profile_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_history_detail_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/settings/presentation/settings_screen.dart';
import 'package:fitflow/features/splash/splash_screen.dart';
import 'package:fitflow/features/workout_player/presentation/custom_workout_player_screen.dart';
import 'package:fitflow/features/workout_player/presentation/workout_player_screen.dart';
import 'package:fitflow/features/workout_preview/presentation/workout_preview_screen.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_builder_screen.dart';
import 'package:fitflow/features/workouts/presentation/custom_workout_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_detail_screen.dart';
import 'package:fitflow/features/workouts/presentation/exercise_library_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_tree_family_screen.dart';
import 'package:fitflow/features/workouts/presentation/skill_trees_screen.dart';
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
        GoRoute(
          path: AppRoutes.capabilityAssessment,
          builder: (context, state) => const CapabilityAssessmentScreen(),
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
                  routes: [
                    GoRoute(
                      path: 'workout-preview',
                      builder: (context, state) => const WorkoutPreviewScreen(),
                      routes: [
                        GoRoute(
                          path: 'player',
                          builder: (context, state) =>
                              const WorkoutPlayerScreen(),
                        ),
                      ],
                    ),
                  ],
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
                      builder: (context, state) =>
                          const ExerciseLibraryScreen(),
                      routes: [
                        GoRoute(
                          path: ':exerciseId',
                          builder: (context, state) {
                            final exerciseId =
                                state.pathParameters['exerciseId']!;
                            return ExerciseDetailScreen(
                                exerciseId: exerciseId);
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'skill-trees',
                      builder: (context, state) => const SkillTreesScreen(),
                      routes: [
                        GoRoute(
                          path: ':familyId',
                          builder: (context, state) => SkillTreeFamilyScreen(
                            familyId: state.pathParameters['familyId']!,
                          ),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'custom/new',
                      builder: (context, state) =>
                          const CustomWorkoutBuilderScreen(),
                    ),
                    GoRoute(
                      path: 'custom/:workoutId',
                      builder: (context, state) {
                        final workoutId = state.pathParameters['workoutId']!;
                        return CustomWorkoutDetailScreen(workoutId: workoutId);
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) {
                            final workoutId =
                                state.pathParameters['workoutId']!;
                            return CustomWorkoutBuilderScreen(
                                workoutId: workoutId);
                          },
                        ),
                        GoRoute(
                          path: 'player',
                          builder: (context, state) {
                            final workoutId =
                                state.pathParameters['workoutId']!;
                            return CustomWorkoutPlayerScreen(
                                workoutId: workoutId);
                          },
                        ),
                      ],
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
                  routes: [
                    GoRoute(
                      path: 'history/:sessionId',
                      builder: (context, state) {
                        final sessionId = state.pathParameters['sessionId']!;
                        return ProgressHistoryDetailScreen(sessionId: sessionId);
                      },
                    ),
                  ],
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
