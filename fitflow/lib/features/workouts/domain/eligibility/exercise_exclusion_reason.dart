/// Reasons an exercise may be excluded for a given user context (5A-2 extended).
enum ExerciseExclusionReason {
  inactiveExercise,
  missingCapability,
  aboveCapability,
  missingEquipment,
  insufficientSpace,
  tooNoisy,
  lowImpactRequired,
  floorRestricted,
  standingOnlyRequired,
  wristLoadRestricted,
  kneeLoadRestricted,
}
