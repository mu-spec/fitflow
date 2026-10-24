import 'progress_presentation.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/workouts/presentation/widgets/training_presentation.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressCapabilitySnapshot extends ConsumerWidget {
  const ProgressCapabilitySnapshot({super.key, this.showHeading = true});
  final bool showHeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final capabilityAsync = ref.watch(capabilityProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading)
          Semantics(
            header: true,
            child: Text(
              context.l10n.trainingMovementSnapshot,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: FitFlowSpace.xxs),
        Text(
          context.l10n.trainingMovementHelp,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: FitFlowSpace.md),
        capabilityAsync.when(
          loading: () =>
              FitFlowLoading(label: context.l10n.trainingMovementLoading),
          error: (e, _) => FitFlowErrorState(
              title: context.l10n.trainingMovementUnavailable,
              message: context.l10n.utilityRetryBody,
              action: TextButton(
                  onPressed: () => ref.invalidate(capabilityProfileProvider),
                  child: Text(context.l10n.retry))),
          data: (profile) {
            if (profile == null) {
              return ProgressRows(
                child: Text(
                  context.l10n.trainingMovementMissing,
                  style: theme.textTheme.bodyMedium,
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
    return ProgressRows(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final pattern in CapabilityProfile.trainablePatterns) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: FitFlowSpace.xs,
              ),
              child: _CapabilityRow(
                patternLabel: movementPatternLabel(context.l10n, pattern),
                level: profile.capabilityFor(pattern)?.level,
              ),
            ),
            if (pattern != CapabilityProfile.trainablePatterns.last)
              const Divider(
                height: 1,
                indent: 0,
                endIndent: 0,
              ),
          ],
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.patternLabel, required this.level});
  final String patternLabel;
  final CapabilityLevel? level;

  @override
  Widget build(BuildContext context) => ProgressLabelValue(
        label: patternLabel,
        value: level == null
            ? context.l10n.trainingUnknown
            : trainingLevelLabel(context.l10n, level!),
      );
}
