import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class HomeErrorState extends StatelessWidget {
  const HomeErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Center(
        child: SingleChildScrollView(
            child: FitFlowMaxWidth(
                child: Semantics(
          liveRegion: true,
          child: FitFlowErrorState(
              title: context.l10n.homeErrorTitle,
              message: context.l10n.homeErrorBody,
              action: FitFlowPrimaryButton(
                  label: context.l10n.retry, onPressed: onRetry)),
        ))),
      )));
}
