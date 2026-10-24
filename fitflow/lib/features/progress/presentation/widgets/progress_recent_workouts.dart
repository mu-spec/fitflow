import 'progress_presentation.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgressRecentWorkouts extends StatefulWidget {
  const ProgressRecentWorkouts({super.key, required this.history});

  final List<CompletedWorkout> history;

  @override
  State<ProgressRecentWorkouts> createState() => _ProgressRecentWorkoutsState();
}

class _ProgressRecentWorkoutsState extends State<ProgressRecentWorkouts> {
  int _visible = 10;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final visibleCount =
        widget.history.length < _visible ? widget.history.length : _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true,
            child: Text(l.recentWorkouts,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w500))),
        const SizedBox(height: FitFlowSpace.sm),
        Column(
          children: [
            for (var i = 0; i < visibleCount; i++) ...[
              _RecentWorkoutTile(
                rowKey: ValueKey<String>(
                  'progress_recent_workout_${widget.history[i].id}',
                ),
                workout: widget.history[i],
              ),
              if (i < visibleCount - 1 || widget.history.length > _visible)
                const Divider(
                  height: 1,
                  indent: 0,
                  endIndent: FitFlowSpace.md,
                ),
            ],
            if (widget.history.length > _visible)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FitFlowSpace.md,
                  vertical: FitFlowSpace.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: FitFlowSpace.sm,
                      ),
                    ),
                    onPressed: () => setState(() => _visible += 10),
                    child: Text(l.trainingHistoryMore),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecentWorkoutTile extends StatelessWidget {
  const _RecentWorkoutTile({required this.rowKey, required this.workout});

  final Key rowKey;
  final CompletedWorkout workout;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return ListTile(
      key: rowKey,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: FitFlowSpace.xs,
      ),
      minVerticalPadding: FitFlowSpace.xs,
      leading: Semantics(
        label: l.trainingHistoryCompleted,
        child: ExcludeSemantics(
            child: Icon(Icons.check_circle_outline_rounded,
                size: 24, color: theme.colorScheme.primary)),
      ),
      title: Text(
        FitFlowLocaleFormat.formatDateTime(context, workout.completedAt),
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitleTextStyle: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: FitFlowSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.trainingHistoryCounts(
              workout.totalExerciseCount,
              workout.totalSetCount,
            )),
            if (workout.estimatedDuration != null ||
                workout.targetDuration != null)
              Text(
                '${workout.estimatedDuration != null ? l.trainingEstimatedDuration : l.trainingPlannedDuration}: ${progressDuration(context, workout.estimatedDuration ?? workout.targetDuration!)}',
              ),
          ],
        ),
      ),
      trailing: const ExcludeSemantics(
        child: Icon(Icons.chevron_right_rounded),
      ),
      onTap: () => context.push(AppRoutes.progressHistoryDetail(workout.id)),
    );
  }
}
