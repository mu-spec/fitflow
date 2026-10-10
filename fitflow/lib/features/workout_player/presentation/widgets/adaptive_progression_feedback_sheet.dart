import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_copy.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/core/accessibility/accessible_actions.dart';
import 'package:fitflow/core/persistence/shared_preferences_provider.dart';
import 'package:fitflow/features/workouts/application/adaptive_progression_controller.dart';
import 'package:fitflow/features/workouts/data/capability_profile_storage.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_decision.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_engine.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/workout/workout_exercise_prescription.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdaptiveProgressionFeedbackSheet extends ConsumerStatefulWidget {
  const AdaptiveProgressionFeedbackSheet({
    super.key,
    required this.effectiveMainPrescriptions,
    required this.currentProfile,
    required this.scrollController,
    this.returnRoute,
  });

  final List<WorkoutExercisePrescription> effectiveMainPrescriptions;
  final CapabilityProfile currentProfile;
  final ScrollController scrollController;

  /// Where Skip / Apply navigate afterwards. Defaults to Home (M10 behaviour);
  /// program sessions pass their program detail route (M16).
  final String? returnRoute;

  String get _destination => returnRoute ?? AppRoutes.home;

  @override
  ConsumerState<AdaptiveProgressionFeedbackSheet> createState() =>
      _AdaptiveProgressionFeedbackSheetState();
}

class _AdaptiveProgressionFeedbackSheetState
    extends ConsumerState<AdaptiveProgressionFeedbackSheet> {
  final Map<MovementPattern, MovementWorkoutFeedback> _feedback = {};
  bool _isApplying = false;
  String? _errorMessage;
  AdaptiveProgressionResult? _previewResult;
  AdaptiveProgressionEvidence? _currentEvidence;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    try {
      final storage =
          await ref.read(adaptiveProgressionEvidenceStorageProvider.future);
      final evidence = storage.load();
      if (!mounted) return;
      setState(() {
        _currentEvidence = evidence;
      });
      _updatePreview();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentEvidence = AdaptiveProgressionEvidence.zero();
      });
    }
  }

  List<MovementPattern> get _uniqueMainMovements {
    final set = <MovementPattern>{};
    for (final pres in widget.effectiveMainPrescriptions) {
      final pattern = pres.exercise.movementPattern;
      if (pattern == null) continue;
      if (!CapabilityProfile.trainablePatterns.contains(pattern)) continue;
      set.add(pattern);
    }
    final list = set.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void _updatePreview() {
    if (_currentEvidence == null) return;
    if (_feedback.isEmpty) {
      setState(() {
        _previewResult = null;
      });
      return;
    }
    final result = AdaptiveProgressionEngine.calculate(
      AdaptiveProgressionInput(
        currentProfile: widget.currentProfile,
        effectiveMainPrescriptions: widget.effectiveMainPrescriptions,
        feedbackByMovement: Map.unmodifiable(_feedback),
        currentEvidence: _currentEvidence!,
        now: DateTime.now().toUtc(),
      ),
    );
    setState(() {
      _previewResult = result;
    });
  }

  Future<void> _applyAndFinish() async {
    if (_isApplying || _feedback.isEmpty) return;
    _isApplying = true;
    setState(() {
      _errorMessage = null;
    });

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final evidenceStorage =
          await ref.read(adaptiveProgressionEvidenceStorageProvider.future);
      final capabilityController = ref.read(capabilityProfileProvider.notifier);

      final controller = AdaptiveProgressionController(
        capabilityController: capabilityController,
        evidenceStorage: evidenceStorage,
        readPersistedCapability: () async =>
            CapabilityProfileStorage(prefs).load(),
      );

      final result = await controller.applyFeedback(
        currentProfile: widget.currentProfile,
        effectiveMainPrescriptions: widget.effectiveMainPrescriptions,
        feedbackByMovement: Map.unmodifiable(_feedback),
        now: DateTime.now().toUtc(),
      );

      if (!mounted) return;

      if (result.success) {
        // Navigate cleanly to home before provider rebuild can reset player
        if (context.mounted) {
          try {
            context.go(widget._destination);
          } catch (_) {
            Navigator.of(context).maybePop();
          }
        }
      } else {
        setState(() {
          _isApplying = false;
          _errorMessage = result.errorMessage ?? context.l10n.flowTuneError;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isApplying = false;
          _errorMessage = context.l10n.flowTuneError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final movements = _uniqueMainMovements;

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.all(FitFlowSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.flowTuneTitle,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: FitFlowSpace.xs),
            Text(context.l10n.flowTuneHelp,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: FitFlowSpace.md),
            const Divider(),
            const SizedBox(height: FitFlowSpace.xs),
            SizedBox(
              child: _currentEvidence == null
                  ? FitFlowLoading(label: context.l10n.part6LoadingTuning)
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: movements.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: FitFlowSpace.md),
                      itemBuilder: (context, index) {
                        final pattern = movements[index];
                        final currentCap =
                            widget.currentProfile.capabilityFor(pattern);
                        final currentLevel = currentCap?.level;
                        final selectedFeedback = _feedback[pattern];
                        final decision = _previewResult?.decisions[pattern];

                        return Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color:
                                          theme.colorScheme.outlineVariant))),
                          child: Padding(
                            padding: const EdgeInsets.all(FitFlowSpace.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                        movementPatternLabel(
                                            context.l10n, pattern),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    if (currentLevel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: FitFlowSpace.xs,
                                            vertical: FitFlowSpace.xxs),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme.secondaryContainer,
                                          borderRadius:
                                              FitFlowRadius.smallBorder,
                                        ),
                                        child: Text(
                                          assessmentChoice(
                                              context.l10n, currentLevel),
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: FitFlowSpace.xs),
                                _FeedbackChoices(
                                  selected: selectedFeedback,
                                  onChanged: (next) {
                                    setState(() {
                                      if (next == null) {
                                        _feedback.remove(pattern);
                                      } else {
                                        _feedback[pattern] = next;
                                      }
                                    });
                                    _updatePreview();
                                  },
                                ),
                                if (decision != null) ...[
                                  const SizedBox(height: FitFlowSpace.xs),
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.all(FitFlowSpace.xs),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                      borderRadius: FitFlowRadius.smallBorder,
                                    ),
                                    child: Text(
                                      _decisionCopy(context, decision.type),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  if (decision.type ==
                                      MovementProgressionDecisionType
                                          .promoted) ...[
                                    const SizedBox(height: FitFlowSpace.xxs),
                                    Text(
                                      '${assessmentChoice(context.l10n, decision.previousLevel)} → ${assessmentChoice(context.l10n, decision.newLevel)}',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ] else if (decision.type ==
                                      MovementProgressionDecisionType
                                          .reduced) ...[
                                    const SizedBox(height: FitFlowSpace.xxs),
                                    Text(
                                      '${assessmentChoice(context.l10n, decision.previousLevel)} → ${assessmentChoice(context.l10n, decision.newLevel)}',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: FitFlowSpace.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(FitFlowSpace.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: FitFlowRadius.smallBorder,
                ),
                child: Text(
                  context.l10n.flowTuneError,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: FitFlowSpace.md),
            FitFlowActionPair(
              expand: true,
              leading: OutlinedButton(
                onPressed: _isApplying
                    ? null
                    : () {
                        // Skip – do not change capability or evidence
                        if (context.mounted) {
                          try {
                            context.go(widget._destination);
                          } catch (_) {
                            // In tests without GoRouter, just pop or do nothing
                            Navigator.of(context).maybePop();
                          }
                        }
                      },
                child: Text(context.l10n.flowSkip),
              ),
              trailing: FilledButton(
                onPressed:
                    (_feedback.isEmpty || _isApplying) ? null : _applyAndFinish,
                child: _isApplying
                    ? Text(context.l10n.utilitySaving)
                    : Text(context.l10n.flowApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _decisionCopy(
        BuildContext context, MovementProgressionDecisionType type) =>
    switch (type) {
      MovementProgressionDecisionType.promoted =>
        context.l10n.flowDecisionPromoted,
      MovementProgressionDecisionType.reduced =>
        context.l10n.flowDecisionReduced,
      MovementProgressionDecisionType.unchangedJustRight =>
        context.l10n.flowDecisionRight,
      MovementProgressionDecisionType.firstEasySignal =>
        context.l10n.flowDecisionFirst,
      MovementProgressionDecisionType.easyNotQualified =>
        context.l10n.flowDecisionNotQualified,
      MovementProgressionDecisionType.alreadyAtMaximum =>
        context.l10n.flowDecisionMaximum,
      MovementProgressionDecisionType.alreadyAtMinimum =>
        context.l10n.flowDecisionMinimum,
    };

class _FeedbackChoices extends StatelessWidget {
  const _FeedbackChoices({
    required this.selected,
    required this.onChanged,
  });

  final MovementWorkoutFeedback? selected;
  final ValueChanged<MovementWorkoutFeedback?> onChanged;

  static const _options = <MovementWorkoutFeedback>[
    MovementWorkoutFeedback.tooHard,
    MovementWorkoutFeedback.justRight,
    MovementWorkoutFeedback.easy,
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final narrow = MediaQuery.sizeOf(context).width < 520;
    if (scale < 1.3 && !narrow) {
      return SegmentedButton<MovementWorkoutFeedback>(
        segments: [
          for (final option in _options)
            ButtonSegment(
              value: option,
              label: Text(feedbackLabel(context.l10n, option)),
              tooltip: feedbackDescription(context.l10n, option),
            ),
        ],
        selected: selected != null ? {selected!} : {},
        onSelectionChanged: (next) {
          onChanged(next.isEmpty ? null : next.first);
        },
        multiSelectionEnabled: false,
        emptySelectionAllowed: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: FitFlowSpace.xs),
            child: Semantics(
              button: true,
              selected: selected == option,
              inMutuallyExclusiveGroup: true,
              label:
                  '${feedbackLabel(context.l10n, option)}. ${feedbackDescription(context.l10n, option)}',
              child: OutlinedButton.icon(
                onPressed: () => onChanged(selected == option ? null : option),
                icon: Icon(
                  selected == option
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                label: Text(feedbackLabel(context.l10n, option)),
              ),
            ),
          ),
      ],
    );
  }
}
