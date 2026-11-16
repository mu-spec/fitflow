import 'package:fitflow/core/design/widgets/fitflow_section_card.dart';
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

class _ProgressContent extends ConsumerStatefulWidget {
  const _ProgressContent();
  @override
  ConsumerState<_ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends ConsumerState<_ProgressContent> {
  int _tab = 0;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            final l = context.l10n;
            return SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: FitFlowMaxWidth(
                  maxWidth: FitFlowLayout.maxContentWidth,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ProgressOverviewHeader(showDeviceNote: false),
                        const SizedBox(height: 20),
                        if (!analytics.isEmpty)
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (var i = 0; i < 3; i++)
                              ChoiceChip(
                                  key: ValueKey('report_tab_$i'),
                                  label: Text([
                                    l.reportOverview,
                                    l.reportHistory,
                                    l.reportTraining
                                  ][i]),
                                  selected: _tab == i,
                                  onSelected: (_) {
                                    setState(() => _tab = i);
                                    if (_scroll.hasClients) _scroll.jumpTo(0);
                                  }),
                          ]),
                        const SizedBox(height: 20),
                        if (analytics.isEmpty) ...[
                          const FitFlowSectionCard(
                              child: _ProgressEmptyState()),
                        ] else if (_tab == 0) ...[
                          FitFlowSectionCard(
                              child:
                                  ProgressSummaryCards(analytics: analytics)),
                          FitFlowSectionCard(
                              child:
                                  ProgressActivityChart(analytics: analytics)),
                          FitFlowSectionCard(
                              child: ProgressConsistency(
                                  analytics: analytics, showHeading: false)),
                          FitFlowSectionCard(
                              child: ProgressRecentWorkouts(
                                  history: analytics.validWorkouts,
                                  initialCount: 1)),
                          Text(l.trainingPlannedNote,
                              style: Theme.of(context).textTheme.bodySmall),
                        ] else if (_tab == 1) ...[
                          FitFlowSectionCard(
                              child: ProgressRecentWorkouts(
                                  history: analytics.validWorkouts)),
                        ] else ...[
                          FitFlowSectionCard(
                              child: ProgressPeriodComparison(
                                  analytics: analytics)),
                          FitFlowSectionCard(
                              child: ProgressMovementTraining(
                                  analytics: analytics)),
                          FitFlowSectionCard(
                              child: ProgressDisclosure(
                                  title: l.utilityMovementTitle,
                                  children: [
                                const ProgressCapabilitySnapshot()
                              ])),
                          FitFlowSectionCard(
                              child: ProgressDisclosure(
                                  title: l.trainingRecoveryDetails,
                                  children: [
                                ProgressRecoverySection(
                                    recoveryStatuses: recoveryStatuses,
                                    now: now,
                                    showHeading: false)
                              ])),
                          Text(l.trainingPlannedNote,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ])),
            );
          },
        ),
      ),
    );
  }
}

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
