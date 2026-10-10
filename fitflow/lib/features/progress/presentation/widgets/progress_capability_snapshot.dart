import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressCapabilitySnapshot extends ConsumerWidget {
  const ProgressCapabilitySnapshot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final capabilityAsync = ref.watch(capabilityProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.trainingMovementSnapshot,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(context.l10n.trainingMovementHelp,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        capabilityAsync.when(
          loading: () => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(context.l10n.trainingMovementLoading,
                          style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.trainingMovementUnavailable,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.trainingMovementMissing,
                      style: theme.textTheme.bodyMedium),
                ),
              );
            }
            return _CapabilityGrid(profile: profile);
          },
        ),
      ],
    );
  }
}

class _CapabilityGrid extends StatelessWidget {
  const _CapabilityGrid({required this.profile});
  final CapabilityProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final pattern in CapabilityProfile.trainablePatterns) ...[
              _CapabilityRow(
                patternLabel: movementPatternLabel(context.l10n, pattern),
                level: profile.capabilityFor(pattern)?.level,
              ),
              if (pattern != CapabilityProfile.trainablePatterns.last)
                const Divider(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.patternLabel, required this.level});
  final String patternLabel;
  final CapabilityLevel? level;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(spacing: 12, runSpacing: 6, children: [
          Text(patternLabel, style: Theme.of(context).textTheme.titleSmall),
          Text(level == null
              ? context.l10n.trainingUnknown
              : trainingLevelLabel(context.l10n, level!)),
        ]),
      );
}
