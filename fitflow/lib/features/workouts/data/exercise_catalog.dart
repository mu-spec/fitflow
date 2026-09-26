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
  ]);

  static final Map<String, Exercise> _byId = Map.unmodifiable({
    for (final exercise in all) exercise.id: exercise,
  });

  /// Returns null for an unknown ID; never mutates the catalog.
  static Exercise? byId(String id) => _byId[id];
}
