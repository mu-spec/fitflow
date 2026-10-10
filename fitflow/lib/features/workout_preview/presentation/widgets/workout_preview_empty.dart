import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class WorkoutPreviewEmpty extends StatelessWidget {
  const WorkoutPreviewEmpty({super.key});
  @override
  Widget build(BuildContext context) => FitFlowEmptyState(
      title: context.l10n.flowEmptyTitle, message: context.l10n.flowEmptyBody);
}
