import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact control showing current mode and Adjust action.
class HomeSessionModeControl extends ConsumerWidget {
  const HomeSessionModeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(workoutSessionModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.tune_outlined, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's workout",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showModeSheet(context, ref),
              child: const Text('Adjust'),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return const ChooseWorkoutModeSheet();
      },
    );
  }
}

/// Bottom sheet Choose today's workout.
class ChooseWorkoutModeSheet extends ConsumerWidget {
  const ChooseWorkoutModeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(workoutSessionModeProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose today's workout",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _ModeOptionTile(
                mode: WorkoutSessionMode.standard,
                title: 'Standard',
                subtitle: 'Your normal adaptive workout',
                isSelected: current == WorkoutSessionMode.standard,
                onTap: () {
                  ref.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.standard);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _ModeOptionTile(
                mode: WorkoutSessionMode.lowEnergy,
                title: 'Low Energy',
                subtitle: 'A shorter, easier workout for today',
                supportingNote: "This doesn't change your movement levels",
                isSelected: current == WorkoutSessionMode.lowEnergy,
                onTap: () {
                  ref.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.lowEnergy);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _ModeOptionTile(
                mode: WorkoutSessionMode.comeback,
                title: 'Comeback',
                subtitle: 'A gentler return workout after time away',
                supportingNote: "This doesn't change your movement levels",
                isSelected: current == WorkoutSessionMode.comeback,
                onTap: () {
                  ref.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.mode,
    required this.title,
    required this.subtitle,
    this.supportingNote,
    required this.isSelected,
    required this.onTap,
  });

  final WorkoutSessionMode mode;
  final String title;
  final String subtitle;
  final String? supportingNote;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
        ),
        child: Row(
          children: [
            RadioGroup<bool>(
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              child: const Radio<bool>(value: true),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  if (supportingNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      supportingNote!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comeback suggestion card shown when policy returns true.
class ComebackSuggestionCard extends ConsumerWidget {
  const ComebackSuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restart_alt_outlined, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Returning after some time away? Comeback gives you a shorter, gentler session without changing your movement levels.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () {
                  ref.read(workoutSessionModeProvider.notifier).selectMode(WorkoutSessionMode.comeback);
                },
                child: const Text('Use Comeback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
