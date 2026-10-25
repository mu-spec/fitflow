import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/settings/presentation/widgets/profile_settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/part6_quality_helpers.dart';

void main() {
  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915)
  ]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Profile utilities $size dark=$dark scale=$scale',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
          addTearDown(tester.view.reset);
          await seedPart6();
          final router = await part6Route(tester, AppRoutes.profile,
              dark: dark, scale: scale);
          addTearDown(router.dispose);
          for (final route in [
            AppRoutes.profile,
            AppRoutes.settings,
            AppRoutes.fitnessProfile,
            AppRoutes.equipment,
            AppRoutes.workoutPreferences,
            AppRoutes.backupRestore,
            AppRoutes.privacyPolicy
          ]) {
            router.go(route);
            await tester.pumpAndSettle();
            final content = find
                .descendant(
                    of: find.byType(ProfileSettingsTheme),
                    matching: find.byType(Material))
                .first;
            expect(Theme.of(tester.element(content)).colorScheme.primary,
                dark ? const Color(0xFFD4E779) : const Color(0xFF526515));
            final tabs = find.byType(NavigationBar);
            expect(Theme.of(tester.element(tabs)).colorScheme.primary,
                (dark ? AppTheme.dark : AppTheme.light).colorScheme.primary);
            if (scale == 1 &&
                [AppRoutes.profile, AppRoutes.settings].contains(route)) {
              final labels = route == AppRoutes.profile
                  ? [
                      'Fitness Profile',
                      'Equipment',
                      'Workout Preferences',
                      'Settings',
                      'Movement levels'
                    ]
                  : [
                      'Appearance',
                      'Workout reminders',
                      'Backup & restore',
                      'Privacy Policy'
                    ];
              for (final label in labels) {
                expect(find.text(label).hitTestable(), findsOneWidget,
                    reason: '$route $label immediately visible');
                expect(tester.getBottomRight(find.text(label)).dy,
                    lessThan(tester.getTopLeft(tabs).dy),
                    reason: '$label clear of navigation');
              }
            }
            if ([
              AppRoutes.fitnessProfile,
              AppRoutes.equipment,
              AppRoutes.workoutPreferences
            ].contains(route)) {
              final save = find.widgetWithText(FilledButton, 'Save changes');
              final cancel = find.widgetWithText(TextButton, 'Cancel');
              expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
              expect(cancel.hitTestable(), findsOneWidget);
              expect(tester.getBottomRight(save).dy,
                  lessThanOrEqualTo(tester.getTopLeft(tabs).dy));
            }
            if (route == AppRoutes.settings) {
              await tester.ensureVisible(find.text('Appearance'));
              await tester.tap(find.text('Appearance'));
              await tester.pumpAndSettle();
              expect(find.text('System default'), findsOneWidget,
                  reason: 'Selected summary is hidden while choosing');
              await tester.ensureVisible(find.text('Workout reminders'));
              await tester.tap(find.text('Workout reminders'));
              await tester.pumpAndSettle();
              await tester.ensureVisible(find.text('Send test notification'));
              await tester.pumpAndSettle();
              expect(find.text('Send test notification').hitTestable(),
                  findsOneWidget);
              // Styling checks never enable real reminders or import user data.
            }
            expect(tester.takeException(), isNull, reason: route);
          }
        });
      }
    }
  }
}
