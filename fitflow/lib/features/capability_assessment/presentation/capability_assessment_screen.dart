import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_v2_setup.dart';
import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/exercise_media_registry.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generator.dart';
import 'package:fitflow/features/workouts/domain/generation/workout_generation_context.dart';
import 'package:fitflow/features/workouts/application/workout_session_mode_controller.dart';
import 'package:fitflow/features/onboarding/presentation/workout_preparation_view.dart';
import 'package:fitflow/features/onboarding/presentation/setup_photo_background.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_copy.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_answer.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_catalog.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_item.dart';
import 'package:fitflow/features/workouts/domain/capability_assessment_state.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
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
class CapabilityAssessmentScreen extends StatelessWidget {
  const CapabilityAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const WorkoutsTheme(child: _AssessmentContent());
}

class _AssessmentContent extends ConsumerStatefulWidget {
  const _AssessmentContent();
  @override
  ConsumerState<_AssessmentContent> createState() =>
      _CapabilityAssessmentScreenState();
}

class _CapabilityAssessmentScreenState extends ConsumerState<_AssessmentContent>
    with SingleTickerProviderStateMixin {
  CapabilityAssessmentState? _assessmentState;
  CapabilityAssessmentState? _initialState;
  bool _isSaving = false;
  String? _errorMessage;
  bool _hasInitialized = false;
  double _preparationProgress = 0;
  bool _preparationFailed = false;
  late final AnimationController _preparationAnimation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..addListener(() {
      if (mounted) {
        setState(() => _preparationProgress =
            (_preparationAnimation.value * .99).clamp(0.0, .99));
      }
    });

  @override
  void dispose() {
    _preparationAnimation.dispose();
    super.dispose();
  }

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
    if (_assessmentState == null || _isSaving) return;
    setState(() {
      _preparationProgress = 0;
      _isSaving = true;
      _errorMessage = null;
    });

    final now = DateTime.now().toUtc();
    final profile = _assessmentState!.toCapabilityProfile(updatedAt: now);

    if (profile == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = context.l10n.assessmentInvalid;
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
        _errorMessage = context.l10n.assessmentSaveError;
      });
      return;
    }

    await _prepareWorkout();
  }

  Future<void> _prepareWorkout() async {
    setState(() {
      _isSaving = true;
      _preparationFailed = false;
      _preparationProgress = 0;
    });
    // A six-second setup presentation, not download/byte progress. Never show
    // 100% or navigate before the real local work succeeds.
    final presentation = _preparationAnimation
        .forward(from: 0)
        .orCancel
        .then<void>((_) {}, onError: (Object _) {});
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final user = await ref.read(userFitnessProfileProvider.future);
      final capability = await ref.read(capabilityProfileProvider.future);
      if (!mounted) return;
      if (user == null || capability == null) throw StateError('Missing setup');
      final plan = WorkoutGenerator.generateCatalog(WorkoutGenerationContext(
          userProfile: user,
          capabilityProfile: capability,
          sessionMode: ref.read(workoutSessionModeProvider)));

      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (plan != null && plan.main.exercises.isNotEmpty) {
        final asset =
            ExerciseMediaRegistry.lookup(plan.main.exercises.first.exercise.id)
                ?.hero;
        if (asset != null) {
          // Missing imagery keeps the existing renderer's fallback available.
          await precacheImage(AssetImage(asset.path), context,
              onError: (_, stackTrace) {});
        }
      }
      if (!mounted) return;
      await presentation;
      if (!mounted) return;
      setState(() => _preparationProgress = 1);
      // Leave the completed state visible before opening Home.
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) context.go(AppRoutes.home);
    } on Object {
      if (!mounted) return;
      _preparationAnimation.stop();
      setState(() => _preparationFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSaving) {
      return WorkoutPreparationView(
          progress: _preparationProgress,
          saving:
              !_preparationAnimation.isAnimating && _preparationProgress == 0,
          failed: _preparationFailed,
          onRetry: _prepareWorkout);
    }
    final userProfileAsync = ref.watch(userFitnessProfileProvider);
    final capabilityProfileAsync = ref.watch(capabilityProfileProvider);

    final isUserLoading = userProfileAsync.isLoading;
    final isCapabilityLoading = capabilityProfileAsync.isLoading;

    if (isUserLoading || isCapabilityLoading) {
      return Scaffold(
          backgroundColor: FitFlowVisualV2.of(context).page,
          body: SafeArea(
              child: FitFlowLoading(label: context.l10n.assessmentLoading)));
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
      return Scaffold(
          backgroundColor: FitFlowVisualV2.of(context).page,
          body: FitFlowLoading(label: context.l10n.assessmentLoading));
    }

    // If user profile is null, recovery to onboarding
    if (userProfile == null) {
      return Scaffold(
          backgroundColor: FitFlowVisualV2.of(context).page,
          appBar: AppBar(title: Text(context.l10n.movementCheckTitle)),
          body: SafeArea(
              child: SingleChildScrollView(
                  child: FitFlowMaxWidth(
            child: FitFlowEmptyState(
                title: context.l10n.assessmentMissingTitle,
                message: context.l10n.assessmentMissingBody,
                action: FilledButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    child: Text(context.l10n.assessmentOnboarding))),
          ))));
    }

    // Initialize assessment state once from experience
    if (!_hasInitialized) {
      final initial =
          CapabilityAssessmentState.fromExperienceLevel(userProfile.experience);
      _assessmentState = initial;
      _initialState = initial;
      _hasInitialized = true;
    }

    return SetupPhotoTheme(child: Builder(builder: _buildAssessment));
  }

  Widget _buildAssessment(BuildContext context) {
    final assessmentState = _assessmentState!;
    final initialState = _initialState!;

    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = FitFlowTheme.of(context);
    final save = FitFlowV2ActionSurface(
      child: FilledButton(
        key: const Key('save_and_continue_button'),
        style: FitFlowV2ActionSurface.primaryStyle(context),
        onPressed: _isSaving ? null : _saveAndContinue,
        child: Text(_isSaving ? l10n.assessmentSaving : l10n.assessmentSave,
            textAlign: TextAlign.center),
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(AppRoutes.onboarding);
      },
      child: SetupPhotoBackground(
          exerciseId: 'single_leg_stand',
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.black.withValues(alpha: .58),
              surfaceTintColor: Colors.transparent,
              title: Text(l10n.movementCheckTitle, style: text.titleLarge),
              leading: IconButton(
                  icon: const BackButtonIcon(),
                  onPressed: () => context.go(AppRoutes.onboarding),
                  tooltip: l10n.backToOnboarding),
            ),
            body: SafeArea(
                child: FitFlowMaxWidth(
              maxWidth: FitFlowLayout.maxReadableWidth,
              child: LayoutBuilder(builder: (context, constraints) {
                final short = constraints.maxHeight < 320;
                final inset = 20.0;
                final scroll = CustomScrollView(slivers: [
                  SliverToBoxAdapter(
                      child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
                    child: SetupPhotoPanel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Text(l10n.assessmentBody, style: text.bodyMedium),
                          const SizedBox(height: 12),
                          FitFlowProgress(
                              label: l10n.assessmentProgress(
                                  assessmentState.answeredCount,
                                  CapabilityAssessmentState.totalCount),
                              value: assessmentState.answeredCount /
                                  CapabilityAssessmentState.totalCount),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: FitFlowSpace.sm),
                            Semantics(
                                liveRegion: true,
                                child: Text(_errorMessage!,
                                    style: text.bodyMedium
                                        ?.copyWith(color: colors.error))),
                          ],
                        ])),
                  )),
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
                        padding: const EdgeInsets.only(bottom: FitFlowSpace.sm),
                        child: _MovementAssessmentCard(
                          key: ValueKey(
                              'assessment_card_${item.movementPattern.name}'),
                          item: item,
                          ordinal: index + 1,
                          currentLevel: currentAnswer?.selectedLevel ??
                              CapabilityLevel.level3,
                          isChanged: isChanged,
                          onLevelSelected: (level) =>
                              _updateLevel(item.movementPattern, level),
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                      child: Padding(
                    key: const Key('assessment_summary'),
                    padding:
                        const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
                    child: SetupPhotoPanel(
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(l10n.assessmentSummary,
                                style: text.titleMedium),
                            children: [
                          for (final item in CapabilityAssessmentCatalog.all)
                            if (assessmentState.answerFor(item.movementPattern)
                                case final answer?)
                              Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: FitFlowSpace.xs),
                                  child: Text(
                                      l10n.assessmentSummaryItem(
                                          movementPatternLabel(
                                              l10n, item.movementPattern),
                                          assessmentChoice(
                                              l10n, answer.selectedLevel)),
                                      style: text.bodyMedium)),
                        ])),
                  )),
                  if (short) SliverToBoxAdapter(child: save),
                ]);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: inset),
                  child: short
                      ? scroll
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [Expanded(child: scroll), save]),
                );
              }),
            )),
          )),
    );
  }
}

class _MovementAssessmentCard extends StatelessWidget {
  const _MovementAssessmentCard(
      {super.key,
      required this.item,
      required this.ordinal,
      required this.currentLevel,
      required this.isChanged,
      required this.onLevelSelected});
  final CapabilityAssessmentItem item;
  final int ordinal;
  final CapabilityLevel currentLevel;
  final bool isChanged;
  final ValueChanged<CapabilityLevel> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = FitFlowTheme.of(context);
    final theme = Theme.of(context);
    final photo = switch (item.movementPattern) {
      MovementPattern.push => 'pushup_wall',
      MovementPattern.pull => 'row_towel',
      MovementPattern.squat => 'squat_bodyweight',
      MovementPattern.lunge => 'lunge_reverse',
      MovementPattern.hinge => 'hip_hinge',
      MovementPattern.core => 'dead_bug',
      MovementPattern.glute => 'bridge_glute',
      MovementPattern.cardio => 'march_in_place',
      MovementPattern.mobility => 'cat_cow',
      MovementPattern.balance => 'single_leg_stand',
      _ => 'arm_circles',
    };
    return SetupPhotoPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FitFlowExerciseImage.hero(
                exerciseId: photo, width: 88, height: 66)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
              header: true,
              child: Text(assessmentTitle(l10n, item.movementPattern),
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w500))),
          Text(isChanged ? l10n.assessmentChanged : l10n.assessmentSuggested,
              style: text.bodySmall?.copyWith(color: colors.textSecondary)),
        ])),
      ]),
      const SizedBox(height: 10),
      Text(assessmentPrompt(l10n, item.movementPattern),
          style: text.bodyMedium),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 0, children: [
        for (final level in CapabilityLevel.values)
          ChoiceChip(
              key: ValueKey('level_${item.movementPattern.name}_${level.name}'),
              label: Text(assessmentChoice(l10n, level)),
              tooltip: assessmentChoiceBody(l10n, level),
              selected: level == currentLevel,
              onSelected: (selected) {
                if (selected) onLevelSelected(level);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              backgroundColor: theme.colorScheme.surface,
              checkmarkColor: colors.brand,
              labelStyle: text.bodyMedium,
              side: BorderSide(
                  color: level == currentLevel ? colors.brand : colors.border),
              showCheckmark: true,
              materialTapTargetSize: MaterialTapTargetSize.padded),
      ]),
      Text(assessmentChoiceBody(l10n, currentLevel), style: text.bodySmall),
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          minTileHeight: 48,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(l10n.exerciseExamples, style: text.bodySmall),
          children: [
            Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(assessmentExamples(l10n, item.movementPattern),
                    style: text.bodySmall))
          ]),
    ]));
  }
}
