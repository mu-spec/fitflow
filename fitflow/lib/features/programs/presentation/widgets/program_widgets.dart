import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/presentation/program_copy.dart';
import 'package:flutter/material.dart';

/// Small tonal tag, e.g. "Matches your selected goal" or "Active program".
class ProgramTag extends StatelessWidget {
  const ProgramTag({
    super.key,
    required this.label,
    this.icon,
    this.emphasized = false,
  });

  final String label;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = emphasized ? colors.primaryContainer : colors.secondaryContainer;
    final fg =
        emphasized ? colors.onPrimaryContainer : colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip for a planned session: Completed / Next / Planned.
class ProgramSessionStatusChip extends StatelessWidget {
  const ProgramSessionStatusChip({super.key, required this.status});

  final AdaptiveProgramSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    switch (status) {
      case AdaptiveProgramSessionStatus.completed:
        bg = colors.tertiaryContainer;
        fg = colors.onTertiaryContainer;
        icon = Icons.check_circle_outline;
      case AdaptiveProgramSessionStatus.next:
        bg = colors.primaryContainer;
        fg = colors.onPrimaryContainer;
        icon = Icons.play_circle_outline;
      case AdaptiveProgramSessionStatus.planned:
        bg = colors.surfaceContainerHighest;
        fg = colors.onSurfaceVariant;
        icon = Icons.radio_button_unchecked;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Factual completion label + bar, e.g. "5 of 12 workouts completed".
class ProgramCompletionBar extends StatelessWidget {
  const ProgramCompletionBar({super.key, required this.status});

  final AdaptiveProgramStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status.completionLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: status.completionFraction,
            minHeight: 8,
            semanticsLabel: status.completionLabel,
          ),
        ),
      ],
    );
  }
}

/// Compact structural facts: weeks • sessions/week • total workouts.
class ProgramStructureLine extends StatelessWidget {
  const ProgramStructureLine({super.key, required this.definition});

  final AdaptiveProgramDefinition definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${ProgramCopy.weeksLabel(definition.weekCount)} • '
      '${ProgramCopy.perWeekLabel(definition.sessionsPerWeek)} • '
      '${ProgramCopy.totalLabel(definition.totalSessionCount)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Row for a planned session inside program detail.
class ProgramSessionRow extends StatelessWidget {
  const ProgramSessionRow({
    super.key,
    required this.session,
    required this.status,
    required this.onView,
  });

  final AdaptiveProgramSession session;
  final AdaptiveProgramSessionStatus status;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Session ${session.session}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  ProgramSessionStatusChip(status: status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${session.focus} • Goal: ${session.generationGoal.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text(ProgramCopy.viewWorkout),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic "not found" body for unknown program/session IDs.
class ProgramNotFoundBody extends StatelessWidget {
  const ProgramNotFoundBody({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined,
                size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialogs with the exact spec copy.
class ProgramDialogs {
  ProgramDialogs._();

  static Future<bool> confirmSwitch(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(ProgramCopy.switchDialogTitle),
        content: const Text(ProgramCopy.switchDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(ProgramCopy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(ProgramCopy.switchDialogConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }

  static Future<bool> confirmRestart(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(ProgramCopy.restartDialogTitle),
        content: const Text(ProgramCopy.restartDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(ProgramCopy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(ProgramCopy.restartDialogConfirm),
          ),
        ],
      ),
    );
    return result == true;
  }
}
