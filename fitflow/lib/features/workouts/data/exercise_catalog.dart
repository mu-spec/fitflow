import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_difficulty.dart';
import 'package:fitflow/features/workouts/domain/exercise_position.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/joint_load.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:fitflow/features/workouts/domain/muscle_group.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';
import 'package:fitflow/features/workouts/domain/space_requirement.dart';

/// Deterministic offline exercise definitions. No assets are bundled yet.
///
/// Equipment sets describe requirements, not alternatives. `none` means no
/// portable equipment; walls and clear floor space are explained in instructions.
/// Floor-dependent supported positions use `floor` for conservative restrictions.
/// Durations/reps tagged `*_per_side` apply to each side, as instructions explain.
/// Progression ranks are one-based within a family; unlinked entries use zero.
abstract final class ExerciseCatalog {
  static final List<Exercise> all = List<Exercise>.unmodifiable([
    Exercise(
      id: "pushup_wall",
      name: "Wall Push-Up",
      shortDescription:
          "A standing press against a wall with a light bodyweight load.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.low,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.chest, MuscleGroup.triceps},
      secondaryMuscles: {MuscleGroup.shoulders, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "pushup",
      progressionRank: 1,
      harderVariationId: "pushup_incline",
      instructions: [
        "Face a solid wall and place palms at shoulder height, slightly wider than shoulders.",
        "Step back, brace your trunk, and bend elbows about 45 degrees from your sides to bring your chest toward the wall.",
        "Press away smoothly while keeping head, hips, and heels aligned."
      ],
      commonMistakes: [
        "Flaring elbows straight out",
        "Bending at the hips instead of moving as one unit"
      ],
      breathingGuidance: "Inhale toward the wall; exhale as you press away.",
      tags: {"bodyweight", "wall_support"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_incline",
      name: "Incline Push-Up",
      shortDescription:
          "A raised-hand push-up on a stable bench to reduce pressing load.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.chest, MuscleGroup.triceps},
      secondaryMuscles: {MuscleGroup.shoulders, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.bench},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "pushup",
      progressionRank: 2,
      easierVariationId: "pushup_wall",
      harderVariationId: "pushup_knee",
      instructions: [
        "Use a sturdy, non-slip bench secured against movement; grip its edge slightly wider than shoulders.",
        "Walk feet back into a straight plank and lower your chest toward the edge with elbows angled back.",
        "Press back up without letting hips sag."
      ],
      commonMistakes: [
        "Using a bench that can slide or tip",
        "Dropping hips below the shoulder-to-heel line"
      ],
      breathingGuidance: "Inhale as you lower; exhale as you press.",
      tags: {"bodyweight", "elevated_hands"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_knee",
      name: "Knee Push-Up",
      shortDescription:
          "A floor push-up with knees supported to shorten the lever.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.chest, MuscleGroup.triceps},
      secondaryMuscles: {MuscleGroup.shoulders, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "pushup",
      progressionRank: 3,
      easierVariationId: "pushup_incline",
      harderVariationId: "pushup_standard",
      instructions: [
        "Place hands slightly wider than shoulders and knees on a comfortable surface.",
        "Keep a straight line from head through hips to knees as you lower your chest.",
        "Press up with elbows angled back, keeping your trunk braced."
      ],
      commonMistakes: [
        "Folding at the hips",
        "Letting the chest drop between the shoulders"
      ],
      breathingGuidance: "Inhale down; exhale up.",
      tags: {"bodyweight", "knee_supported"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_standard",
      name: "Standard Push-Up",
      shortDescription: "A full bodyweight press from a straight-arm plank.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.chest, MuscleGroup.triceps},
      secondaryMuscles: {
        MuscleGroup.shoulders,
        MuscleGroup.abs,
        MuscleGroup.glutes
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 60),
      progressionFamilyId: "pushup",
      progressionRank: 4,
      easierVariationId: "pushup_knee",
      harderVariationId: "pushup_decline",
      instructions: [
        "Set hands just wider than shoulders and extend legs with toes on the floor.",
        "Brace your trunk and lower your chest with elbows roughly 45 degrees from your sides.",
        "Press to straight arms while keeping the body in one line."
      ],
      commonMistakes: [
        "Sagging the lower back",
        "Reaching the chin forward instead of lowering the chest"
      ],
      breathingGuidance: "Inhale while lowering; exhale while pressing.",
      tags: {"bodyweight"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_decline",
      name: "Decline Push-Up",
      shortDescription:
          "A feet-elevated push-up that increases upper-body pressing demand.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level4,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {
        MuscleGroup.chest,
        MuscleGroup.shoulders,
        MuscleGroup.triceps
      },
      secondaryMuscles: {MuscleGroup.abs, MuscleGroup.glutes},
      requiredEquipment: {WorkoutEquipment.bench},
      exerciseType: ExerciseType.reps,
      defaultReps: 6,
      defaultRest: Duration(seconds: 60),
      progressionFamilyId: "pushup",
      progressionRank: 5,
      easierVariationId: "pushup_standard",
      instructions: [
        "Secure a low, stable bench and place your toes on it with hands on the floor.",
        "Brace in a straight line and lower your chest between your hands without arching your back.",
        "Press up under control; step down carefully to finish."
      ],
      commonMistakes: [
        "Using an unstable or excessively high support",
        "Piking hips to avoid the pressing load"
      ],
      breathingGuidance: "Inhale down; exhale as you press.",
      tags: {"bodyweight", "elevated_feet"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_chair",
      name: "Chair Sit-to-Stand",
      shortDescription: "Stand from a chair and sit back down with control.",
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {MuscleGroup.hamstrings, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.chair},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "squat",
      progressionRank: 1,
      harderVariationId: "squat_partial",
      instructions: [
        "Secure a firm chair against a wall and sit near the front with feet hip-width apart.",
        "Lean your torso forward slightly and press through both feet to stand without using your hands.",
        "Send hips back and bend knees to sit gently, keeping knees in line with toes."
      ],
      commonMistakes: [
        "Dropping onto the seat",
        "Letting knees collapse inward"
      ],
      breathingGuidance: "Exhale to stand; inhale as you sit.",
      tags: {"bodyweight", "chair_supported"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_partial",
      name: "Partial Squat",
      shortDescription:
          "A shallow squat to practice controlled hip and knee bending.",
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {MuscleGroup.hamstrings, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "squat",
      progressionRank: 2,
      easierVariationId: "squat_chair",
      harderVariationId: "squat_bodyweight",
      instructions: [
        "Stand with feet about shoulder-width apart and toes slightly turned out.",
        "Send hips back and bend knees through a shallow, comfortable range, keeping heels down.",
        "Push through your feet to stand tall without snapping the knees."
      ],
      commonMistakes: [
        "Lifting heels",
        "Forcing depth beyond a comfortable range"
      ],
      breathingGuidance: "Inhale as you lower; exhale to stand.",
      tags: {"bodyweight", "reduced_range"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_bodyweight",
      name: "Bodyweight Squat",
      shortDescription:
          "A controlled squat through your comfortable range without added weight.",
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.abs,
        MuscleGroup.lowerBack
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "squat",
      progressionRank: 3,
      easierVariationId: "squat_partial",
      harderVariationId: "squat_tempo",
      instructions: [
        "Stand with feet around shoulder-width apart and brace your trunk.",
        "Bend hips and knees together, tracking knees over toes and keeping the whole foot grounded.",
        "Lower only as far as you can control, then drive through your feet to stand."
      ],
      commonMistakes: [
        "Knees collapsing inward",
        "Rounding the back to chase depth"
      ],
      breathingGuidance: "Inhale on the descent; exhale as you stand.",
      tags: {"bodyweight"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_tempo",
      name: "Tempo Squat",
      shortDescription:
          "A bodyweight squat with a three-second lowering phase and a brief pause.",
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.abs,
        MuscleGroup.lowerBack
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 60),
      progressionFamilyId: "squat",
      progressionRank: 4,
      easierVariationId: "squat_bodyweight",
      instructions: [
        "Set your squat stance and brace with weight spread across each foot.",
        "Lower for three seconds to a comfortable depth, then pause for one second without relaxing.",
        "Stand smoothly in about one second and reset before the next repetition."
      ],
      commonMistakes: [
        "Rushing the lowering phase",
        "Bouncing out of the bottom"
      ],
      breathingGuidance: "Inhale slowly while lowering; exhale as you rise.",
      tags: {"bodyweight", "tempo"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "wall_sit",
      name: "Wall Sit",
      shortDescription: "A static squat hold supported by a wall.",
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps},
      secondaryMuscles: {MuscleGroup.glutes, MuscleGroup.calves},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 20),
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Lean your back against a solid wall and walk feet forward about hip-width apart.",
        "Slide down to a comfortable bend, no deeper than thighs parallel, with knees above ankles.",
        "Hold with back supported and hands off thighs; slide up slowly to finish."
      ],
      commonMistakes: [
        "Holding lower than you can control",
        "Pressing hands into thighs to unload the legs"
      ],
      breathingGuidance:
          "Breathe steadily throughout; do not hold your breath.",
      tags: {"bodyweight", "isometric", "wall_support"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "dead_bug",
      name: "Dead Bug",
      shortDescription:
          "Alternate opposite arm and leg reaches while keeping the trunk stable.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.abs},
      secondaryMuscles: {MuscleGroup.obliques, MuscleGroup.hipFlexors},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Lie on your back with arms above shoulders and hips and knees bent to right angles.",
        "Brace gently; reach one arm overhead and extend the opposite leg only as far as you can keep your lower back from arching.",
        "Return slowly and switch sides; the default is eight repetitions per side."
      ],
      commonMistakes: ["Arching the lower back", "Moving limbs too quickly"],
      breathingGuidance: "Exhale during the reach; inhale as you return.",
      tags: {"bodyweight", "alternating", "reps_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "plank_knee",
      name: "Knee Plank",
      shortDescription:
          "A forearm plank supported on the knees for a shorter lever.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.abs},
      secondaryMuscles: {
        MuscleGroup.obliques,
        MuscleGroup.shoulders,
        MuscleGroup.glutes
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 20),
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "forearm_plank",
      progressionRank: 1,
      harderVariationId: "plank_forearm",
      instructions: [
        "Place forearms on the floor with elbows under shoulders and knees down.",
        "Move knees back until head, hips, and knees form a straight line.",
        "Brace gently and hold without sinking into the shoulders or arching the back."
      ],
      commonMistakes: [
        "Keeping hips folded above the knees",
        "Holding your breath"
      ],
      breathingGuidance:
          "Take slow, continuous breaths while keeping your trunk braced.",
      tags: {"bodyweight", "isometric", "forearm_supported", "knee_supported"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "plank_forearm",
      name: "Forearm Plank",
      shortDescription:
          "An anti-extension trunk hold supported on forearms and toes.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.abs},
      secondaryMuscles: {
        MuscleGroup.obliques,
        MuscleGroup.shoulders,
        MuscleGroup.glutes
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 25),
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "forearm_plank",
      progressionRank: 2,
      easierVariationId: "plank_knee",
      instructions: [
        "Set elbows beneath shoulders with forearms resting on the floor.",
        "Extend both legs onto your toes and align head, hips, and heels.",
        "Brace abs and glutes, hold steadily, then lower knees to finish."
      ],
      commonMistakes: [
        "Letting the lower back sag",
        "Raising hips to avoid trunk tension"
      ],
      breathingGuidance:
          "Breathe steadily into your ribs without losing the brace.",
      tags: {"bodyweight", "isometric", "forearm_supported"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "plank_side",
      name: "Side Plank",
      shortDescription:
          "A lateral trunk hold on one forearm and the sides of the feet.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.obliques},
      secondaryMuscles: {
        MuscleGroup.abs,
        MuscleGroup.shoulders,
        MuscleGroup.glutes
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 15),
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Lie on one side with elbow under shoulder and legs straight, feet stacked.",
        "Lift hips until head, trunk, and legs form a line, pressing the forearm into the floor.",
        "Hold for fifteen seconds, lower slowly, and repeat on the other side."
      ],
      commonMistakes: [
        "Letting hips sag",
        "Rolling the chest toward the floor"
      ],
      breathingGuidance: "Keep breathing evenly throughout each side.",
      tags: {
        "bodyweight",
        "isometric",
        "forearm_supported",
        "duration_per_side"
      },
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "hollow_hold",
      name: "Hollow Hold",
      shortDescription:
          "A supine trunk hold with raised shoulders and extended legs.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level4,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.abs},
      secondaryMuscles: {MuscleGroup.hipFlexors, MuscleGroup.obliques},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 15),
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Lie on your back, brace your abdomen, and keep your lower back gently against the floor.",
        "Lift shoulders and legs, reaching arms overhead; raise legs higher if needed to preserve back contact.",
        "Hold without arching, then lower gently; stop the set if you lose back contact."
      ],
      commonMistakes: [
        "Lowering legs until the back arches",
        "Pulling the chin tightly toward the chest"
      ],
      breathingGuidance:
          "Use small, steady breaths rather than holding your breath.",
      tags: {"bodyweight", "isometric"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "bridge_glute",
      name: "Glute Bridge",
      shortDescription:
          "Lift the hips from the floor using both feet for support.",
      movementPattern: MovementPattern.glute,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.glutes},
      secondaryMuscles: {MuscleGroup.hamstrings, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 12,
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "glute_bridge",
      progressionRank: 1,
      harderVariationId: "bridge_single_leg",
      instructions: [
        "Lie on your back with knees bent, feet hip-width apart, and arms resting at your sides.",
        "Press through your feet and squeeze glutes to lift hips until shoulders, hips, and knees align.",
        "Pause briefly and lower slowly without arching your lower back."
      ],
      commonMistakes: [
        "Overextending the lower back at the top",
        "Pushing mainly through the toes"
      ],
      breathingGuidance: "Exhale as hips rise; inhale as you lower.",
      tags: {"bodyweight"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "bridge_single_leg",
      name: "Single-Leg Glute Bridge",
      shortDescription:
          "A hip lift supported on one foot to increase unilateral demand.",
      movementPattern: MovementPattern.glute,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.abs,
        MuscleGroup.obliques
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "glute_bridge",
      progressionRank: 2,
      easierVariationId: "bridge_glute",
      instructions: [
        "Lie on your back with knees bent and feet near your hips, then lift one foot clear of the floor.",
        "Press through the grounded foot to raise hips while keeping the pelvis level.",
        "Lower under control; complete eight repetitions, then switch legs."
      ],
      commonMistakes: [
        "Rotating or dropping one side of the pelvis",
        "Arching the back to lift higher"
      ],
      breathingGuidance: "Exhale to lift; inhale to lower.",
      tags: {"bodyweight", "unilateral", "reps_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "march_in_place",
      name: "March in Place",
      shortDescription:
          "A gentle alternating march without leaving the ground on both feet.",
      movementPattern: MovementPattern.warmup,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.hipFlexors, MuscleGroup.quadriceps},
      secondaryMuscles: {
        MuscleGroup.calves,
        MuscleGroup.glutes,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 45),
      defaultRest: Duration(seconds: 20),
      instructions: [
        "Stand tall with feet hip-width apart and relaxed shoulders.",
        "Lift one knee to a comfortable height while swinging the opposite arm.",
        "Set the foot down softly and alternate at a steady pace, always keeping one foot grounded."
      ],
      commonMistakes: [
        "Leaning backward to lift the knee",
        "Stamping feet loudly"
      ],
      breathingGuidance: "Breathe naturally at a comfortable pace.",
      tags: {"bodyweight", "no_jumping", "warmup"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "high_knees",
      name: "High Knees",
      shortDescription:
          "Running in place with alternating high knee drives and brief flight phases.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.high,
      noiseLevel: NoiseLevel.loud,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.high,
      primaryMuscles: {
        MuscleGroup.hipFlexors,
        MuscleGroup.quadriceps,
        MuscleGroup.calves
      },
      secondaryMuscles: {MuscleGroup.glutes, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 20),
      defaultRest: Duration(seconds: 40),
      instructions: [
        "Stand tall and begin a light run in place with bent elbows.",
        "Drive alternating knees toward hip height only as far as you can control, with quick arm swings.",
        "Land softly under your hips with slightly bent knees; slow to a march to finish."
      ],
      commonMistakes: [
        "Leaning far backward",
        "Landing heavily with locked knees"
      ],
      breathingGuidance: "Breathe rhythmically; avoid breath holding.",
      tags: {"bodyweight", "jumping", "running_in_place"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "jumping_jacks",
      name: "Jumping Jacks",
      shortDescription:
          "Repeated outward and inward jumps coordinated with overhead arm raises.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.high,
      noiseLevel: NoiseLevel.loud,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.high,
      primaryMuscles: {
        MuscleGroup.calves,
        MuscleGroup.quadriceps,
        MuscleGroup.glutes
      },
      secondaryMuscles: {
        MuscleGroup.shoulders,
        MuscleGroup.hipFlexors,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 30),
      defaultRest: Duration(seconds: 40),
      instructions: [
        "Stand with feet together and arms by your sides, allowing clear space overhead and to either side.",
        "Jump feet apart as arms sweep overhead, landing with soft knees and knees tracking over toes.",
        "Jump feet together as arms lower; repeat at a controlled rhythm."
      ],
      commonMistakes: [
        "Landing with locked knees",
        "Letting knees collapse inward on landing"
      ],
      breathingGuidance: "Breathe continuously in rhythm with the movement.",
      tags: {"bodyweight", "jumping"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "row_doorway",
      name: "Doorway Row",
      shortDescription:
          "A shallow leaning row using a secure, load-bearing doorway grip.",
      movementPattern: MovementPattern.pull,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.upperBack, MuscleGroup.lats},
      secondaryMuscles: {
        MuscleGroup.biceps,
        MuscleGroup.forearms,
        MuscleGroup.shoulders
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Use only a fixed, load-bearing doorway with a secure handhold; never grip a moving door, handle, or decorative trim. If unsure of its strength, skip this exercise.",
        "Face the doorway, grip the structural sides at chest height, and lean back only slightly with feet firmly planted and knees soft.",
        "Pull your chest toward the opening with elbows moving back, then slowly straighten arms without losing your grip."
      ],
      commonMistakes: [
        "Using loose trim or an unverified support",
        "Leaning too far back or jerking against the grip"
      ],
      breathingGuidance: "Exhale as you pull; inhale as you lower back.",
      tags: {"bodyweight", "structural_doorway_required"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "row_towel",
      name: "Towel Row",
      shortDescription:
          "A seated, self-resisted row with a towel looped around the feet, not anchored to a door.",
      movementPattern: MovementPattern.pull,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.low,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.upperBack, MuscleGroup.lats},
      secondaryMuscles: {MuscleGroup.biceps, MuscleGroup.forearms},
      requiredEquipment: {WorkoutEquipment.towel},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Sit on the floor with knees slightly bent and loop an intact towel around the mid-soles of both shoes, holding one end in each hand.",
        "Keep your spine tall and pull elbows back toward your ribs while your legs provide gentle opposing pressure through the towel.",
        "Ease the arms forward while maintaining light tension; adjust leg pressure so each repetition stays smooth."
      ],
      commonMistakes: [
        "Looping the towel around toes where it can slip",
        "Rounding the back or pulling with sudden force"
      ],
      breathingGuidance: "Exhale while pulling; inhale while releasing.",
      tags: {"self_resisted", "seated_on_floor"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "reverse_snow_angel",
      name: "Reverse Snow Angel",
      shortDescription:
          "A prone arm sweep emphasizing controlled shoulder-blade movement.",
      movementPattern: MovementPattern.pull,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.upperBack, MuscleGroup.shoulders},
      secondaryMuscles: {MuscleGroup.lowerBack, MuscleGroup.lats},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Lie face down with forehead hovering just above the floor, neck neutral, and arms by your sides.",
        "Lift hands slightly and sweep arms out and overhead only through a comfortable shoulder range.",
        "Sweep back toward your hips with control, keeping ribs and pelvis grounded."
      ],
      commonMistakes: [
        "Shrugging shoulders toward ears",
        "Arching the lower back to lift the arms higher"
      ],
      breathingGuidance:
          "Exhale through the overhead sweep; inhale on the return.",
      tags: {"bodyweight", "prone", "shoulder_control"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "superman",
      name: "Superman",
      shortDescription: "A small, controlled prone lift of the arms and legs.",
      movementPattern: MovementPattern.hinge,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.lowerBack, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.upperBack,
        MuscleGroup.shoulders
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Lie face down with arms extended overhead and legs long, keeping your gaze toward the floor.",
        "Gently brace and lift arms, chest, and legs a small distance without forcing your lower back.",
        "Pause for one second, then lower slowly; use a smaller lift or stop if your back is uncomfortable."
      ],
      commonMistakes: [
        "Throwing the head back",
        "Seeking maximum height by forcefully arching"
      ],
      breathingGuidance:
          "Exhale during the gentle lift; inhale while lowering.",
      tags: {"bodyweight", "prone", "back_extension"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "prone_y_raise",
      name: "Prone Y Raise",
      shortDescription:
          "A light prone arm raise in a Y shape for shoulder-blade control.",
      movementPattern: MovementPattern.pull,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.upperBack, MuscleGroup.shoulders},
      secondaryMuscles: {MuscleGroup.lowerBack},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Lie face down with arms angled overhead into a Y and thumbs pointing up.",
        "Keep your neck long and gently raise your hands a few centimetres without lifting your ribs.",
        "Pause briefly, then lower slowly, keeping shoulders away from your ears."
      ],
      commonMistakes: [
        "Shrugging instead of rotating the shoulder blades",
        "Lifting the chest by arching the back"
      ],
      breathingGuidance: "Exhale as hands lift; inhale as they lower.",
      tags: {"bodyweight", "prone", "shoulder_control"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "lunge_reverse",
      name: "Reverse Lunge",
      shortDescription:
          "An alternating backward step into a controlled split-stance bend.",
      movementPattern: MovementPattern.lunge,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.calves,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "lunge",
      progressionRank: 2,
      easierVariationId: "squat_split_static",
      harderVariationId: "lunge_forward",
      instructions: [
        "Stand tall with feet hip-width apart and hands at your hips.",
        "Step one foot back, bend both knees, and lower only as far as you can keep the front foot grounded and knee tracking over toes.",
        "Push through the front foot to return to standing and alternate; complete eight repetitions per side."
      ],
      commonMistakes: [
        "Stepping back on a tightrope-width stance",
        "Dropping the rear knee heavily onto the floor"
      ],
      breathingGuidance: "Inhale as you lower; exhale to return.",
      tags: {"bodyweight", "unilateral", "reps_per_side", "balance_demand"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "lunge_forward",
      name: "Forward Lunge",
      shortDescription:
          "An alternating forward step with controlled braking and return.",
      movementPattern: MovementPattern.lunge,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.high,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.calves,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "lunge",
      progressionRank: 3,
      easierVariationId: "lunge_reverse",
      harderVariationId: "squat_split_bulgarian",
      instructions: [
        "Stand with feet hip-width apart and brace your trunk.",
        "Step forward and bend both knees, controlling your landing while keeping the lead knee aligned with toes.",
        "Push through the lead foot to return to the start, then alternate; complete eight repetitions per side."
      ],
      commonMistakes: [
        "Landing heavily and collapsing into the front knee",
        "Taking a step too short to lower with control"
      ],
      breathingGuidance: "Inhale while lowering; exhale while pushing back.",
      tags: {"bodyweight", "unilateral", "reps_per_side", "balance_demand"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_split_static",
      name: "Static Split Squat",
      shortDescription:
          "An in-place split-stance squat without stepping between repetitions.",
      movementPattern: MovementPattern.lunge,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.calves,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "lunge",
      progressionRank: 1,
      harderVariationId: "lunge_reverse",
      instructions: [
        "Take a staggered stance with feet hip-width apart side to side and rear heel raised.",
        "Bend both knees to lower vertically through a comfortable range, keeping the front foot grounded.",
        "Press through your feet to rise without changing stance; complete eight repetitions and switch sides."
      ],
      commonMistakes: [
        "Putting both feet on one narrow line",
        "Allowing the front knee to collapse inward"
      ],
      breathingGuidance: "Inhale down; exhale up.",
      tags: {"bodyweight", "unilateral", "reps_per_side", "balance_demand"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_split_bulgarian",
      name: "Bulgarian Split Squat",
      shortDescription:
          "A rear-foot-elevated split squat with increased front-leg and balance demand.",
      movementPattern: MovementPattern.lunge,
      difficulty: ExerciseDifficulty.level4,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.high,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.calves,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.bench},
      exerciseType: ExerciseType.reps,
      defaultReps: 6,
      defaultRest: Duration(seconds: 60),
      progressionFamilyId: "lunge",
      progressionRank: 4,
      easierVariationId: "lunge_forward",
      instructions: [
        "Secure a low bench against movement and place the top of one foot on it behind you, with the front foot far enough forward for a comfortable bend.",
        "Brace and lower through the front leg with a slight forward torso lean, keeping the front knee aligned with toes and hips square.",
        "Press through the front foot to rise; complete six repetitions per side and step down carefully."
      ],
      commonMistakes: [
        "Using a high or unstable rear-foot support",
        "Losing balance while forcing a deep knee bend"
      ],
      breathingGuidance: "Inhale on the descent; exhale as you rise.",
      tags: {
        "bodyweight",
        "unilateral",
        "reps_per_side",
        "elevated_rear_foot",
        "balance_demand"
      },
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "calf_raise",
      name: "Calf Raise",
      shortDescription:
          "A standing two-leg heel raise through a controlled range.",
      movementPattern: MovementPattern.balance,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.calves},
      secondaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 15,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Stand with feet hip-width apart on a flat surface and knees soft.",
        "Press through the balls of both feet to raise heels without rolling ankles outward.",
        "Pause at the top and lower heels slowly to the floor."
      ],
      commonMistakes: [
        "Bouncing rapidly through repetitions",
        "Rolling weight onto the outer edges of the feet"
      ],
      breathingGuidance: "Exhale as you rise; inhale as you lower.",
      tags: {"bodyweight", "ankle_plantarflexion", "balance_demand"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "bird_dog",
      name: "Bird Dog",
      shortDescription:
          "An opposite arm and leg reach from all fours to resist trunk rotation.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.abs, MuscleGroup.lowerBack},
      secondaryMuscles: {
        MuscleGroup.glutes,
        MuscleGroup.obliques,
        MuscleGroup.shoulders
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Start on hands and knees with hands under shoulders and knees under hips.",
        "Reach one arm forward and the opposite leg back, stopping at trunk height while keeping hips level.",
        "Pause briefly, return gently, and switch sides; complete eight repetitions per side."
      ],
      commonMistakes: [
        "Arching the back to lift the leg higher",
        "Rotating the pelvis toward the raised leg"
      ],
      breathingGuidance: "Exhale during the reach; inhale as you return.",
      tags: {"bodyweight", "alternating", "reps_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "bicycle_crunch",
      name: "Bicycle Crunch",
      shortDescription:
          "A slow alternating trunk rotation with opposite knee and shoulder approach.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.abs, MuscleGroup.obliques},
      secondaryMuscles: {MuscleGroup.hipFlexors},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Lie on your back with hips and knees bent, fingertips lightly supporting your head.",
        "Lift shoulder blades and rotate one shoulder toward the opposite knee as the other leg extends only as far as you can control.",
        "Switch sides slowly without pulling your neck; complete ten repetitions per side."
      ],
      commonMistakes: [
        "Pulling the head forward with the hands",
        "Pedalling quickly while letting the lower back arch"
      ],
      breathingGuidance:
          "Exhale with each rotation; inhale through the transition.",
      tags: {"bodyweight", "alternating", "reps_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "heel_taps",
      name: "Heel Taps",
      shortDescription:
          "A supine alternating heel reach using small side bends of the trunk.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.obliques, MuscleGroup.abs},
      secondaryMuscles: {MuscleGroup.hipFlexors},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Lie on your back with knees bent and feet flat, arms reaching toward your heels.",
        "Lift shoulder blades slightly and slide your right hand toward your right heel with a small side bend.",
        "Return through centre and reach left; complete ten reaches per side without straining the neck."
      ],
      commonMistakes: [
        "Reaching so far that the neck strains",
        "Swinging the arms instead of moving the trunk"
      ],
      breathingGuidance:
          "Exhale on each reach; inhale returning toward centre.",
      tags: {"bodyweight", "alternating", "reps_per_side", "heel_reach"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "reverse_crunch",
      name: "Reverse Crunch",
      shortDescription:
          "A small pelvic curl bringing bent knees toward the trunk.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.abs},
      secondaryMuscles: {MuscleGroup.hipFlexors, MuscleGroup.obliques},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Lie on your back with arms at your sides and hips and knees bent to right angles.",
        "Exhale and gently curl the pelvis toward the ribs, lifting the tailbone slightly without swinging your legs.",
        "Lower the pelvis slowly and return knees over hips without arching your back."
      ],
      commonMistakes: [
        "Using momentum to swing the legs overhead",
        "Pressing through the neck instead of curling the pelvis"
      ],
      breathingGuidance: "Exhale during the curl; inhale while lowering.",
      tags: {"bodyweight", "pelvic_curl"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "mountain_climbers",
      name: "Mountain Climbers",
      shortDescription:
          "A brisk alternating knee drive from a high plank with light foot switches.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.moderate,
      noiseLevel: NoiseLevel.moderate,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.abs, MuscleGroup.hipFlexors},
      secondaryMuscles: {
        MuscleGroup.shoulders,
        MuscleGroup.triceps,
        MuscleGroup.quadriceps,
        MuscleGroup.obliques
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 20),
      defaultRest: Duration(seconds: 40),
      instructions: [
        "Set a high plank with hands under shoulders and a straight line from head to heels.",
        "Drive one knee toward the chest, then switch feet briskly with a small, light hop, keeping shoulders above hands.",
        "Continue at a controlled rhythm without letting hips bounce; lower knees to finish."
      ],
      commonMistakes: [
        "Lifting hips high with each switch",
        "Stamping feet or losing shoulder alignment"
      ],
      breathingGuidance:
          "Breathe rhythmically throughout rather than holding your breath.",
      tags: {"bodyweight", "dynamic_core", "jumping"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "cat_cow",
      name: "Cat-Cow",
      shortDescription:
          "A gentle alternating rounding and extension of the spine on all fours.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.lowerBack, MuscleGroup.abs},
      secondaryMuscles: {MuscleGroup.upperBack, MuscleGroup.shoulders},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Start on hands and knees with hands beneath shoulders and knees beneath hips.",
        "Exhale and gently round the spine, letting the head follow without forcing the chin inward.",
        "Inhale and ease the chest forward with a small back arch; repeat within a comfortable range."
      ],
      commonMistakes: [
        "Forcing the neck into end range",
        "Moving quickly or pushing through back discomfort"
      ],
      breathingGuidance:
          "Exhale into the rounded shape; inhale into gentle extension.",
      tags: {"bodyweight", "dynamic_mobility"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "childs_pose",
      name: "Child's Pose",
      shortDescription:
          "A supported kneeling rest with the hips moving toward the heels and arms reaching forward.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.lats, MuscleGroup.lowerBack},
      secondaryMuscles: {MuscleGroup.glutes, MuscleGroup.shoulders},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 30),
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Kneel on a comfortable surface, separate knees as needed, and gently bring hips toward heels.",
        "Fold forward and reach arms along the floor, allowing the forehead to rest if comfortable.",
        "Relax into easy breaths without forcing knee bend; come up slowly and stop if knees are uncomfortable."
      ],
      commonMistakes: [
        "Forcing hips onto heels despite knee pain",
        "Reaching so aggressively that shoulders tense"
      ],
      breathingGuidance:
          "Take slow breaths into the back and sides of your ribs.",
      tags: {"bodyweight", "static_stretch", "deep_knee_flexion"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "hip_flexor_stretch",
      name: "Hip Flexor Stretch",
      shortDescription:
          "A half-kneeling stretch with a gentle pelvic tuck to target the rear hip.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.kneeling,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.hipFlexors},
      secondaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 25),
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Kneel on one knee on a comfortable surface with the other foot forward and front knee above the ankle.",
        "Gently tuck the pelvis and squeeze the rear glute, then shift forward slightly without arching the back.",
        "Hold for twenty-five seconds with an upright torso, then switch sides."
      ],
      commonMistakes: [
        "Arching the lower back instead of extending the hip",
        "Lunging deeply into the front knee"
      ],
      breathingGuidance: "Breathe slowly and let the stretch remain gentle.",
      tags: {
        "bodyweight",
        "static_stretch",
        "duration_per_side",
        "floor_contact"
      },
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "hamstring_stretch_standing",
      name: "Standing Hamstring Stretch",
      shortDescription:
          "A standing hip hinge over one extended leg with its heel grounded.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.hamstrings},
      secondaryMuscles: {MuscleGroup.calves, MuscleGroup.glutes},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 25),
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Stand tall, place one heel slightly forward, and keep that knee soft rather than locked.",
        "Bend the supporting knee and hinge at your hips with a long spine until the back of the front thigh gently stretches.",
        "Hold for twenty-five seconds, rise slowly, and switch legs without bouncing."
      ],
      commonMistakes: [
        "Rounding the back to reach farther",
        "Locking the front knee or forcing a painful stretch"
      ],
      breathingGuidance: "Breathe slowly and evenly throughout each hold.",
      tags: {"bodyweight", "static_stretch", "duration_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "thoracic_rotation",
      name: "Thoracic Rotation",
      shortDescription:
          "A side-lying open-book rotation with knees supported together on the floor.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.upperBack, MuscleGroup.obliques},
      secondaryMuscles: {MuscleGroup.chest, MuscleGroup.shoulders},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Lie on one side with hips and knees bent and arms extended forward, palms together.",
        "Open the top arm toward the other side while rotating the upper trunk, keeping knees together on the floor.",
        "Return slowly without forcing the shoulder to touch the floor; complete eight repetitions per side."
      ],
      commonMistakes: [
        "Letting knees roll open with the torso",
        "Forcing the arm down beyond a comfortable shoulder range"
      ],
      breathingGuidance: "Exhale as you open; inhale as you return.",
      tags: {"bodyweight", "dynamic_mobility", "reps_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "good_morning",
      name: "Good Morning",
      shortDescription:
          "Standing hip hinge with hands behind head, folding forward with flat back and returning upright.",
      movementPattern: MovementPattern.hinge,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.hamstrings, MuscleGroup.glutes},
      secondaryMuscles: {MuscleGroup.lowerBack, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "hinge",
      progressionRank: 2,
      easierVariationId: "hip_hinge",
      harderVariationId: "hip_hinge_single_leg",
      instructions: [
        "Stand with feet hip-width apart, knees soft, hands lightly behind head with elbows wide and spine tall.",
        "Push hips back and hinge forward with a flat back until you feel a gentle hamstring stretch, keeping shins nearly vertical.",
        "Drive hips forward and squeeze glutes to return to standing without rounding your back."
      ],
      commonMistakes: [
        "Rounding the lower back instead of hinging at hips",
        "Bending knees into a squat rather than pushing hips back"
      ],
      breathingGuidance: "Inhale as you hinge back; exhale as you drive hips forward to stand.",
      tags: {"bodyweight", "hip_hinge", "hamstring_focus"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "hip_hinge",
      name: "Hip Hinge",
      shortDescription:
          "Fundamental hip-hinge pattern drill with hands on hips and soft knees.",
      movementPattern: MovementPattern.hinge,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.glutes, MuscleGroup.hamstrings},
      secondaryMuscles: {MuscleGroup.lowerBack, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      progressionFamilyId: "hinge",
      progressionRank: 1,
      harderVariationId: "good_morning",
      instructions: [
        "Stand with feet hip-width apart, hands on hips, knees softly bent and weight centered over mid-foot.",
        "Push hips straight back with a long spine until torso leans forward, shins stay vertical and back stays flat.",
        "Squeeze glutes to bring hips forward to standing, keeping abs gently braced."
      ],
      commonMistakes: [
        "Squatting by bending knees forward",
        "Rounding shoulders or arching lower back at the end range"
      ],
      breathingGuidance: "Inhale to hinge; exhale to return to standing.",
      tags: {"bodyweight", "hip_hinge", "pattern_learning"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "hip_hinge_single_leg",
      name: "Single-Leg Hip Hinge",
      shortDescription:
          "Unilateral hinge balancing on one leg with the opposite leg extending straight back.",
      movementPattern: MovementPattern.hinge,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.glutes, MuscleGroup.hamstrings},
      secondaryMuscles: {
        MuscleGroup.lowerBack,
        MuscleGroup.abs,
        MuscleGroup.obliques
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      progressionFamilyId: "hinge",
      progressionRank: 3,
      easierVariationId: "good_morning",
      instructions: [
        "Stand on one leg with knee soft, opposite leg straight, hands on hips or at sides for balance.",
        "Hinge by pushing hips back and reaching extended leg behind you, keeping hips square and back flat.",
        "Drive through the standing foot to return upright; complete eight repetitions per side without touching the free foot down."
      ],
      commonMistakes: [
        "Rotating hips open toward the side",
        "Rounding the back to reach farther"
      ],
      breathingGuidance: "Inhale while hinging; exhale as you return to standing.",
      tags: {
        "bodyweight",
        "unilateral",
        "reps_per_side",
        "balance_demand",
        "hip_hinge"
      },
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "donkey_kick",
      name: "Donkey Kick",
      shortDescription:
          "Quadruped hip extension driving heel toward ceiling with knee bent at ninety degrees.",
      movementPattern: MovementPattern.glute,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.lowerBack,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Start on hands and knees with hands under shoulders, knees under hips, and neck neutral on a comfortable surface.",
        "Keep knee bent at ninety degrees, brace trunk, and lift one heel toward the ceiling by extending the hip without arching the back.",
        "Pause briefly at the top and lower with control; complete ten repetitions per side keeping hips level."
      ],
      commonMistakes: [
        "Arching the lower back to lift the leg higher",
        "Rotating the pelvis toward the lifting leg"
      ],
      breathingGuidance: "Exhale as you kick back; inhale as you lower.",
      tags: {"bodyweight", "quadruped", "reps_per_side"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "fire_hydrant",
      name: "Fire Hydrant",
      shortDescription:
          "Quadruped hip abduction lifting the bent knee outward while keeping the pelvis stable.",
      movementPattern: MovementPattern.glute,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.obliques,
        MuscleGroup.abs,
        MuscleGroup.hipFlexors
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Begin on hands and knees with hands under shoulders, knees under hips, and back neutral.",
        "Brace trunk and lift one knee outward to the side, keeping the knee bent and foot flexed, without shifting weight excessively.",
        "Pause at a comfortable height, then lower with control; complete ten repetitions per side."
      ],
      commonMistakes: [
        "Leaning the torso away from the lifting leg",
        "Rotating the lower back instead of moving at the hip"
      ],
      breathingGuidance: "Exhale as you lift the knee outward; inhale as you lower.",
      tags: {"bodyweight", "quadruped", "reps_per_side", "hip_abduction"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_pike",
      name: "Pike Push-Up",
      shortDescription:
          "Inverted-V press emphasizing shoulders by bending elbows to lower the head toward the floor.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.shoulders, MuscleGroup.triceps},
      secondaryMuscles: {
        MuscleGroup.chest,
        MuscleGroup.upperBack,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Start in an inverted-V with hands slightly wider than shoulders, hips high, and legs straight with heels toward the floor.",
        "Bend elbows and lower the crown of the head toward the floor between your hands while keeping hips elevated.",
        "Press back to the start with control, keeping neck neutral and avoiding shrugging shoulders."
      ],
      commonMistakes: [
        "Letting hips sag into a flat plank",
        "Flaring elbows straight outward and shrugging"
      ],
      breathingGuidance: "Inhale as you lower; exhale as you press up.",
      tags: {"bodyweight", "shoulder_emphasis", "inverted"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_close_grip",
      name: "Close-Grip Push-Up",
      shortDescription:
          "Narrow-hand push-up emphasizing triceps while keeping elbows close to the ribs.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.triceps, MuscleGroup.chest},
      secondaryMuscles: {MuscleGroup.shoulders, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Set hands close together beneath the center of your chest, legs extended with toes on the floor and trunk braced.",
        "Lower chest between hands with elbows tucked near the ribs, keeping hips in one line with shoulders.",
        "Press back to straight arms without flaring elbows outward or sagging the lower back."
      ],
      commonMistakes: [
        "Allowing elbows to flare away from the sides",
        "Sagging hips or piking them upward to assist the press"
      ],
      breathingGuidance: "Inhale while lowering; exhale while pressing.",
      tags: {"bodyweight", "triceps_emphasis", "narrow_hands"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "pushup_wide",
      name: "Wide Push-Up",
      shortDescription:
          "Wide-hand push-up increasing chest stretch and horizontal pressing range.",
      movementPattern: MovementPattern.push,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.chest, MuscleGroup.shoulders},
      secondaryMuscles: {MuscleGroup.triceps, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Place hands wider than shoulders with fingers facing forward and legs extended in a straight plank.",
        "Brace trunk and lower chest between hands with elbows angled outward around forty-five degrees, keeping hips level.",
        "Press back up while maintaining a straight line from head to heels without letting shoulders shrug."
      ],
      commonMistakes: [
        "Placing hands excessively wide and dropping the chest between shoulders",
        "Allowing the lower back to sag under the stretch load"
      ],
      breathingGuidance: "Inhale on the descent; exhale on the press.",
      tags: {"bodyweight", "chest_emphasis", "wide_hands"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "shoulder_tap",
      name: "Shoulder Tap",
      shortDescription:
          "High-plank anti-rotation drill alternately tapping opposite shoulder while resisting trunk twist.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.abs, MuscleGroup.obliques},
      secondaryMuscles: {MuscleGroup.shoulders, MuscleGroup.glutes},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Begin in a high plank with hands under shoulders, feet hip-width apart, and a straight line from head to heels.",
        "Shift weight slightly, lift one hand and tap the opposite shoulder without rotating hips or shoulders.",
        "Return hand to the floor with control and alternate; complete eight taps per side."
      ],
      commonMistakes: [
        "Rotating hips or shoulders with each tap",
        "Placing feet too narrow and losing balance"
      ],
      breathingGuidance: "Breathe steadily and exhale with each tap.",
      tags: {
        "bodyweight",
        "anti_rotation",
        "reps_per_side",
        "wrist_loaded",
        "shoulder_stability"
      },
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "plank_up_down",
      name: "Plank Up-Down",
      shortDescription:
          "Dynamic plank transitioning between high-plank hands and forearm support.",
      movementPattern: MovementPattern.core,
      difficulty: ExerciseDifficulty.level3,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.high,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.abs, MuscleGroup.shoulders},
      secondaryMuscles: {
        MuscleGroup.triceps,
        MuscleGroup.obliques,
        MuscleGroup.glutes
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Start in a forearm plank with elbows under shoulders and body in a straight line.",
        "Press one palm then the other to a high plank, keeping hips level and feet hip-width apart.",
        "Lower one forearm then the other back to the start with control; complete eight full transitions, alternating the leading arm."
      ],
      commonMistakes: [
        "Rocking hips side to side with each transition",
        "Sagging the lower back when moving between supports"
      ],
      breathingGuidance:
          "Breathe rhythmically; exhale as you press to high plank, inhale as you lower.",
      tags: {"bodyweight", "dynamic_plank", "wrist_loaded", "shoulder_stability"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "step_jack",
      name: "Step Jack",
      shortDescription:
          "Low-impact stepping jack with alternating side steps and overhead arm raises.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {
        MuscleGroup.calves,
        MuscleGroup.quadriceps,
        MuscleGroup.glutes
      },
      secondaryMuscles: {
        MuscleGroup.shoulders,
        MuscleGroup.hipFlexors,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 30),
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Stand with feet together and arms by your sides, with clear space at sides and overhead.",
        "Step one foot to the side while sweeping both arms overhead, keeping knees soft and landing on the whole foot without jumping.",
        "Step feet together as arms lower; continue alternating sides at a brisk but controlled rhythm."
      ],
      commonMistakes: [
        "Jumping off the floor instead of stepping",
        "Landing with locked knees or collapsing knees inward"
      ],
      breathingGuidance: "Breathe continuously in rhythm with the steps.",
      tags: {"bodyweight", "no_jumping", "low_impact", "cardio_alternative"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "butt_kicks",
      name: "Butt Kicks",
      shortDescription:
          "Jogging in place driving heels toward glutes with quick arm swings.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.moderate,
      noiseLevel: NoiseLevel.moderate,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.quadriceps,
        MuscleGroup.calves
      },
      secondaryMuscles: {MuscleGroup.glutes, MuscleGroup.hipFlexors, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 20),
      defaultRest: Duration(seconds: 40),
      instructions: [
        "Stand tall with feet hip-width apart and elbows bent at about ninety degrees.",
        "Jog lightly in place, flicking each heel toward the glute quickly without leaning far forward.",
        "Land softly on the forefoot and stay on the balls of your feet while swinging arms naturally."
      ],
      commonMistakes: [
        "Leaning excessively forward and kicking away from the body",
        "Landing heavily on the heels with locked knees"
      ],
      breathingGuidance: "Breathe rhythmically through the jog; avoid holding breath.",
      tags: {"bodyweight", "running_in_place", "cardio"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "skater_step",
      name: "Skater Step",
      shortDescription:
          "Lateral stepping skater with soft side lunges and arm swings without leaving the floor.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.glutes, MuscleGroup.quadriceps},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.calves,
        MuscleGroup.abs,
        MuscleGroup.obliques
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 30),
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Stand with feet hip-width apart, knees soft, and arms relaxed, allowing lateral space on each side.",
        "Step one foot diagonally behind the other, bending front knee softly as you sweep arms across your body.",
        "Push off the front foot and step to the other side, keeping hops tiny or feet grounded for a no-jumping option."
      ],
      commonMistakes: [
        "Jumping high instead of stepping softly",
        "Letting the front knee collapse inward across the toes"
      ],
      breathingGuidance: "Breathe steadily with the lateral rhythm.",
      tags: {"bodyweight", "lateral", "no_jumping", "cardio"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "squat_knee_drive",
      name: "Squat to Knee Drive",
      shortDescription:
          "Bodyweight squat followed by alternating standing knee drives for power and balance.",
      movementPattern: MovementPattern.squat,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      secondaryMuscles: {
        MuscleGroup.hamstrings,
        MuscleGroup.hipFlexors,
        MuscleGroup.calves,
        MuscleGroup.abs
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 45),
      instructions: [
        "Stand with feet about shoulder-width apart, brace trunk, and keep weight over mid-foot.",
        "Lower into a controlled squat to a comfortable depth with knees tracking over toes.",
        "Stand and immediately drive one knee toward hip height without leaning backward, then step down and repeat alternating sides for eight repetitions per side."
      ],
      commonMistakes: [
        "Rounding the back at the squat bottom",
        "Leaning backward or using momentum for the knee drive"
      ],
      breathingGuidance: "Inhale on the squat; exhale as you stand and drive the knee up.",
      tags: {
        "bodyweight",
        "unilateral",
        "reps_per_side",
        "balance_demand",
        "squat_plus_knee"
      },
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "shadow_boxing",
      name: "Shadow Boxing",
      shortDescription:
          "Standing alternating punches with light foot movement and core rotation.",
      movementPattern: MovementPattern.cardio,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.low,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.shoulders, MuscleGroup.obliques},
      secondaryMuscles: {
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.abs,
        MuscleGroup.quadriceps
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 30),
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Adopt a staggered stance with hands up near the face, elbows tucked, and chin slightly tucked.",
        "Extend alternating jabs and crosses with full arm extension while pivoting the rear foot and rotating the trunk lightly.",
        "Keep feet active with small steps, stay relaxed in the shoulders, and return hands to guard after each punch."
      ],
      commonMistakes: [
        "Locking elbows aggressively at full extension",
        "Holding breath and tensing shoulders"
      ],
      breathingGuidance: "Exhale with each punch; inhale as you return to guard.",
      tags: {"bodyweight", "no_jumping", "cardio", "boxing"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "single_leg_stand",
      name: "Single-Leg Stand",
      shortDescription:
          "Quiet single-leg balance hold with eyes forward and hands at hips.",
      movementPattern: MovementPattern.balance,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.calves, MuscleGroup.glutes},
      secondaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.abs},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 20),
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Stand tall with feet hip-width apart and hands on hips, focusing gaze at a fixed point ahead.",
        "Shift weight onto one foot and lift the opposite foot a few centimetres, keeping the standing knee soft and hips level.",
        "Hold for twenty seconds with steady breathing, then switch sides without hopping."
      ],
      commonMistakes: [
        "Locking the standing knee straight",
        "Tilting hips or reaching the lifted leg far away"
      ],
      breathingGuidance: "Breathe slowly and evenly throughout each hold.",
      tags: {"bodyweight", "balance", "duration_per_side", "quiet_hold"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "standing_knee_raise",
      name: "Standing Knee Raise",
      shortDescription:
          "Controlled standing knee lift to hip height with trunk upright and hands at hips.",
      movementPattern: MovementPattern.balance,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.hipFlexors, MuscleGroup.quadriceps},
      secondaryMuscles: {
        MuscleGroup.glutes,
        MuscleGroup.calves,
        MuscleGroup.abs,
        MuscleGroup.obliques
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 8,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Stand tall with feet hip-width apart and hands at hips or holding a wall lightly for balance if needed.",
        "Lift one knee toward hip height with a controlled motion, keeping trunk upright and standing leg soft.",
        "Lower the foot softly without touching momentum, then alternate for eight repetitions per side."
      ],
      commonMistakes: [
        "Leaning backward to lift the knee",
        "Losing balance by moving too quickly"
      ],
      breathingGuidance: "Exhale as you lift the knee; inhale as you lower.",
      tags: {"bodyweight", "balance", "reps_per_side", "controlled"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "ankle_circles",
      name: "Ankle Circles",
      shortDescription:
          "Standing ankle mobility circles lifting one foot and rotating the ankle joint.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.tiny,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.low,
      primaryMuscles: {MuscleGroup.calves},
      secondaryMuscles: {MuscleGroup.quadriceps, MuscleGroup.glutes},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 10,
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Stand near a wall for light balance support if needed, shift weight onto one leg with standing knee soft.",
        "Lift the opposite foot slightly and draw slow, full circles with the toes, rotating from the ankle without moving the knee.",
        "Complete ten circles in each direction, then switch sides keeping motion smooth."
      ],
      commonMistakes: [
        "Rotating the entire leg instead of isolating the ankle",
        "Rushing through small, incomplete circles"
      ],
      breathingGuidance: "Breathe naturally at a relaxed pace.",
      tags: {"bodyweight", "mobility", "reps_per_side", "ankle_mobility"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "arm_circles",
      name: "Arm Circles",
      shortDescription:
          "Standing small-to-large arm rotations for shoulder mobility and warm-up.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level1,
      bodyPosition: ExercisePosition.standing,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.small,
      wristLoad: JointLoad.none,
      kneeLoad: JointLoad.none,
      primaryMuscles: {MuscleGroup.shoulders},
      secondaryMuscles: {MuscleGroup.upperBack, MuscleGroup.chest},
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.timed,
      defaultDuration: Duration(seconds: 30),
      defaultRest: Duration(seconds: 15),
      instructions: [
        "Stand with feet hip-width apart, arms extended to the sides at shoulder height, palms facing forward.",
        "Draw small forward circles, gradually enlarging them, then reverse direction after fifteen seconds.",
        "Keep shoulders relaxed and trunk tall without shrugging toward ears."
      ],
      commonMistakes: [
        "Shrugging shoulders toward ears throughout",
        "Arching the lower back as circles enlarge"
      ],
      breathingGuidance: "Breathe steadily and keep shoulders relaxed.",
      tags: {"bodyweight", "mobility", "warmup", "shoulder_mobility"},
      assetPath: null,
      active: true,
    ),
    Exercise(
      id: "world_greatest_stretch",
      name: "World's Greatest Stretch",
      shortDescription:
          "Dynamic mobility flow stepping into deep lunge, rotating trunk, and reaching overhead.",
      movementPattern: MovementPattern.mobility,
      difficulty: ExerciseDifficulty.level2,
      bodyPosition: ExercisePosition.floor,
      impactLevel: ImpactLevel.low,
      noiseLevel: NoiseLevel.quiet,
      spaceRequirement: SpaceRequirement.medium,
      wristLoad: JointLoad.moderate,
      kneeLoad: JointLoad.moderate,
      primaryMuscles: {MuscleGroup.hipFlexors, MuscleGroup.hamstrings},
      secondaryMuscles: {
        MuscleGroup.glutes,
        MuscleGroup.obliques,
        MuscleGroup.upperBack,
        MuscleGroup.shoulders,
        MuscleGroup.chest
      },
      requiredEquipment: {WorkoutEquipment.none},
      exerciseType: ExerciseType.reps,
      defaultReps: 5,
      defaultRest: Duration(seconds: 30),
      instructions: [
        "Begin in a high plank with hands under shoulders and body in a straight line, then step the right foot outside the right hand into a deep lunge.",
        "Place the left forearm near the floor inside the front foot if comfortable, then rotate the trunk and reach the right arm toward the ceiling, following fingertips with eyes.",
        "Return hand to the floor, step back to plank, and repeat on the opposite side for five repetitions per side."
      ],
      commonMistakes: [
        "Letting the front knee collapse inward or slide far past toes",
        "Forcing shoulder to the floor by over-rotating the lower back"
      ],
      breathingGuidance:
          "Inhale to lengthen the spine in the lunge; exhale during the rotation and reach.",
      tags: {
        "bodyweight",
        "dynamic_mobility",
        "reps_per_side",
        "full_body",
        "lunge_plus_rotation"
      },
      assetPath: null,
      active: true,
    ),

  ]);

  static final Map<String, Exercise> _byId = Map.unmodifiable({
    for (final exercise in all) exercise.id: exercise,
  });

  /// Returns null for an unknown ID; never mutates the catalog.
  static Exercise? byId(String id) => _byId[id];
}
