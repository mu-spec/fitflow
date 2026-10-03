import 'package:fitflow/features/workouts/domain/recovery/movement_recovery_status.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/locale_format.dart';
import 'package:flutter/material.dart';

class ProgressRecoverySection extends StatelessWidget {
  const ProgressRecoverySection({
    super.key,
    required this.recoveryStatuses,
    required this.now,
  });

  final List<MovementRecoveryStatus> recoveryStatuses;
  final DateTime now;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Training recovery',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Based on your recent FitFlow training history, not a medical recovery measure.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('Based only on time since this movement appeared in your FitFlow workouts.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
        const SizedBox(height: 16),
        if (recoveryStatuses.where((s) => s.lastTrained != null).isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  'No recent training data. Complete workouts with different movements to see recovery.',
                  style: theme.textTheme.bodyMedium),
            ),
          )
        else
          ...recoveryStatuses.where((s) => s.lastTrained != null).map((status) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecoveryCard(
                status: status,
                friendlyLastTrained: _friendlyLastTrained(context, status.lastTrained),
              ),
            );
          }),
        if (recoveryStatuses.any((s) => s.lastTrained == null)) ...[
          const SizedBox(height: 16),
          Text('Movements not trained yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recoveryStatuses.where((s) => s.lastTrained == null).map((s) {
              return Chip(label: Text(s.movementPattern.label));
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.status, required this.friendlyLastTrained});
  final MovementRecoveryStatus status;
  final String friendlyLastTrained;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color categoryColor;
    switch (status.category) {
      case RecoveryCategory.trainedRecently:
        categoryColor = colorScheme.primary;
        break;
      case RecoveryCategory.resting:
        categoryColor = colorScheme.secondary;
        break;
      case RecoveryCategory.wellRested:
        categoryColor = colorScheme.tertiary;
        break;
      case RecoveryCategory.notTrainedRecently:
        categoryColor = colorScheme.onSurfaceVariant;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(status.movementPattern.label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status.category.label,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: categoryColor, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(friendlyLastTrained,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('${status.sessionsLast7Days} sessions • ${status.setsLast7Days} sets this week',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
