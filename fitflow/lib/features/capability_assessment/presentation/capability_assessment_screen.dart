import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_answer.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_item.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_state.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/capability_level_description.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Dedicated first-run movement capability assessment.
///
/// Title: Movement Check
/// Supporting text: Your workouts adapt to each movement separately. Review these
/// starting levels and change anything that doesn't feel right.
class CapabilityAssessmentScreen extends ConsumerStatefulWidget {
  const CapabilityAssessmentScreen({super.key});

  @override
  ConsumerState<CapabilityAssessmentScreen> createState() =>
      _CapabilityAssessmentScreenState();
}

class _CapabilityAssessmentScreenState
    extends ConsumerState<CapabilityAssessmentScreen> {
  CapabilityAssessmentState? _assessmentState;
  CapabilityAssessmentState? _initialState;
  bool _isSaving = false;
  String? _errorMessage;
  bool _hasInitialized = false;

  void _updateLevel(MovementPattern pattern, CapabilityLevel newLevel) {
    if (_assessmentState == null) return;
    final answer = CapabilityAssessmentAnswer(
      movementPattern: pattern,
      selectedLevel: newLevel,
    );
    setState(() {
      _assessmentState = _assessmentState!.withAnswer(answer);
      _errorMessage = null;
    });
  }

  Future<void> _saveAndContinue() async {
    if (_assessmentState == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final now = DateTime.now().toUtc();
    final profile = _assessmentState!.toCapabilityProfile(updatedAt: now);

    if (profile == null) {
      setState(() {
        _isSaving = false;
        _errorMessage =
            'Could not create capability profile. Please review your selections and try again.';
      });
      return;
    }

    bool saved = false;
    try {
      saved = await ref
          .read(capabilityProfileProvider.notifier)
          .saveProfile(profile);
    } on Object {
      saved = false;
    }

    if (!mounted) return;

    if (!saved) {
      setState(() {
        _isSaving = false;
        _errorMessage =
            'Failed to save your movement profile. Please try again.';
      });
      return;
    }

    // Success → Home, using go not push, so back doesn't return to assessment
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);

    final isUserLoading = userProfileAsync.isLoading;
    final isCapabilityLoading = capabilityProfileAsync.isLoading;

    if (isUserLoading || isCapabilityLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final userProfile = userProfileAsync.valueOrNull;
    final capabilityProfile = capabilityProfileAsync.valueOrNull;

    // If capability already exists and valid, navigate to Home
    if (capabilityProfile != null &&
        capabilityProfile.isValid &&
        capabilityProfile.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If user profile is null, recovery to onboarding
    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movement Check')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  'We could not find your fitness profile.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please complete onboarding first.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.onboarding),
                  child: const Text('Go to Onboarding'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initialize assessment state once from experience
    if (!_hasInitialized) {
      final initial =
          CapabilityAssessmentState.fromExperienceLevel(userProfile.experience);
      _assessmentState = initial;
      _initialState = initial;
      _hasInitialized = true;
    }

    final assessmentState = _assessmentState!;
    final initialState = _initialState!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(AppRoutes.onboarding);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Movement Check'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.onboarding),
            tooltip: 'Back to onboarding',
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Movement Check',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your workouts adapt to each movement separately. Review these starting levels and change anything that doesn\'t feel right.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Starting from your training experience — adjust any movement below.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressSummary(context, assessmentState),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: CapabilityAssessmentCatalog.all.length,
                itemBuilder: (context, index) {
                  final item = CapabilityAssessmentCatalog.all[index];
                  final currentAnswer =
                      assessmentState.answerFor(item.movementPattern);
                  final initialAnswer =
                      initialState.answerFor(item.movementPattern);
                  final isChanged = currentAnswer != null &&
                      initialAnswer != null &&
                      currentAnswer.selectedLevel !=
                          initialAnswer.selectedLevel;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: _MovementAssessmentCard(
                      key: ValueKey(
                          'assessment_card_${item.movementPattern.name}'),
                      item: item,
                      currentLevel: currentAnswer?.selectedLevel ??
                          CapabilityLevel.level3,
                      initialLevel: initialAnswer?.selectedLevel,
                      isChanged: isChanged,
                      onLevelSelected: (level) =>
                          _updateLevel(item.movementPattern, level),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Summary',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      _buildCompactSummary(context, assessmentState),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('save_and_continue_button'),
                        onPressed: _isSaving ? null : _saveAndContinue,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save & Continue'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These starting levels help FitFlow personalize your workouts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary(
      BuildContext context, CapabilityAssessmentState state) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          '${state.answeredCount} of ${CapabilityAssessmentState.totalCount} movements ready',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: state.answeredCount / CapabilityAssessmentState.totalCount,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummary(
      BuildContext context, CapabilityAssessmentState state) {
    final parts = <String>[];
    for (final item in CapabilityAssessmentCatalog.all) {
      final answer = state.answerFor(item.movementPattern);
      if (answer != null) {
        final patternLabel = _shortLabelForPattern(item.movementPattern);
        final levelNumber = answer.selectedLevel.index + 1;
        parts.add('$patternLabel L$levelNumber');
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: parts
            .map(
              (p) => Chip(
                label: Text(
                  p,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
            .toList(),
      ),
    );
  }

  String _shortLabelForPattern(MovementPattern pattern) {
    switch (pattern) {
      case MovementPattern.push:
        return 'Push';
      case MovementPattern.pull:
        return 'Pull';
      case MovementPattern.squat:
        return 'Squat';
      case MovementPattern.lunge:
        return 'Lunge';
      case MovementPattern.hinge:
        return 'Hinge';
      case MovementPattern.core:
        return 'Core';
      case MovementPattern.glute:
        return 'Glute';
      case MovementPattern.cardio:
        return 'Cardio';
      case MovementPattern.mobility:
        return 'Mobility';
      case MovementPattern.balance:
        return 'Balance';
      case MovementPattern.warmup:
        return 'Warmup';
      case MovementPattern.cooldown:
        return 'Cooldown';
    }
  }
}

class _MovementAssessmentCard extends StatelessWidget {
  const _MovementAssessmentCard({
    super.key,
    required this.item,
    required this.currentLevel,
    this.initialLevel,
    required this.isChanged,
    required this.onLevelSelected,
  });

  final CapabilityAssessmentItem item;
  final CapabilityLevel currentLevel;
  final CapabilityLevel? initialLevel;
  final bool isChanged;
  final ValueChanged<CapabilityLevel> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isChanged
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isChanged ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.prompt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (initialLevel != null && !isChanged)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Suggested from your experience',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                if (isChanged)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Changed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Examples:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                for (var i = 0; i < item.examples.length; i++) ...[
                  Text(
                    item.examples[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (i != item.examples.length - 1)
                    Text(
                      '•',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level ${currentLevel.index + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentLevel.assessmentTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentLevel.assessmentDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select level',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _LevelSelector(
              currentLevel: currentLevel,
              onSelected: onLevelSelected,
              movementPatternName: item.movementPattern.name,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.currentLevel,
    required this.onSelected,
    required this.movementPatternName,
  });

  final CapabilityLevel currentLevel;
  final ValueChanged<CapabilityLevel> onSelected;
  final String movementPatternName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CapabilityLevel.values.map((level) {
        final isSelected = level == currentLevel;
        return ChoiceChip(
          key: ValueKey('level_${movementPatternName}_${level.name}'),
          label: Text('L${level.index + 1}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSelected(level);
            }
          },
          tooltip:
              'Level ${level.index + 1} — ${level.assessmentTitle}: ${level.assessmentDescription}',
          showCheckmark: true,
        );
      }).toList(),
    );
  }
}
