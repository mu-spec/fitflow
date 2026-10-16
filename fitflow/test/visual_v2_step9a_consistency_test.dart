import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_exercise_row.dart';
import 'package:fitflow/features/workout_preview/presentation/widgets/workout_preview_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

Future<void> _pumpProgramSessionPreview(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
  bool generationFails = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  SharedPreferences.setMockInitialValues({});

  final router = programTestRouter(
    initialLocation: AppRoutes.programSessionPreview(
      'balanced_foundations',
      'balanced_foundations_w1_s3',
    ),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: programOverrides(
        profile: generationFails ? programUngenerableProfile() : null,
      ),
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          theme: dark ? AppTheme.dark : AppTheme.light,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Visual V2 Step 9A Program Session Preview consistency', () {
    for (final dark in [false, true]) {
      testWidgets(
        '${dark ? 'dark' : 'light'} mode shares the V2 page and preview hierarchy',
        (tester) async {
          await _pumpProgramSessionPreview(tester, dark: dark);
          final semantics = tester.ensureSemantics();
          try {
            final preview = find.byType(ProgramSessionPreviewScreen);
            final scaffoldFinder = find.descendant(
              of: preview,
              matching: find.byType(Scaffold),
            );
            expect(scaffoldFinder, findsOneWidget);
            final scaffold = tester.widget<Scaffold>(scaffoldFinder);
            final visual = FitFlowVisualV2.of(tester.element(scaffoldFinder));
            expect(scaffold.backgroundColor, visual.page);

            final appBar = tester.widget<AppBar>(find.descendant(
              of: preview,
              matching: find.byType(AppBar),
            ));
            expect(appBar.backgroundColor, visual.page);
            expect(appBar.scrolledUnderElevation, 0);

            final maxWidth = tester.widget<FitFlowMaxWidth>(find.descendant(
              of: preview,
              matching: find.byType(FitFlowMaxWidth),
            ));
            expect(maxWidth.maxWidth, FitFlowLayout.maxContentWidth);
            final list = tester.widget<ListView>(find.descendant(
              of: preview,
              matching: find.byType(ListView),
            ));
            expect(list.padding, const EdgeInsets.all(FitFlowSpace.xl));

            final infoSurfaces = find.descendant(
              of: preview,
              matching: find.byType(FitFlowV2InfoSurface),
            );
            expect(infoSurfaces, findsNWidgets(2));
            final surfaces =
                tester.widgetList<FitFlowV2InfoSurface>(infoSurfaces).toList();
            expect(surfaces.map((surface) => surface.tonal), [false, true]);
            expect(
              find.descendant(
                of: infoSurfaces.at(1),
                matching: find.byType(ExcludeSemantics),
              ),
              findsWidgets,
            );
            final metricTags = find.descendant(
              of: preview,
              matching: find.byType(FitFlowV2Tag),
            );
            expect(metricTags, findsNWidgets(4));
            for (var i = 0; i < 4; i++) {
              expect(
                find.descendant(
                  of: metricTags.at(i),
                  matching: find.byType(ExcludeSemantics),
                ),
                findsWidgets,
              );
            }

            final sectionHeaders = tester
                .widgetList<WorkoutPreviewSectionHeader>(find.descendant(
                  of: preview,
                  matching: find.byType(WorkoutPreviewSectionHeader),
                ))
                .toList();
            expect(sectionHeaders, isNotEmpty);
            expect(sectionHeaders.every((header) => header.visualV2), isTrue);
            final rows = tester
                .widgetList<WorkoutPreviewExerciseRow>(find.descendant(
                  of: preview,
                  matching: find.byType(WorkoutPreviewExerciseRow),
                ))
                .toList();
            expect(rows, isNotEmpty);
            expect(rows.every((row) => row.visualV2), isTrue);
            expect(rows.every((row) => row.sequenceNumber == null), isTrue);

            final headings = tester
                .widgetList<Semantics>(find.descendant(
                  of: preview,
                  matching: find.byType(Semantics),
                ))
                .where((semantics) => semantics.properties.header == true);
            expect(headings, isNotEmpty);
            final sessionHeading = find.ancestor(
              of: find.text('Week 1 • Session 3'),
              matching: find.byType(Semantics),
            );
            expect(sessionHeading, findsWidgets);
            expect(
              tester.widgetList<Semantics>(sessionHeading).any(
                    (semantics) => semantics.properties.header == true,
                  ),
              isTrue,
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }

    testWidgets(
        'compact text-scaled layout keeps token gutters and a 56dp+ CTA',
        (tester) async {
      await _pumpProgramSessionPreview(
        tester,
        size: const Size(320, 720),
        textScale: 1.5,
      );
      final preview = find.byType(ProgramSessionPreviewScreen);
      final list = tester.widget<ListView>(find.descendant(
        of: preview,
        matching: find.byType(ListView),
      ));
      expect(list.padding, const EdgeInsets.all(FitFlowSpace.md));
      expect(tester.takeException(), isNull);

      await programScrollTo(tester, find.text('Start workout'), step: 200);
      final buttonFinder = find.ancestor(
        of: find.text('Start workout'),
        matching: find.byType(FilledButton),
      );
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
      expect(tester.getSize(buttonFinder).height, greaterThanOrEqualTo(56));
      expect(tester.takeException(), isNull);
    });

    testWidgets('generation failure reuses the shared error presentation',
        (tester) async {
      await _pumpProgramSessionPreview(
        tester,
        size: const Size(320, 720),
        textScale: 1.5,
        generationFails: true,
      );
      await programScrollTo(
        tester,
        find.text(
            "This program workout can't be generated with your current setup."),
      );
      expect(find.byType(FitFlowErrorState), findsOneWidget);
      expect(
        find.text(
            "This program workout can't be generated with your current setup."),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your current environment, equipment, or workout preferences leave too few compatible exercises for a complete session.',
        ),
        findsOneWidget,
      );
      expect(find.byType(WorkoutPreviewExerciseRow), findsNothing);
      expect(find.text('Start workout'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
