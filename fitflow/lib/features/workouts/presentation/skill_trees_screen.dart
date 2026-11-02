import 'package:flutter/material.dart';
import 'exercise_library_screen.dart';

class SkillTreesScreen extends StatelessWidget {
  const SkillTreesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ExerciseLibraryScreen(initialSkills: true);
}
