import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/core/design/media/program_media_registry.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/onboarding/data/workout_duration.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/programs/presentation/widgets/workouts_program_cards.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_exercise_entry.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_storage.dart';
import 'package:fitflow/features/workouts/domain/custom/custom_workout_template.dart';
import 'package:fitflow/features/workouts/presentation/workouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

/// Step 3 Visual V2 Workouts hub contract. Functional Workouts suites remain
/// the behavior gate; this file pins the new presentation language only.
void main() {
  final t0 = DateTime.utc(2026, 10, 1);

  CustomWorkoutTemplate customTemplate(String id, String name) =>
      CustomWorkoutTemplate(
        id: id,
        name: name,
        targetDuration: WorkoutDuration.fifteenMinutes,
        createdAt: DateTime.utc(2026, 10, 2),
        updatedAt: DateTime.utc(2026, 10, 2),
        warmup: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'march_in_place',
              sets: 1,
              workDuration: const Duration(seconds: 20),
              restBetweenSets: Duration.zero)
        ],
        main: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'squat_bodyweight',
              sets: 2,
              repsPerSet: 10,
              restBetweenSets: const Duration(seconds: 30))
        ],
        cooldown: [
          CustomWorkoutExerciseEntry(
              exerciseId: 'cobra_stretch',
              sets: 1,
              workDuration: const Duration(seconds: 20),
              restBetweenSets: Duration.zero)
        ],
      );

  AdaptiveProgramsState activeState(
      {String programId = 'balanced_foundations', List<String>? done}) {
    final completed = done ??
        const [
          'balanced_foundations_w1_s1',
          'balanced_foundations_w1_s2',
          'balanced_foundations_w1_s3',
          'balanced_foundations_w2_s1',
        ];
    var i = 0;
    return AdaptiveProgramsState(
      activeProgramId: programId,
      progressByProgram: {
        programId: AdaptiveProgramProgress(
          programId: programId,
          startedAt: t0,
          updatedAt: t0,
          completions: [
            for (final id in completed)
              AdaptiveProgramSessionCompletion(
                plannedSessionId: id,
                playerSessionId: 'p${i++}',
                completedAt: t0,
              ),
          ],
        ),
      },
    );
  }

  /// Full hub router: unchanged destinations with stub screens for the
  /// Explore/Create taps whose real screens are owned by other suites.
  GoRouter hubRouter() => GoRouter(
        initialLocation: AppRoutes.workouts,
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Home stub'))),
          ),
          GoRoute(
            path: AppRoutes.workouts,
            builder: (context, state) => const Scaffold(body: WorkoutsScreen()),
            routes: [
              GoRoute(
                path: 'programs',
                builder: (context, state) => const ProgramsOverviewScreen(),
                routes: [
                  GoRoute(
                    path: ':programId',
                    builder: (context, state) => ProgramDetailScreen(
                      programId: state.pathParameters['programId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'session/:sessionId',
                        builder: (context, state) =>
                            ProgramSessionPreviewScreen(
                          programId: state.pathParameters['programId']!,
                          sessionId: state.pathParameters['sessionId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'exercise-library',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Library stub'))),
              ),
              GoRoute(
                path: 'skill-trees',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Skill stub'))),
              ),
              GoRoute(
                path: 'custom/:id/edit',
                builder: (context, state) => Scaffold(
                    body: Text('Edit ${state.pathParameters['id']}')),
              ),
              GoRoute(
                path: 'custom/new',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Create stub'))),
              ),
              GoRoute(
                path: 'custom/:id',
                builder: (context, state) => Scaffold(
                    body: Text('Detail ${state.pathParameters['id']}')),
              ),
            ],
          ),
        ],
      );

  Future<void> pumpHub(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
    bool reduced = true,
    Size? size,
    bool activeProgram = false,
    String activeProgramId = 'balanced_foundations',
    bool custom = false,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
    }
    final prefs = <String, Object>{};
    if (activeProgram) {
      prefs[AdaptiveProgramsStorage.key] = AdaptiveProgramsStorage.encode(
          activeState(
              programId: activeProgramId,
              done:
                  activeProgramId == 'balanced_foundations' ? null : const []));
    }
    SharedPreferences.setMockInitialValues(prefs);
    if (custom) {
      await const CustomWorkoutStorage()
          .saveAll([customTemplate('v2-custom', 'TEST Step Three Lift')]);
    }
    final router = hubRouter();
    addTearDown(() {
      router.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: programOverrides(),
        child: MediaQuery(
          // Mirror what WidgetsApp provides in production: the view's logical
          // size. The page reads MediaQuery.sizeOf for its responsive split.
          data: MediaQueryData(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
            size: tester.view.physicalSize / tester.view.devicePixelRatio,
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

  Finder programsCard() => find.byKey(const Key('v2_programs_feature'));

  group('Visual V2 Workouts hub', () {
    testWidgets('hierarchy: header, programs feature, custom, explore, note',
        (tester) async {
      await pumpHub(tester);
      expect(find.text('Your workouts'), findsOneWidget);
      expect(find.text('FITFLOW'), findsOneWidget);
      expect(find.text('Follow a program or build a workout of your own.'),
          findsNothing);

      expect(programsCard(), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Programs'), findsOneWidget);
      expect(find.text('Plans for your level and setup.'),
          findsOneWidget);
      expect(find.byType(FitFlowProgramImage), findsOneWidget);
      expect(find.byType(FitFlowV2FeatureArt), findsNothing);

      expect(find.text('Custom workouts'), findsOneWidget);
      expect(find.byKey(const Key('v2_custom_empty')), findsOneWidget);
      expect(find.text('No custom workouts yet'), findsNothing);
      expect(find.text('Choose exercises for your own workout.'), findsOneWidget);

      expect(find.text('Explore'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center_outlined), findsWidgets);
      expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);

      expect(find.text('Today’s workout'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);

      // Vertical hierarchy: page title leads, then Programs, then Custom,
      // then Explore destinations.
      final titleY = tester.getCenter(find.text('Your workouts')).dy;
      final programsY = tester.getCenter(programsCard()).dy;
      final customY = tester.getCenter(find.text('Custom workouts')).dy;
      final exploreY = tester.getCenter(find.text('Explore')).dy;
      expect(titleY, lessThan(programsY));
      expect(programsY, lessThan(customY));
      expect(customY, lessThan(exploreY));

      // The local hub palette does not replace the surrounding app theme.
      final ctx = tester.element(programsCard());
      final scaffold = tester.widget<Scaffold>(find.descendant(
          of: find.byType(WorkoutsScreen), matching: find.byType(Scaffold)));
      expect(scaffold.backgroundColor, FitFlowVisualV2.of(ctx).page);
    });

    testWidgets(
        'Programs uses a decorative registered cover and collection route',
        (tester) async {
      await pumpHub(tester);
      final photo = tester.widget<FitFlowProgramImage>(find.descendant(
          of: programsCard(), matching: find.byType(FitFlowProgramImage)));
      expect(ProgramMediaRegistry.lookup(photo.programId), isNotNull);
      expect(photo.decorative, isTrue);
      expect(photo.width / photo.height, closeTo(4 / 3, .001));
      expect(find.text('Active program'), findsNothing);
      expect(find.text('Recommended'), findsNothing);
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramsOverviewScreen), findsOneWidget);
    });

    testWidgets('active program keeps real continuation and leads Programs',
        (tester) async {
      await pumpHub(tester, activeProgram: true);
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('Balanced Foundations'), findsOneWidget);
      expect(find.text('4 of 12 sessions'), findsOneWidget);
      expect(find.textContaining('Week 2 • Next: Session 2'), findsOneWidget);

      // Compact continuation surface, still the exact existing content/action.
      final card = find.byType(ActiveProgramCard);
      expect(
          find.descendant(
              of: card, matching: find.byType(FitFlowV2HeroSurface)),
          findsNothing);
      expect(
          find.descendant(of: card, matching: find.byType(FitFlowV2FeatureArt)),
          findsNothing);
      final cover = tester.widget<FitFlowProgramImage>(find.descendant(
          of: card, matching: find.byType(FitFlowProgramImage)));
      expect(cover.programId, 'balanced_foundations');
      expect(cover.width / cover.height, closeTo(4 / 3, .001));

      // Continuation sits above the Programs discovery feature.
      final activeY = tester.getCenter(card).dy;
      expect(activeY, lessThan(tester.getCenter(programsCard()).dy));

      final cta = find.widgetWithText(FilledButton, 'Continue');
      expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);

      // No active program -> no continuation band at all.
      await pumpHub(tester, activeProgram: false, custom: true);
      expect(find.text('Active program'), findsNothing);
      expect(find.byType(FitFlowV2HeroSurface), findsNothing);
    });

    testWidgets(
        'active cover follows every canonical ID without changing state',
        (tester) async {
      for (final dark in [false, true]) {
        for (final entry in ProgramMediaRegistry.entries) {
          await pumpHub(tester,
              activeProgram: true,
              activeProgramId: entry.programId,
              dark: dark,
              scale: 2,
              size: const Size(320, 700));
          final photo = tester.widget<FitFlowProgramImage>(find.descendant(
              of: find.byType(ActiveProgramCard),
              matching: find.byType(FitFlowProgramImage)));
          expect(photo.programId, entry.programId);
          expect(photo.width / photo.height, closeTo(4 / 3, .001));
          final saved = await const AdaptiveProgramsStorage().load();
          expect(saved.activeProgramId, entry.programId);
          expect(find.text('Continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('complete program keeps factual completion and detail route',
        (tester) async {
      final done = [
        for (var w = 1; w <= 4; w++)
          for (var s = 1; s <= 3; s++) 'stay_active_starter_w${w}_s$s'
      ];
      final prefs = {
        AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(
            activeState(programId: 'stay_active_starter', done: done))
      };
      SharedPreferences.setMockInitialValues(prefs);
      final router = hubRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: programOverrides(),
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child:
                MaterialApp.router(theme: AppTheme.light, routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 of 12 sessions'), findsOneWidget);
      expect(find.text('Program complete'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'View program'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
    });

    testWidgets('custom empty state: one explanation and one create action',
        (tester) async {
      await pumpHub(tester);
      final card = find.byKey(const Key('v2_custom_empty'));
      expect(card, findsOneWidget);
      expect(
          find.descendant(of: card, matching: find.byType(FitFlowV2FeatureArt)),
          findsNothing);
      expect(find.text('Create workout'), findsOneWidget);
      expect(find.text('Create custom workout'), findsNothing);
      final create = find.widgetWithText(FilledButton, 'Create workout');
      await tester.ensureVisible(create);
      expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Create stub'), findsOneWidget);
    });

    testWidgets('custom populated state: authored list, truthful actions',
        (tester) async {
      await pumpHub(tester, custom: true);
      expect(find.text('TEST Step Three Lift'), findsOneWidget);
      expect(find.text('No custom workouts yet'), findsNothing);
      expect(find.text('Create custom workout'), findsOneWidget);
      expect(find.textContaining('15 minutes'), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'View'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Edit'), findsOneWidget);
      expect(tester.getSize(find.widgetWithText(OutlinedButton, 'View')).height,
          greaterThanOrEqualTo(48));
    });

    testWidgets('saved hub actions preserve IDs and delete confirmation',
        (tester) async {
      for (final action in ['View', 'Edit']) {
        await pumpHub(tester, custom: true);
        final button = action == 'View'
            ? find.widgetWithText(OutlinedButton, action)
            : find.widgetWithText(TextButton, action);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text('${action == 'View' ? 'Detail' : 'Edit'} v2-custom'),
            findsOneWidget);
      }
      for (final action in ['View', 'Edit', 'Delete']) {
        await pumpHub(tester, custom: true);
        final menu = find.byType(PopupMenuButton<String>);
        await tester.ensureVisible(menu);
        await tester.pumpAndSettle();
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, action));
        await tester.pumpAndSettle();
        if (action != 'Delete') {
          expect(find.text('${action == 'View' ? 'Detail' : 'Edit'} v2-custom'),
              findsOneWidget);
          continue;
        }
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(await const CustomWorkoutStorage().loadAll(), hasLength(1));
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await tester.pumpAndSettle();
        expect(await const CustomWorkoutStorage().loadAll(), isEmpty);
        expect(find.byKey(const Key('v2_custom_empty')), findsOneWidget);
      }
    });

    testWidgets('explore tiles keep library and skill tree destinations',
        (tester) async {
      await pumpHub(tester);
      final count =
          ExerciseCatalog.all.where((exercise) => exercise.active).length;
      expect(find.text('Browse $count exercises'), findsOneWidget);
      expect(
          tester
              .getSize(find.ancestor(
                  of: find.text('Exercise Library'),
                  matching: find.byType(TextButton)))
              .height,
          greaterThanOrEqualTo(64));

      final libraryText = find.text('Exercise Library');
      await tester.ensureVisible(libraryText);
      await tester.pumpAndSettle();
      await tester.tap(libraryText);
      await tester.pumpAndSettle();
      expect(find.text('Library stub'), findsOneWidget);

      await pumpHub(tester, size: const Size(430, 900));
      await tester.ensureVisible(find.text('Exercise skill trees'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exercise skill trees'));
      await tester.pumpAndSettle();
      expect(find.text('Skill stub'), findsOneWidget);
    });

    testWidgets('artwork is decorative-only across the hub', (tester) async {
      await pumpHub(tester, activeProgram: true, custom: true);
      expect(find.byType(FitFlowV2FeatureArt), findsNothing);
      final photos = tester
          .widgetList<FitFlowProgramImage>(find.byType(FitFlowProgramImage));
      expect(photos, hasLength(2));
      expect(photos.every((photo) => photo.decorative), isTrue);
      final exercisePhoto = tester
          .widget<FitFlowExerciseImage>(find.byType(FitFlowExerciseImage));
      expect(exercisePhoto.exerciseId, 'squat_bodyweight');
      expect(exercisePhoto.decorative, isTrue);
      // Status is never image/color alone: active state is text-labelled.
      expect(find.text('4 of 12 sessions'), findsOneWidget);
    });

    testWidgets('navigation text stays readable in both themes',
        (tester) async {
      for (final dark in [false, true]) {
        await pumpHub(tester, dark: dark);
        final context = tester.element(programsCard());
        final colors = FitFlowTheme.of(context);
        final page = FitFlowVisualV2.of(context).page;
        expect(fitflowContrast(colors.textPrimary, page),
            greaterThanOrEqualTo(4.5));
        expect(fitflowContrast(colors.textSecondary, page),
            greaterThanOrEqualTo(4.5));
        expect(page, dark ? const Color(0xFF202526) : const Color(0xFFF3F4EE));
        final buttonTheme = Theme.of(context).filledButtonTheme.style!;
        final fill = buttonTheme.backgroundColor!.resolve({})!;
        final ink = buttonTheme.foregroundColor!.resolve({})!;
        expect(fill, const Color(0xFFD4E779));
        expect(fitflowContrast(ink, fill), greaterThanOrEqualTo(4.5));
        final outer = Theme.of(tester.element(find.byType(WorkoutsScreen)));
        expect(outer.scaffoldBackgroundColor,
            (dark ? AppTheme.dark : AppTheme.light).scaffoldBackgroundColor);
      }
    });

    testWidgets('native actions: tile/button semantics and 48dp targets',
        (tester) async {
      await pumpHub(tester, activeProgram: true, custom: true);
      expect(
          find.ancestor(
              of: find.text('Programs'), matching: find.byType(InkWell)),
          findsWidgets);
      expect(
          find.ancestor(
              of: find.text('Exercise skill trees'),
              matching: find.byType(InkWell)),
          findsWidgets);
      expect(
          tester
              .getSize(find.ancestor(
                  of: find.text('Exercise skill trees'),
                  matching: find.byType(TextButton)))
              .height,
          greaterThanOrEqualTo(48));
      final goHome = find.widgetWithText(TextButton, 'Go to Home');
      await tester.ensureVisible(goHome);
      expect(tester.getSize(goHome).height, greaterThanOrEqualTo(48));
      await tester.pumpAndSettle();
      await tester.tap(goHome);
      await tester.pumpAndSettle();
      expect(find.text('Home stub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion makes the feature entrance immediate',
        (tester) async {
      await pumpHub(tester, reduced: true);
      final builders = tester
          .widgetList<TweenAnimationBuilder<double>>(find.descendant(
              of: find.byType(WorkoutsScreen),
              matching: find.byType(TweenAnimationBuilder<double>)))
          .toList();
      expect(builders, isNotEmpty);
      for (final b in builders) {
        expect(b.duration, Duration.zero);
      }
      await pumpHub(tester, reduced: false);
      final animated = tester
          .widgetList<TweenAnimationBuilder<double>>(find.descendant(
              of: find.byType(WorkoutsScreen),
              matching: find.byType(TweenAnimationBuilder<double>)))
          .toList();
      for (final b in animated) {
        expect(b.duration, greaterThan(Duration.zero));
      }
    });

    testWidgets('program photo stays compact and yields to large text',
        (tester) async {
      await pumpHub(tester, size: const Size(390, 844));
      final normal =
          tester.widget<FitFlowProgramImage>(find.byType(FitFlowProgramImage));
      expect(normal.width, lessThanOrEqualTo(104));
      await pumpHub(tester, size: const Size(390, 844), scale: 2);
      final large =
          tester.widget<FitFlowProgramImage>(find.byType(FitFlowProgramImage));
      expect(large.width, lessThan(normal.width));
      expect(large.width / large.height, closeTo(4 / 3, .001));
      expect(find.text('Programs'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'tablet keeps ordered readable explore rows at both text scales',
        (tester) async {
      for (final scale in [1.0, 2.0]) {
        await pumpHub(tester, size: const Size(840, 1000), scale: scale);
        final library = tester.getCenter(find.text('Exercise Library')).dy;
        final skills = tester.getCenter(find.text('Exercise skill trees')).dy;
        expect(skills, greaterThan(library));
        expect(tester.getSize(programsCard()).width, lessThan(760));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('short landscape stays scrollable with reachable actions',
        (tester) async {
      await pumpHub(tester,
          size: const Size(900, 320), activeProgram: true, custom: true);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      final goHome = find.widgetWithText(TextButton, 'Go to Home');
      await tester.ensureVisible(goHome);
      expect(goHome, findsOneWidget);
      await tester.ensureVisible(find.text('Programs'));
      expect(tester.takeException(), isNull);
    });

    test('artwork repaints only on kind or color changes', () {
      const style = FitFlowV2ArtStyle(
        panel: Color(0xFF000000),
        panelEdge: Color(0xFF111111),
        ink: Color(0xFF222222),
        wash: Color(0xFF333333),
        accent: Color(0xFF444444),
      );
      const different = FitFlowV2ArtStyle(
        panel: Color(0xFF000000),
        panelEdge: Color(0xFF111111),
        ink: Color(0xFF999999),
        wash: Color(0xFF333333),
        accent: Color(0xFF444444),
      );
      for (final painter in <_RepaintProbe>[
        const FitFlowV2ProgramsPainter(style),
        const FitFlowV2CustomWorkoutPainter(style),
        const FitFlowV2ExerciseLibraryPainter(style),
        const FitFlowV2SkillTreePainter(style),
      ]) {
        expect(painter.shouldRepaint(painter), isFalse,
            reason: '${painter.runtimeType} unchanged');
      }
      const programs = FitFlowV2ProgramsPainter(style);
      expect(programs.shouldRepaint(const FitFlowV2ProgramsPainter(different)),
          isTrue);
      expect(programs.shouldRepaint(const FitFlowV2SkillTreePainter(style)),
          isTrue,
          reason: 'swapping compositions must repaint with the same palette');
    });

    const sizes = [
      Size(320, 700),
      Size(360, 640),
      Size(360, 800),
      Size(412, 915),
      Size(390, 844),
      Size(430, 900),
      Size(600, 900),
      Size(840, 1000),
      Size(1024, 768),
      Size(900, 320),
    ];
    for (final size in sizes) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
              'V2 Workouts $size dark=$dark scale=$scale with real states',
              (tester) async {
            await pumpHub(
              tester,
              size: size,
              dark: dark,
              scale: scale,
              activeProgram: true,
              custom: true,
            );
            expect(find.text('Your workouts'), findsOneWidget);
            expect(find.text('Programs'), findsOneWidget);
            expect(find.text('Custom workouts'), findsOneWidget);
            expect(find.byType(FitFlowProgramImage), findsNWidgets(2),
                reason: 'active program cover and compact collection entry');
            expect(find.text('Active program'), findsOneWidget);
            expect(find.text('TEST Step Three Lift'), findsOneWidget);
            expect(find.byIcon(Icons.fitness_center_outlined), findsWidgets);
            expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
            expect(programsCard(), findsOneWidget);
            expect(tester.takeException(), isNull,
                reason: '$size dark=$dark scale=$scale');
            await tester.ensureVisible(find.text('Programs'));
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}

typedef _RepaintProbe = CustomPainter;
