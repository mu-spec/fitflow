import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'progress_presentation.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';

class ProgressPeriodComparison extends StatelessWidget {
  const ProgressPeriodComparison(
      {super.key, required this.analytics, this.showHeading = true});

  final TrainingAnalytics analytics;
  final bool showHeading;

  String _formatDuration(Duration d) {
    final isNegative = d.isNegative;
    final abs = d.abs();
    final totalMinutes = abs.inMinutes;
    final seconds = abs.inSeconds % 60;
    String formatted;
    if (abs == Duration.zero) {
      formatted = '0 min';
    } else if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      formatted = mins == 0 ? '$hours' 'h' : '$hours' 'h $mins' 'm';
    } else if (totalMinutes > 0) {
      formatted =
          seconds == 0 ? '$totalMinutes min' : '$totalMinutes' 'm $seconds' 's';
    } else {
      formatted = '$seconds' 's';
    }
    return isNegative ? '-$formatted' : '+$formatted';
  }

  String _formatPlannedDelta(Duration delta) {
    if (delta == Duration.zero) return 'No change';
    return '${_formatDuration(delta)} planned';
  }

  String _formatWorkoutsDelta(BuildContext context, int delta) {
    return FitFlowLocaleFormat.formatWorkoutDelta(context.l10n, delta);
  }

  String _formatSetsDelta(int delta) {
    if (delta == 0) return 'No change';
    final sign = delta > 0 ? '+' : '';
    return '$sign$delta Main sets';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final workoutDelta = analytics.workoutDelta;
    final setsDelta = analytics.mainSetsDelta;
    final plannedDelta = analytics.plannedDurationDelta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading)
          Semantics(
            header: true,
            child: Text(
              context.l10n.progressComparisonTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: FitFlowSpace.xs),
        Text(
          context.l10n.progressComparisonHelp,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: FitFlowSpace.md),
        ProgressRows(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _ComparisonRow(
                label: context.l10n.trainingWorkouts,
                current: '${analytics.currentPeriod.workoutCount}',
                previous: '${analytics.previousPeriod.workoutCount}',
                delta: _formatWorkoutsDelta(context, workoutDelta),
                isPositive: workoutDelta > 0,
                isNegative: workoutDelta < 0,
              ),
              const Divider(height: FitFlowSpace.sm, indent: 0, endIndent: 0),
              _ComparisonRow(
                label: context.l10n.progressMainSets,
                current: '${analytics.currentPeriod.mainSets}',
                previous: '${analytics.previousPeriod.mainSets}',
                delta: _formatSetsDelta(setsDelta),
                isPositive: setsDelta > 0,
                isNegative: setsDelta < 0,
              ),
              const Divider(height: FitFlowSpace.sm, indent: 0, endIndent: 0),
              _ComparisonRow(
                label: context.l10n.progressPlannedTime,
                current:
                    _formatDuration(analytics.currentPeriod.plannedDuration)
                        .replaceFirst('+', ''),
                previous:
                    _formatDuration(analytics.previousPeriod.plannedDuration)
                        .replaceFirst('+', ''),
                delta: _formatPlannedDelta(plannedDelta),
                isPositive: plannedDelta > Duration.zero,
                isNegative: plannedDelta < Duration.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.delta,
    required this.isPositive,
    required this.isNegative,
  });

  final String label;
  final String current;
  final String previous;
  final String delta;
  final bool isPositive;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color deltaColor;
    IconData deltaIcon;
    if (isPositive) {
      deltaColor = colorScheme.primary;
      deltaIcon = Icons.trending_up;
    } else if (isNegative) {
      deltaColor = colorScheme.error;
      deltaIcon = Icons.trending_down;
    } else {
      deltaColor = colorScheme.onSurfaceVariant;
      deltaIcon = Icons.trending_flat;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: FitFlowSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: FitFlowSpace.md,
            runSpacing: FitFlowSpace.xxs,
            children: [
              Text(
                context.l10n.progressPreviousValue(previous),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                context.l10n.progressCurrentValue(current),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: FitFlowSpace.xxs),
          Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                ExcludeSemantics(
                    child: Icon(deltaIcon, size: 16, color: deltaColor)),
                Text(delta,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: deltaColor)),
              ]),
        ],
      ),
    );
  }
}
