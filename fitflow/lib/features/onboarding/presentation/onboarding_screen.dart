import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/onboarding_pages.dart';
import 'package:fitflow/features/onboarding/presentation/onboarding_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding flow: walks through the placeholder steps, then opens Home.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const String _getStartedLabel = 'Get Started';
  static const String _continueLabel = 'Continue';

  int _index = 0;

  bool get _isLastPage => _index == OnboardingPages.all.length - 1;

  void _showPreviousPage() {
    if (_index > 0) {
      setState(() => _index--);
    }
  }

  void _showNextPage() {
    if (_isLastPage) {
      context.go(AppRoutes.home);
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingPages.all;

    return OnboardingShell(
      step: _index + 1,
      totalSteps: pages.length,
      page: pages[_index],
      canGoBack: _index > 0,
      trailingLabel: _isLastPage ? _getStartedLabel : _continueLabel,
      onBack: _showPreviousPage,
      onContinue: _showNextPage,
    );
  }
}
