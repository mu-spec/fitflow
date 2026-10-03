import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/progress/domain/training_analytics_engine.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_activity_chart.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_capability_snapshot.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_consistency.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_movement_training.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_period_comparison.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recent_workouts.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_recovery_section.dart';
import 'package:fitflow/features/progress/presentation/widgets/progress_summary_cards.dart';
import 'package:fitflow/features/workouts/application/workout_history_controller.dart';
import 'package:fitflow/features/workouts/domain/recovery/training_recovery_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Polished Progress analytics dashboard – M14
/// Truthful offline analytics derived from real history + current capability snapshot.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
        data: (history) {
          final now = DateTime.now().toUtc();
          final analytics = TrainingAnalyticsEngine.calculate(history: history, now: now);
          final recoveryStatuses = TrainingRecoveryEngine.calculate(history: analytics.validWorkouts, now: now);

          // Empty state
          if (analytics.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.yourProgress,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(context.l10n.progressDeviceNote,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.insights_outlined,
                                size: 64, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(context.l10n.noCompletedWorkouts,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(context.l10n.finishWorkoutHint,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => context.go(AppRoutes.home),
                              child: Text(context.l10n.startAWorkout),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Capability snapshot may still be accessible in empty state
                      const ProgressCapabilitySnapshot(),
                      const SizedBox(height: 32),
                      // Recovery empty state
                      ProgressRecoverySection(recoveryStatuses: recoveryStatuses, now: now),
                    ],
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProgressSummaryCards(analytics: analytics),
                    const SizedBox(height: 32),
                    ProgressPeriodComparison(analytics: analytics),
                    const SizedBox(height: 32),
                    ProgressActivityChart(analytics: analytics),
                    const SizedBox(height: 32),
                    ProgressConsistency(analytics: analytics),
                    const SizedBox(height: 32),
                    ProgressMovementTraining(analytics: analytics),
                    const SizedBox(height: 32),
                    const ProgressCapabilitySnapshot(),
                    const SizedBox(height: 32),
                    ProgressRecoverySection(recoveryStatuses: recoveryStatuses, now: now),
                    const SizedBox(height: 32),
                    ProgressRecentWorkouts(history: analytics.validWorkouts),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
