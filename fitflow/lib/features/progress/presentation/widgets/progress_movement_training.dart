import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/progress/domain/training_analytics.dart';
import 'package:flutter/material.dart';

class ProgressMovementTraining extends StatelessWidget {
  const ProgressMovementTraining({super.key, required this.analytics});

  final TrainingAnalytics analytics;

  String _formatLastTrained(DateTime? last, DateTime now) {
    if (last == null) return 'Not trained in last 28 days';
    final diff = now.difference(last);
    if (diff.inMinutes < 60) {
      if (diff.inMinutes <= 1) return 'Last trained just now';
      return 'Last trained ${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      if (diff.inHours == 1) return 'Last trained 1 hour ago';
      return 'Last trained ${diff.inHours} hours ago';
    }
    if (diff.inDays == 0) return 'Last trained today';
    if (diff.inDays == 1) return 'Last trained yesterday';
    if (diff.inDays < 7) return 'Last trained ${diff.inDays} days ago';
    return 'Last trained ${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final movementData = analytics.movementAnalytics;
    final withData = movementData.where((m) => m.mainSets > 0).toList();
    final withoutData = movementData.where((m) => m.mainSets == 0).toList();

    final maxSets = withData.isEmpty
        ? 1
        : withData.map((m) => m.mainSets).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Movement training',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
          'Main-workout sets from your last 28 days.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: FitFlowSpace.md),
        if (withData.isEmpty)
          FitFlowV2InfoSurface(
            tonal: true,
            child: Text(
              'No Main movement training in last 28 days.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          FitFlowV2InfoSurface(
            padding: const EdgeInsets.all(FitFlowSpace.md),
            child: Column(
              children: [
                for (var i = 0; i < withData.length; i++) ...[
                  _MovementRow(
                    data: withData[i],
                    maxSets: maxSets,
                    now: analytics.now,
                    formatLast: _formatLastTrained,
                  ),
                  if (i != withData.length - 1)
                    const Divider(height: FitFlowSpace.xl),
                ],
              ],
            ),
          ),
        if (withoutData.isNotEmpty) ...[
          const SizedBox(height: FitFlowSpace.md),
          Semantics(
            header: true,
            child: Text(
              'Movements not trained yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(
            'No Main sets for these movements in last 28 days.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Wrap(
            spacing: FitFlowSpace.xs,
            runSpacing: FitFlowSpace.xs,
            children: withoutData
                .map((m) => FitFlowV2Tag(m.movementPattern.label))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.data,
    required this.maxSets,
    required this.now,
    required this.formatLast,
  });

  final MovementTrainingAnalytics data;
  final int maxSets;
  final DateTime now;
  final String Function(DateTime?, DateTime) formatLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fitFlowTheme = FitFlowTheme.of(context);
    final barWidthFactor = maxSets == 0 ? 0.0 : data.mainSets / maxSets;

    return Semantics(
      label:
          '${data.movementPattern.label}: ${data.mainSets} Main sets, ${data.sessions} sessions, ${formatLast(data.lastTrained, now)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.movementPattern.label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: FitFlowSpace.xs),
              Text(
                '${data.mainSets} sets',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: FitFlowSpace.xxs),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barWidthFactor,
                minHeight: 8,
                backgroundColor: fitFlowTheme.subtleSurface,
                color: fitFlowTheme.brand,
              ),
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final compact = constraints.maxWidth < 420 || textScale > 1.3;
              final sessions = Text(
                '${data.sessions} sessions',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              );
              final lastTrained = Text(
                formatLast(data.lastTrained, now),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: compact ? TextAlign.start : TextAlign.end,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sessions,
                    const SizedBox(height: FitFlowSpace.xxs),
                    lastTrained,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: sessions),
                  const SizedBox(width: FitFlowSpace.xs),
                  Expanded(child: lastTrained),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
