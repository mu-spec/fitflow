import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/backup/presentation/backup_restore_screen.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_screen.dart';
import 'package:fitflow/features/home/presentation/home_screen.dart';
import 'package:fitflow/features/main/presentation/main_shell.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fitflow/features/profile/presentation/equipment_editor_screen.dart';
import 'package:fitflow/features/profile/presentation/fitness_profile_editor_screen.dart';
import 'package:fitflow/features/profile/presentation/profile_screen.dart';
import 'package:fitflow/features/profile/presentation/workout_preferences_editor_screen.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_player_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_history_detail_screen.dart';
import 'package:fitflow/features/progress/presentation/progress_screen.dart';
import 'package:fitflow/features/settings/presentation/privacy_policy_screen.dart';
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

  /// [initialLocation] defaults to the splash start gate; tests may start
  /// directly on a nested route.
  static GoRouter create({String initialLocation = AppRoutes.splash}) {
    return GoRouter(
      initialLocation: initialLocation,
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
                      path: 'programs',
                      builder: (context, state) =>
                          const ProgramsOverviewScreen(),
                      routes: [
                        GoRoute(
                          path: ':programId',
                          builder: (context, state) => ProgramDetailScreen(
                            programId: state.pathParameters['programId']!,
                          ),
                          routes: [
                            GoRoute(
                              path: 'session/:sessionId',
                              builder: (context, state) =>
                                  ProgramSessionPreviewScreen(
                                programId: state.pathParameters['programId']!,
                                sessionId: state.pathParameters['sessionId']!,
                              ),
                              routes: [
                                GoRoute(
                                  path: 'player',
                                  builder: (context, state) =>
                                      ProgramSessionPlayerScreen(
                                    programId:
                                        state.pathParameters['programId']!,
                                    sessionId:
                                        state.pathParameters['sessionId']!,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                      path: 'fitness-profile',
                      builder: (context, state) =>
                          const FitnessProfileEditorScreen(),
                    ),
                    GoRoute(
                      path: 'equipment',
                      builder: (context, state) =>
                          const EquipmentEditorScreen(),
                    ),
                    GoRoute(
                      path: 'workout-preferences',
                      builder: (context, state) =>
                          const WorkoutPreferencesEditorScreen(),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => const SettingsScreen(),
                      routes: [
                        GoRoute(
                          path: 'backup-restore',
                          builder: (context, state) =>
                              const BackupRestoreScreen(),
                        ),
                        GoRoute(
                          path: 'privacy-policy',
                          builder: (context, state) =>
                              const PrivacyPolicyScreen(),
                        ),
                      ],
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
