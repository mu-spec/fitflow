import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:flutter/material.dart';

/// Shared layout for all onboarding steps: progress, title, content, and
/// the Back / Continue controls.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.content,
    required this.canGoBack,
    required this.canContinue,
    required this.trailingLabel,
    required this.onBack,
    required this.onContinue,
  });

  final int step;
  final int totalSteps;
  final String title;
  final Widget content;
  final bool canGoBack;
  final bool canContinue;
  final String trailingLabel;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                16,
                AppDimens.screenPadding,
                0,
              ),
              child: OnboardingProgress(step: step, totalSteps: totalSteps),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    content,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.screenPadding,
                0,
                AppDimens.screenPadding,
                16,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: canGoBack ? onBack : null,
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: canContinue ? onContinue : null,
                    child: Text(trailingLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
