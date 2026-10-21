import 'package:fitflow/features/workout_player/application/workout_player_state.dart';
import 'package:fitflow/features/workout_player/presentation/widgets/workout_player_exercise_center.dart';
import 'package:flutter/material.dart';

/// The engine supplies the actual upcoming prescription during transition.
class WorkoutPlayerTransitionView extends StatelessWidget {
  const WorkoutPlayerTransitionView(
      {super.key, required this.state, this.mediaHeight = 240});
  final WorkoutPlayerState state;
  final double mediaHeight;
  @override
  Widget build(BuildContext context) =>
      WorkoutPlayerExerciseCenter(state: state, mediaHeight: mediaHeight);
}
