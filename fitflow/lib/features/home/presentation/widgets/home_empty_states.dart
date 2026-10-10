import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeEmptyStates {
  HomeEmptyStates._();
  static Widget missingUserProfile(BuildContext context,
          {VoidCallback? onAction}) =>
      _page(
        FitFlowEmptyState(
            icon: Icons.person_outline,
            title: context.l10n.homeMissingProfile,
            message: context.l10n.homeMissingProfileBody,
            action: FitFlowPrimaryButton(
                label: context.l10n.homeCompleteProfile, onPressed: onAction)),
      );
  static Widget missingCapabilityProfile(BuildContext context,
          {VoidCallback? onAction}) =>
      _page(
        FitFlowEmptyState(
            icon: Icons.accessibility_new_outlined,
            title: context.l10n.homeMissingAssessment,
            message: context.l10n.homeMissingAssessmentBody,
            action: FitFlowPrimaryButton(
                label: context.l10n.homeStartAssessment, onPressed: onAction)),
      );
  static Widget noWorkoutAvailable(BuildContext context,
          {required UserFitnessProfile userProfile}) =>
      FitFlowEmptyState(
        icon: Icons.tune_outlined,
        title: context.l10n.homeNoPlan,
        message: context.l10n.homeNoPlanBody,
        action: FitFlowPrimaryButton(
            label: context.l10n.homeReviewProfile,
            onPressed: () => context.go(AppRoutes.profile)),
      );
  static Widget _page(Widget content) => Scaffold(
          body: SafeArea(
              child: Center(
        child: SingleChildScrollView(child: FitFlowMaxWidth(child: content)),
      )));
}
