import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_typography.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark surface hierarchy is distinct and readable', () {
    final p = FitFlowColors.dark;
    expect(p.background.computeLuminance(),
        lessThan(p.surface.computeLuminance()));
    expect(p.surface.computeLuminance(),
        lessThan(p.elevatedSurface.computeLuminance()));
    for (final surface in [
      p.background,
      p.surface,
      p.elevatedSurface,
      p.subtleSurface
    ]) {
      for (final text in [p.textPrimary, p.textSecondary, p.textMuted]) {
        expect(fitflowContrast(text, surface), greaterThanOrEqualTo(4.5));
      }
    }
    expect(p.brand, const Color(0xFF67E8C3));
    // Semantic status roles remain distinct from the brand accent.
    expect(p.error, const Color(0xFFFFB4AB));
    expect(p.warning, const Color(0xFFE0B15A));
    expect(p.success, const Color(0xFF7DCEA0));
  });

  test('mint primary, quiet secondary and accessible control sizes', () {
    final theme = AppTheme.dark;
    final p = FitFlowColors.dark;
    final primary = theme.filledButtonTheme.style!;
    expect(primary.backgroundColor!.resolve({}), p.brand);
    expect(primary.foregroundColor!.resolve({}), p.onBrand);
    expect(primary.minimumSize!.resolve({})!.height, inInclusiveRange(52, 56));
    expect(fitflowContrast(p.onBrand, p.brand), greaterThanOrEqualTo(4.5));
    final secondary = theme.outlinedButtonTheme.style!;
    expect(secondary.backgroundColor!.resolve({}), p.surface);
    expect(secondary.foregroundColor!.resolve({}), p.textPrimary);
    expect(secondary.side!.resolve({})!.color, p.border);
    for (final style in [
      primary,
      secondary,
      theme.textButtonTheme.style!,
      theme.iconButtonTheme.style!
    ]) {
      final size = style.minimumSize!.resolve({})!;
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  test('compact typography and surfaces preserve large tabular timer', () {
    expect(FitFlowTypography.screenTitle.fontSize, inInclusiveRange(24, 28));
    expect(FitFlowTypography.displayHero.fontSize, lessThanOrEqualTo(28));
    expect(FitFlowTypography.sectionHeading.fontSize, inInclusiveRange(18, 20));
    expect(FitFlowTypography.cardHeading.fontSize, inInclusiveRange(15, 17));
    expect(FitFlowTypography.timer.fontSize, inInclusiveRange(56, 64));
    expect(FitFlowTypography.timer.fontFeatures,
        contains(FontFeature.tabularFigures()));
    expect(FitFlowRadius.card, inInclusiveRange(14, 18));
    expect(FitFlowRadius.medium, inInclusiveRange(8, 12));
  });

  testWidgets('shared hero is solid and primary remains usable at 2x text',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
            body: FitFlowV2HeroSurface(
          child: FitFlowPrimaryButton(label: 'Start workout', onPressed: () {}),
        )),
      ),
    ));
    final box = tester.widget<DecoratedBox>(find
        .descendant(
            of: find.byType(FitFlowV2HeroSurface),
            matching: find.byType(DecoratedBox))
        .first);
    expect((box.decoration as BoxDecoration).gradient, isNull);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(52));
    expect(tester.takeException(), isNull);
  });

  test(
      'navigation has mint selection, quiet icons and compact non-pill indicator',
      () {
    final nav = AppTheme.dark.navigationBarTheme;
    expect(nav.height, 64);
    expect(nav.backgroundColor, FitFlowColors.dark.surface);
    expect(nav.iconTheme!.resolve({WidgetState.selected})!.color,
        FitFlowColors.dark.brand);
    expect(nav.labelTextStyle!.resolve({WidgetState.selected})!.color,
        FitFlowColors.dark.brand);
    expect(nav.iconTheme!.resolve({})!.color, FitFlowColors.dark.textSecondary);
    expect(nav.indicatorShape, isA<RoundedRectangleBorder>());
    expect(AppTheme.dark.navigationRailTheme.selectedIconTheme!.color,
        FitFlowColors.dark.brand);
  });

  testWidgets('four destinations and expanded rail retain selection callback',
      (tester) async {
    var selected = 0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final width in [360.0, 900.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: FitFlowNavigationShell(
            selectedIndex: 0,
            onSelected: (i) => selected = i,
            destinations: const [
              FitFlowNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home'),
              FitFlowNavDestination(
                  icon: Icons.fitness_center_outlined,
                  selectedIcon: Icons.fitness_center,
                  label: 'Workouts'),
              FitFlowNavDestination(
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights,
                  label: 'Progress'),
              FitFlowNavDestination(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile'),
            ],
            body: const SizedBox.expand()),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(width < 840 ? NavigationBar : NavigationRail),
          findsOneWidget);
      await tester.tap(find.text('Profile'));
      expect(selected, 3);
      expect(tester.takeException(), isNull);
    }
  });

  test('light theme stays light with readable native action states', () {
    final theme = AppTheme.light;
    final p = FitFlowColors.light;
    expect(theme.brightness, Brightness.light);
    expect(fitflowContrast(p.onBrand, p.brand), greaterThanOrEqualTo(4.5));
    expect(
        fitflowContrast(p.textPrimary, p.surface), greaterThanOrEqualTo(4.5));
    expect(
        theme.filledButtonTheme.style!.backgroundColor!
            .resolve({WidgetState.disabled}),
        p.subtleSurface);
    expect(
        theme.filledButtonTheme.style!.overlayColor!
            .resolve({WidgetState.focused}),
        isNotNull);
  });
}
