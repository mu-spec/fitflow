import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPreviewAdaptiveNote extends StatelessWidget {
  const WorkoutPreviewAdaptiveNote({super.key});
  @override
  Widget build(BuildContext context) => Text(context.l10n.flowAdaptiveNote,
      style: Theme.of(context).textTheme.bodySmall);
}
