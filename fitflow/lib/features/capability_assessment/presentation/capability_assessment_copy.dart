import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/features/workouts/domain/capability_level.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';

String assessmentTitle(AppLocalizations l10n, MovementPattern pattern) =>
    switch (pattern) {
      MovementPattern.push => l10n.assessmentPushTitle,
      MovementPattern.pull => l10n.assessmentPullTitle,
      MovementPattern.squat => l10n.assessmentSquatTitle,
      MovementPattern.lunge => l10n.assessmentLungeTitle,
      MovementPattern.hinge => l10n.assessmentHingeTitle,
      MovementPattern.core => l10n.assessmentCoreTitle,
      MovementPattern.glute => l10n.assessmentGluteTitle,
      MovementPattern.cardio => l10n.assessmentCardioTitle,
      MovementPattern.mobility => l10n.assessmentMobilityTitle,
      MovementPattern.balance => l10n.assessmentBalanceTitle,
      MovementPattern.warmup || MovementPattern.cooldown => '',
    };

String assessmentPrompt(AppLocalizations l10n, MovementPattern pattern) =>
    switch (pattern) {
      MovementPattern.push => l10n.assessmentPushPrompt,
      MovementPattern.pull => l10n.assessmentPullPrompt,
      MovementPattern.squat => l10n.assessmentSquatPrompt,
      MovementPattern.lunge => l10n.assessmentLungePrompt,
      MovementPattern.hinge => l10n.assessmentHingePrompt,
      MovementPattern.core => l10n.assessmentCorePrompt,
      MovementPattern.glute => l10n.assessmentGlutePrompt,
      MovementPattern.cardio => l10n.assessmentCardioPrompt,
      MovementPattern.mobility => l10n.assessmentMobilityPrompt,
      MovementPattern.balance => l10n.assessmentBalancePrompt,
      MovementPattern.warmup || MovementPattern.cooldown => '',
    };

String assessmentExamples(AppLocalizations l10n, MovementPattern pattern) =>
    switch (pattern) {
      MovementPattern.push => l10n.assessmentPushExamples,
      MovementPattern.pull => l10n.assessmentPullExamples,
      MovementPattern.squat => l10n.assessmentSquatExamples,
      MovementPattern.lunge => l10n.assessmentLungeExamples,
      MovementPattern.hinge => l10n.assessmentHingeExamples,
      MovementPattern.core => l10n.assessmentCoreExamples,
      MovementPattern.glute => l10n.assessmentGluteExamples,
      MovementPattern.cardio => l10n.assessmentCardioExamples,
      MovementPattern.mobility => l10n.assessmentMobilityExamples,
      MovementPattern.balance => l10n.assessmentBalanceExamples,
      MovementPattern.warmup || MovementPattern.cooldown => '',
    };

String assessmentChoice(AppLocalizations l10n, CapabilityLevel level) =>
    switch (level) {
      CapabilityLevel.level1 => l10n.assessmentChoice1,
      CapabilityLevel.level2 => l10n.assessmentChoice2,
      CapabilityLevel.level3 => l10n.assessmentChoice3,
      CapabilityLevel.level4 => l10n.assessmentChoice4,
      CapabilityLevel.level5 => l10n.assessmentChoice5,
    };

String assessmentChoiceBody(AppLocalizations l10n, CapabilityLevel level) =>
    switch (level) {
      CapabilityLevel.level1 => l10n.assessmentChoice1Body,
      CapabilityLevel.level2 => l10n.assessmentChoice2Body,
      CapabilityLevel.level3 => l10n.assessmentChoice3Body,
      CapabilityLevel.level4 => l10n.assessmentChoice4Body,
      CapabilityLevel.level5 => l10n.assessmentChoice5Body,
    };
