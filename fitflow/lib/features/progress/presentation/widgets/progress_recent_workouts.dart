import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/workouts/domain/history/completed_workout.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
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
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TrainingHeading(l.recentWorkouts),
      const SizedBox(height: 12),
      for (final workout in widget.history.take(_visible)) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
              FitFlowLocaleFormat.formatDateTime(context, workout.completedAt),
              style: theme.textTheme.titleMedium),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.trainingHistoryCompleted),
                    Text(l.trainingHistoryCounts(
                        workout.totalExerciseCount, workout.totalSetCount)),
                    if (workout.estimatedDuration != null ||
                        workout.targetDuration != null)
                      Text(
                          '${workout.estimatedDuration != null ? l.trainingEstimatedDuration : l.trainingPlannedDuration}: ${FitFlowLocaleFormat.formatDuration(l, workout.estimatedDuration ?? workout.targetDuration!)}'),
                  ])),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              context.push(AppRoutes.progressHistoryDetail(workout.id)),
        ),
        const Divider(height: 1),
      ],
      if (widget.history.length > _visible)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextButton(
              onPressed: () => setState(() => _visible += 10),
              child: Text(l.trainingHistoryMore)),
        ),
    ]);
  }
}
