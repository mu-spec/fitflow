import 'package:fitflow/core/design/workout_design_theme.dart';
import 'package:flutter/material.dart';

/// Home opts into the new foundation without restyling neighboring screens.
class HomeTheme extends StatelessWidget {
  const HomeTheme({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => WorkoutDesignTheme(child: child);
}
