import 'widgets/progress_presentation.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
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
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chart-led overview; primary analytics are visible without disclosure.
/// Truthful offline analytics derived from real history + current capability snapshot.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const ProgressTheme(child: _ProgressContent());
}

class _ProgressContent extends ConsumerWidget {
  const _ProgressContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final visual = FitFlowVisualV2.of(context);

    return Material(
      color: visual.page,
      child: SafeArea(
        child: historyAsync.when(
          loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(FitFlowSpace.xl),
            child: FitFlowLoading(
              label: context.l10n.trainingHistoryLoading,
            ),
          ),
          error: (e, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FitFlowSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.trainingHistoryError),
                  TextButton(
                    onPressed: () =>
                        ref.read(workoutHistoryProvider.notifier).refresh(),
                    child: Text(context.l10n.trainingRetry),
                  ),
                ],
              ),
            ),
          ),
          data: (history) {
            final now = DateTime.now().toUtc();
            final analytics =
                TrainingAnalyticsEngine.calculate(history: history, now: now);
            final recoveryStatuses = TrainingRecoveryEngine.calculate(
              history: analytics.validWorkouts,
              now: now,
            );

            if (analytics.isEmpty) {
              return _progressOverviewScroll(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProgressOverviewHeader(),
                    const SizedBox(height: FitFlowSpace.xl),
                    const _ProgressEmptyState(),
                  ],
                ),
              );
            }

            return _progressOverviewScroll(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProgressOverviewHeader(showDeviceNote: false),
                  const SizedBox(height: 12),
                  ProgressSummaryCards(analytics: analytics),
                  const Divider(height: 24),
                  ProgressActivityChart(analytics: analytics),
                  const SizedBox(height: 12),
                  ProgressConsistency(analytics: analytics, showHeading: false),
                  const Divider(height: 32),
                  ProgressMovementTraining(analytics: analytics, compact: true),
                  const Divider(height: 32),
                  ProgressRecentWorkouts(
                      history: analytics.validWorkouts, initialCount: 3),
                  const Divider(height: 24),
                  ProgressDisclosure(
                    key: const Key('progress_more_details'),
                    title: context.l10n.progressMoreDetails,
                    children: [
                      Text(context.l10n.progressDeviceNote,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text(context.l10n.trainingPlannedNote,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      ProgressPeriodComparison(analytics: analytics),
                      const Divider(height: 32),
                      ProgressMovementTraining(analytics: analytics),
                      const Divider(height: 32),
                      const ProgressCapabilitySnapshot(),
                      const Divider(height: 32),
                      ProgressRecoverySection(
                          recoveryStatuses: recoveryStatuses, now: now),
                    ],
                  ),
                  const SizedBox(height: FitFlowSpace.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _progressOverviewScroll(Widget child) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: FitFlowSpace.screenHorizontal,
        vertical: FitFlowSpace.sm,
      ),
      child: FitFlowMaxWidth(
        maxWidth: FitFlowLayout.maxContentWidth,
        child: child,
      ),
    );

class _ProgressEmptyState extends StatelessWidget {
  const _ProgressEmptyState();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final colors = FitFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
            child:
                Icon(Icons.insights_outlined, size: 32, color: colors.brand)),
        const SizedBox(height: FitFlowSpace.md),
        Semantics(
          header: true,
          child: Text(
            l.noCompletedWorkouts,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: FitFlowSpace.xs),
        Text(
          l.finishWorkoutHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: FitFlowSpace.lg),
        Center(
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
            ),
            onPressed: () => context.go(AppRoutes.home),
            child: Text(l.startAWorkout),
          ),
        ),
      ],
    );
  }
}
