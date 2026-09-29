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
        Text('Current movement levels',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Your current movement-specific levels used by adaptive workouts.',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        capabilityAsync.when(
          loading: () => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 12),
                  Text('Loading movement levels...', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Movement levels unavailable.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No capability profile yet. Complete onboarding to see levels.',
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
                patternLabel: pattern.label,
                level: profile.capabilityFor(pattern)?.level,
              ),
              if (pattern != CapabilityProfile.trainablePatterns.last) const Divider(height: 20),
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

  int _levelNumber(CapabilityLevel l) {
    switch (l) {
      case CapabilityLevel.level1:
        return 1;
      case CapabilityLevel.level2:
        return 2;
      case CapabilityLevel.level3:
        return 3;
      case CapabilityLevel.level4:
        return 4;
      case CapabilityLevel.level5:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelNumber = level != null ? _levelNumber(level!) : null;

    return Semantics(
      label: '$patternLabel Level ${levelNumber ?? 'unknown'}',
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(patternLabel,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(5, (i) {
                final isFilled = levelNumber != null && i < levelNumber;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
                    height: 8,
                    decoration: BoxDecoration(
                      color: isFilled ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              levelNumber != null ? 'Level $levelNumber' : '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
