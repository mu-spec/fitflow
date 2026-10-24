import 'progress_presentation.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/workouts/domain/recovery/movement_recovery_status.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';

class ProgressRecoverySection extends StatelessWidget {
  const ProgressRecoverySection({
    super.key,
    required this.recoveryStatuses,
    required this.now,
    this.showHeading = true,
  });

  final List<MovementRecoveryStatus> recoveryStatuses;
  final DateTime now;
  final bool showHeading;

  String _friendlyLastTrained(BuildContext context, DateTime? last) {
    final l10n = context.l10n;
    if (last == null) return l10n.lastTrainedNever;
    final diff = now.difference(last);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      if (mins <= 1) return l10n.lastTrainedJustNow;
      return l10n.lastTrainedMinutes(mins);
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      if (hours == 1) return l10n.lastTrainedOneHour;
      return l10n.lastTrainedHours(hours);
    }
    if (diff.inDays == 0) return l10n.lastTrainedToday;
    if (diff.inDays == 1) return l10n.lastTrainedYesterday;
    if (diff.inDays < 7) return l10n.lastTrainedDays(diff.inDays);
    return l10n.lastTrainedOn(
      FitFlowLocaleFormat.formatDate(MaterialLocalizations.of(context), last),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trainedStatuses =
        recoveryStatuses.where((s) => s.lastTrained != null).toList();
    final untrainedStatuses =
        recoveryStatuses.where((s) => s.lastTrained == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading)
          Semantics(
            header: true,
            child: Text(
              context.l10n.trainingRecoveryDetails,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
          context.l10n.progressRecoveryHelp,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: FitFlowSpace.md),
        if (trainedStatuses.isEmpty)
          ProgressRows(
            child: Text(
              'No recent training data. Complete workouts with different movements to see recovery.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ProgressRows(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < trainedStatuses.length; i++) ...[
                  _RecoveryRow(
                    status: trainedStatuses[i],
                    friendlyLastTrained: _friendlyLastTrained(
                      context,
                      trainedStatuses[i].lastTrained,
                    ),
                  ),
                  if (i != trainedStatuses.length - 1)
                    const Divider(
                      height: 1,
                      indent: 0,
                      endIndent: 0,
                    ),
                ],
              ],
            ),
          ),
        if (recoveryStatuses.any((s) => s.lastTrained == null)) ...[
          const SizedBox(height: FitFlowSpace.md),
          Semantics(
            header: true,
            child: Text(
              'Movements not trained yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(
              untrainedStatuses
                  .map((status) => status.movementPattern.label)
                  .join(' · '),
              style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  const _RecoveryRow({
    required this.status,
    required this.friendlyLastTrained,
  });

  final MovementRecoveryStatus status;
  final String friendlyLastTrained;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: FitFlowSpace.xs,
            runSpacing: FitFlowSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                status.movementPattern.label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(status.category.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Text(
            friendlyLastTrained,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(
            '${status.sessionsLast7Days} sessions • ${status.setsLast7Days} sets this week',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
