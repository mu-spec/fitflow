import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/accessibility/system_motion.dart';
import 'package:fitflow/core/design/fitflow_colors.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_motion.dart';
import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_typography.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/widgets/fitflow_navigation.dart';
import 'package:fitflow/core/design/widgets/fitflow_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tokens', () {
    test('text pairs meet WCAG AA in light and dark', () {
      for (final palette in [FitFlowColors.light, FitFlowColors.dark]) {
        _expectText(palette.textPrimary, palette.background);
        _expectText(palette.textPrimary, palette.surface);
        _expectText(palette.textSecondary, palette.background);
        _expectText(palette.textSecondary, palette.surface);
        _expectText(palette.textMuted, palette.background);
        _expectText(palette.textMuted, palette.surface);
        _expectText(palette.textMuted, palette.subtleSurface);
        _expectText(palette.onBrand, palette.brand);
        _expectText(palette.onError, palette.error);
        _expectText(palette.onSuccess, palette.success);
        _expectText(palette.onWarning, palette.warning);
        _expectText(palette.onInfo, palette.info);
        _expectText(palette.onWorkoutActive, palette.workoutActive);
        _expectText(palette.onWorkoutRest, palette.workoutRest);
        _expectText(palette.onProgress, palette.progress);
      }
    });

    test('spacing scale is small and strictly increasing', () {
      expect(FitFlowSpace.scale, hasLength(9));
      for (var i = 1; i < FitFlowSpace.scale.length; i++) {
        expect(FitFlowSpace.scale[i], greaterThan(FitFlowSpace.scale[i - 1]));
      }
      expect(FitFlowSpace.screenHorizontal, 24);
    });

    test('shape language uses distinct radii', () {
      expect(FitFlowRadius.small, lessThan(FitFlowRadius.medium));
      expect(FitFlowRadius.medium, lessThan(FitFlowRadius.card));
      expect(FitFlowRadius.card, lessThan(FitFlowRadius.sheet));
      expect(FitFlowRadius.sheet, lessThan(FitFlowRadius.pill));
    });

    test('motion is short, ordered, and not bouncy', () {
      expect(FitFlowMotion.micro, lessThan(FitFlowMotion.standard));
      expect(FitFlowMotion.standard, lessThan(FitFlowMotion.emphasized));
      expect(FitFlowMotion.emphasized,
          lessThanOrEqualTo(const Duration(milliseconds: 400)));
      expect(FitFlowMotion.standardCurve, isNot(Curves.bounceOut));
      expect(FitFlowMotion.emphasizedCurve, isNot(Curves.elasticOut));
    });

    test('timer and stat styles stay large and tabular', () {
      expect(FitFlowTypography.timer.fontSize, greaterThanOrEqualTo(48));
      expect(
        FitFlowTypography.timer.fontFeatures,
        contains(FontFeature.tabularFigures()),
      );
      expect(
        FitFlowTypography.stat.fontFeatures,
        contains(FontFeature.tabularFigures()),
      );
    });

    test('window size comes from width, not a device model', () {
      expect(FitFlowLayout.fromWidth(320), FitFlowWindowSize.compact);
      expect(FitFlowLayout.fromWidth(700), FitFlowWindowSize.medium);
      expect(FitFlowLayout.fromWidth(900), FitFlowWindowSize.expanded);
    });
  });

  group('theme', () {
    test('light and dark expose the semantic extension and 48dp controls', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.extension<FitFlowTheme>(), isNotNull);
        expect(theme.brightness, isNotNull);
        expect(
          theme.filledButtonTheme.style?.minimumSize?.resolve({}),
          const Size(48, 52),
        );
        expect(theme.scaffoldBackgroundColor, isNot(theme.colorScheme.primary));
        final focused = theme.filledButtonTheme.style?.overlayColor
            ?.resolve({WidgetState.focused});
        expect(focused, isNotNull);
      }
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    testWidgets('reduced motion collapses design-system durations',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

      late Duration micro;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              micro = SystemMotion.micro(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(micro, Duration.zero);
      expect(
        const FitFlowPageTransitionsBuilder(reducedMotion: true)
            .transitionDuration,
        Duration.zero,
      );
      expect(
        const FitFlowPageTransitionsBuilder().transitionDuration,
        FitFlowMotion.standard,
      );
    });
  });

  group('components', () {
    testWidgets('primary button is 48dp, disabled, and loading',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                FitFlowPrimaryButton(label: 'Start', onPressed: () => taps++),
                const FitFlowPrimaryButton(label: 'Wait', onPressed: null),
                const FitFlowPrimaryButton(
                  label: 'Save',
                  onPressed: null,
                  loading: true,
                ),
              ],
            ),
          ),
        ),
      );

      final start = tester.getSize(find.widgetWithText(FilledButton, 'Start'));
      expect(start.height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('Start'));
      expect(taps, 1);
      await tester.tap(find.text('Wait'));
      expect(taps, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Save, loading'), findsOneWidget);
    });

    testWidgets('selection is a check, not color alone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: FitFlowSelectableTile(label: 'Quiet room', selected: true),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Quiet room'), findsOneWidget);
      final tile = tester.widget<FitFlowSelectableTile>(
        find.byType(FitFlowSelectableTile),
      );
      expect(tile.selected, isTrue);
    });

    testWidgets('status chip includes an icon with the label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: FitFlowStatusChip(label: 'Rest', status: FitFlowStatus.rest),
          ),
        ),
      );
      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
    });

    testWidgets('empty and error states keep their message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Column(
              children: [
                FitFlowEmptyState(
                    title: 'Nothing yet', message: 'Start a session.'),
                FitFlowErrorState(
                    title: 'Could not load', message: 'Try again.'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('navigation uses a bar on phones and a rail when expanded', (
      tester,
    ) async {
      var selected = 0;
      Future<void> pumpAt(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: FitFlowNavigationShell(
              selectedIndex: selected,
              onSelected: (index) => selected = index,
              destinations: const [
                FitFlowNavDestination(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                FitFlowNavDestination(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
              body: const Text('Body'),
            ),
          ),
        );
      }

      await pumpAt(const Size(360, 700));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(selected, 1);

      selected = 0;
      await pumpAt(const Size(900, 800));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}

void _expectText(Color foreground, Color background) {
  expect(
    fitflowContrast(foreground, background),
    greaterThanOrEqualTo(4.5),
    reason: '$foreground on $background',
  );
}
