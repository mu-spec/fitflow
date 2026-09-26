/// Why a capability value changed, for future auditing.
///
/// Stable enum names suitable for future serialization.
enum CapabilitySource {
  initialAssessment,
  workoutFeedback,
  progression,
  manualAdjustment,
}
