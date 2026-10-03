import 'package:fitflow/features/onboarding/data/experience_level.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/onboarding/data/training_environment.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/onboarding/data/workout_preference.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/workouts/domain/adaptive/movement_workout_feedback.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/session/workout_session_mode.dart';
import 'package:fitflow/l10n/app_localizations.dart';
import 'package:fitflow/l10n/locale_format.dart';

/// Presentation labels for domain enums.
///
/// Domain objects keep their English `.label` and persist `.name`. These
/// adapters are the only place UI copy for those enums should come from.
String fitnessGoalLabel(AppLocalizations l10n, FitnessGoal goal) {
  return switch (goal) {
    FitnessGoal.generalFitness => l10n.goalGeneralFitness,
    FitnessGoal.buildStrength => l10n.goalBuildStrength,
    FitnessGoal.buildMuscle => l10n.goalBuildMuscle,
    FitnessGoal.loseWeight => l10n.goalLoseWeight,
    FitnessGoal.improveEndurance => l10n.goalImproveEndurance,
    FitnessGoal.improveMobility => l10n.goalImproveMobility,
    FitnessGoal.stayActive => l10n.goalStayActive,
  };
}

String experienceLabel(AppLocalizations l10n, ExperienceLevel level) {
  return switch (level) {
    ExperienceLevel.completelyNew => l10n.experienceCompletelyNew,
    ExperienceLevel.someExperience => l10n.experienceSome,
    ExperienceLevel.regularTraining => l10n.experienceRegular,
    ExperienceLevel.experienced => l10n.experienceExperienced,
  };
}

String experienceHelp(AppLocalizations l10n, ExperienceLevel level) {
  return switch (level) {
    ExperienceLevel.completelyNew => l10n.experienceCompletelyNewHelp,
    ExperienceLevel.someExperience => l10n.experienceSomeHelp,
    ExperienceLevel.regularTraining => l10n.experienceRegularHelp,
    ExperienceLevel.experienced => l10n.experienceExperiencedHelp,
  };
}

String workoutDurationLabel(AppLocalizations l10n, WorkoutDuration duration) {
  return FitFlowLocaleFormat.formatMinutes(l10n, duration.minutes);
}

String environmentLabel(AppLocalizations l10n, TrainingEnvironment environment) {
  return switch (environment) {
    TrainingEnvironment.apartment => l10n.environmentApartment,
    TrainingEnvironment.normalHome => l10n.environmentNormalHome,
    TrainingEnvironment.smallRoom => l10n.environmentSmallRoom,
    TrainingEnvironment.largeRoom => l10n.environmentLargeRoom,
    TrainingEnvironment.hotel => l10n.environmentHotel,
    TrainingEnvironment.outdoor => l10n.environmentOutdoor,
  };
}

String equipmentLabel(AppLocalizations l10n, WorkoutEquipment equipment) {
  return switch (equipment) {
    WorkoutEquipment.none => l10n.equipmentNone,
    WorkoutEquipment.exerciseMat => l10n.equipmentMat,
    WorkoutEquipment.chair => l10n.equipmentChair,
    WorkoutEquipment.resistanceBands => l10n.equipmentBands,
    WorkoutEquipment.dumbbells => l10n.equipmentDumbbells,
    WorkoutEquipment.kettlebell => l10n.equipmentKettlebell,
    WorkoutEquipment.pullUpBar => l10n.equipmentPullUpBar,
    WorkoutEquipment.bench => l10n.equipmentBench,
    WorkoutEquipment.towel => l10n.equipmentTowel,
  };
}

String preferenceLabel(AppLocalizations l10n, WorkoutPreference preference) {
  return switch (preference) {
    WorkoutPreference.noJumping => l10n.preferenceNoJumping,
    WorkoutPreference.lowImpact => l10n.preferenceLowImpact,
    WorkoutPreference.noFloorExercises => l10n.preferenceNoFloor,
    WorkoutPreference.standingOnly => l10n.preferenceStandingOnly,
    WorkoutPreference.avoidWristHeavy => l10n.preferenceAvoidWrist,
    WorkoutPreference.avoidDeepKneeBending => l10n.preferenceAvoidKnee,
  };
}

String difficultyLabel(AppLocalizations l10n, ExerciseDifficulty difficulty) {
  final level = difficulty.name.replaceFirst('level', '');
  return l10n.difficultyLevel(level);
}

String movementPatternLabel(AppLocalizations l10n, MovementPattern pattern) {
  return switch (pattern) {
    MovementPattern.push => l10n.patternPush,
    MovementPattern.pull => l10n.patternPull,
    MovementPattern.squat => l10n.patternSquat,
    MovementPattern.lunge => l10n.patternLunge,
    MovementPattern.hinge => l10n.patternHinge,
    MovementPattern.core => l10n.patternCore,
    MovementPattern.glute => l10n.patternGlute,
    MovementPattern.cardio => l10n.patternCardio,
    MovementPattern.mobility => l10n.patternMobility,
    MovementPattern.balance => l10n.patternBalance,
    MovementPattern.warmup => l10n.patternWarmup,
    MovementPattern.cooldown => l10n.patternCooldown,
  };
}

String sessionModeLabel(AppLocalizations l10n, WorkoutSessionMode mode) {
  return switch (mode) {
    WorkoutSessionMode.standard => l10n.modeStandard,
    WorkoutSessionMode.lowEnergy => l10n.modeLowEnergy,
    WorkoutSessionMode.comeback => l10n.modeComeback,
  };
}

String feedbackLabel(AppLocalizations l10n, MovementWorkoutFeedback feedback) {
  return switch (feedback) {
    MovementWorkoutFeedback.tooHard => l10n.feedbackTooHard,
    MovementWorkoutFeedback.justRight => l10n.feedbackJustRight,
    MovementWorkoutFeedback.easy => l10n.feedbackEasy,
  };
}

String feedbackDescription(
  AppLocalizations l10n,
  MovementWorkoutFeedback feedback,
) {
  return switch (feedback) {
    MovementWorkoutFeedback.tooHard => l10n.feedbackTooHardDescription,
    MovementWorkoutFeedback.justRight => l10n.feedbackJustRightDescription,
    MovementWorkoutFeedback.easy => l10n.feedbackEasyDescription,
  };
}

String appearanceModeLabel(AppLocalizations l10n, AppearanceMode mode) {
  return switch (mode) {
    AppearanceMode.light => l10n.appearanceLight,
    AppearanceMode.dark => l10n.appearanceDark,
    AppearanceMode.system => l10n.appearanceSystem,
  };
}

String onboardingTitle(AppLocalizations l10n, String pageId) {
  return switch (pageId) {
    'welcome' => l10n.onboardingWelcomeTitle,
    'goal' => l10n.onboardingGoalTitle,
    'experience' => l10n.onboardingExperienceTitle,
    'workout_time' => l10n.onboardingTimeTitle,
    'environment' => l10n.onboardingEnvironmentTitle,
    'equipment' => l10n.onboardingEquipmentTitle,
    'preferences' => l10n.onboardingPreferencesTitle,
    'ready' => l10n.onboardingReadyTitle,
    _ => pageId,
  };
}

String? onboardingBody(AppLocalizations l10n, String pageId) {
  return switch (pageId) {
    'welcome' => l10n.onboardingWelcomeBody,
    'ready' => l10n.onboardingReadyBody,
    _ => null,
  };
}
