/// Where a Player session was launched from.
///
/// - [adaptive]: generated Home workout (M12 modes apply).
/// - [custom]: user-built custom workout (M13; never affects levels).
/// - [program]: a planned session of an adaptive program (M16). Always runs
///   in `WorkoutSessionMode.standard`; never reads the Home session mode.
enum WorkoutSessionOrigin {
  adaptive,
  custom,
  program,
}
