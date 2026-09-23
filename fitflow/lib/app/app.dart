import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_router.dart';
import 'package:fitflow/core/constants/app_constants.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FitFlowApp extends ConsumerWidget {
  const FitFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearanceMode = ref.watch(appearanceControllerProvider).value ??
        AppearanceMode.system;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appearanceMode.toThemeMode(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
