import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_v2_setup.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
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

    // Same save gate and route. Success feedback never adds a delay or extra tap.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.assessmentSuccess),
      duration: const Duration(seconds: 2),
    ));
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

    final assessmentState = _assessmentState!;
    final initialState = _initialState!;

    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = FitFlowTheme.of(context);
    final v = FitFlowVisualV2.of(context);
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
      child: Scaffold(
        backgroundColor: v.page,
        appBar: AppBar(
          backgroundColor: v.page,
          title: Text(l10n.movementCheckTitle),
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
            final inset =
                constraints.maxWidth < 360 ? FitFlowSpace.md : FitFlowSpace.xl;
            final scroll = CustomScrollView(slivers: [
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FitFlowV2HeroSurface(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Semantics(
                                    header: true,
                                    child: Text(l10n.assessmentIntro,
                                        style: text.headlineSmall
                                            ?.copyWith(color: v.onHero)))),
                            const SizedBox(width: FitFlowSpace.xs),
                            const FitFlowV2AdaptiveMotif(size: 56),
                          ]),
                          const SizedBox(height: FitFlowSpace.sm),
                          Text(l10n.assessmentBody,
                              style: text.bodyMedium
                                  ?.copyWith(color: v.heroSecondary)),
                        ],
                      )),
                      const SizedBox(height: FitFlowSpace.md),
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
                    ]),
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
                padding: const EdgeInsets.symmetric(vertical: FitFlowSpace.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                          header: true,
                          child: Text(l10n.assessmentSummary,
                              style: text.titleMedium)),
                      const SizedBox(height: FitFlowSpace.sm),
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
                      if (short) save,
                    ]),
              )),
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
      ),
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
    final v = FitFlowVisualV2.of(context);
    return FitFlowV2InfoSurface(
        tonal: ordinal.isEven,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            ExcludeSemantics(
                child: Container(
                    padding: const EdgeInsets.all(FitFlowSpace.xs),
                    decoration: BoxDecoration(
                        color: v.heroStart,
                        borderRadius: FitFlowRadius.smallBorder),
                    child: Text(ordinal.toString().padLeft(2, '0'),
                        style: text.labelMedium?.copyWith(color: v.action)))),
            const SizedBox(width: FitFlowSpace.sm),
            Expanded(
                child: Semantics(
                    header: true,
                    child: Text(assessmentTitle(l10n, item.movementPattern),
                        style: text.titleMedium))),
          ]),
          const SizedBox(height: FitFlowSpace.xxs),
          Text(assessmentPrompt(l10n, item.movementPattern),
              style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: FitFlowSpace.xs),
          Text(assessmentExamples(l10n, item.movementPattern),
              style: text.bodySmall?.copyWith(color: colors.textMuted)),
          const SizedBox(height: FitFlowSpace.sm),
          Text(l10n.assessmentChoose, style: text.labelMedium),
          const SizedBox(height: FitFlowSpace.xs),
          Wrap(
              spacing: FitFlowSpace.xs,
              runSpacing: FitFlowSpace.xxs,
              children: [
                for (final level in CapabilityLevel.values)
                  ChoiceChip(
                    key: ValueKey(
                        'level_${item.movementPattern.name}_${level.name}'),
                    label: Text(assessmentChoice(l10n, level)),
                    tooltip: assessmentChoiceBody(l10n, level),
                    selected: level == currentLevel,
                    onSelected: (selected) {
                      if (selected) onLevelSelected(level);
                    },
                    selectedColor: v.heroStart,
                    backgroundColor: v.support,
                    checkmarkColor: v.action,
                    labelStyle: text.labelLarge?.copyWith(
                        color: level == currentLevel
                            ? v.onHero
                            : colors.textPrimary),
                    side: BorderSide(
                        color: level == currentLevel
                            ? colors.brand
                            : v.subtleBorder),
                    showCheckmark: true,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
              ]),
          const SizedBox(height: FitFlowSpace.xs),
          Padding(
              padding: const EdgeInsets.only(top: FitFlowSpace.xxs),
              child: Text(assessmentChoiceBody(l10n, currentLevel),
                  style: text.bodySmall)),
          const SizedBox(height: FitFlowSpace.xs),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ExcludeSemantics(
                child: Icon(
                    isChanged ? Icons.check_rounded : Icons.tune_rounded,
                    size: 16,
                    color: colors.brand)),
            const SizedBox(width: FitFlowSpace.xs),
            Expanded(
                child: Text(
                    isChanged
                        ? l10n.assessmentChanged
                        : l10n.assessmentSuggested,
                    style: text.labelSmall
                        ?.copyWith(color: colors.textSecondary))),
          ]),
        ]));
  }
}
