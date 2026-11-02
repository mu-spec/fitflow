import 'package:flutter/material.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';

class ExerciseCharacteristicsSection extends StatelessWidget {
  const ExerciseCharacteristicsSection({super.key, required this.exercise});
  final Exercise exercise;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (exercise.bodyPosition != null)
          Chip(label: Text(exercise.bodyPosition!.label)),
        Chip(label: Text('${exercise.impactLevel.label} impact')),
        Chip(label: Text(exercise.noiseLevel.label)),
        Chip(label: Text('${exercise.spaceRequirement.label} space')),
        Chip(label: Text('Wrist load: ${exercise.wristLoad.label}')),
        Chip(label: Text('Knee load: ${exercise.kneeLoad.label}')),
      ]);
}
