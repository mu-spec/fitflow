import 'dart:async';
import 'dart:ui' as ui;

import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_contrast.dart';
import 'package:fitflow/core/design/media/fitflow_program_image.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:fitflow/core/design/media/program_media_registry.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_program_cover.dart';
import 'package:fitflow/features/onboarding/data/fitness_goal.dart';
import 'package:fitflow/features/programs/application/adaptive_programs_controller.dart';
import 'package:fitflow/features/programs/data/adaptive_programs_storage.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_catalog.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_definition.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_progress.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_recommendation_policy.dart';
import 'package:fitflow/features/programs/domain/adaptive_program_status.dart';
import 'package:fitflow/features/programs/domain/adaptive_programs_state.dart';
import 'package:fitflow/features/programs/presentation/program_detail_screen.dart';
import 'package:fitflow/features/programs/presentation/program_session_preview_screen.dart';
import 'package:fitflow/features/programs/presentation/programs_overview_screen.dart';
import 'package:fitflow/features/programs/presentation/widgets/program_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/adaptive_program_test_helpers.dart';

/// Step 4 presentation contract. The unchanged program UI suites remain the
/// regression gate for storage, confirmations, generation and destinations.
void main() {
  final t0 = DateTime.utc(2026, 10, 13);
  final balanced = AdaptiveProgramCatalog.balancedFoundations;
  final strength = AdaptiveProgramCatalog.strengthFoundations;

  AdaptiveProgramsState stateFor(
    AdaptiveProgramDefinition definition, {
    bool active = true,
    List<String> done = const [],
  }) =>
      AdaptiveProgramsState(
        activeProgramId: active ? definition.id : null,
        progressByProgram: {
          definition.id: AdaptiveProgramProgress(
            programId: definition.id,
            startedAt: t0,
            updatedAt: t0,
            completions: [
              for (var i = 0; i < done.length; i++)
                AdaptiveProgramSessionCompletion(
                  plannedSessionId: done[i],
                  playerSessionId: 'visual-v2-$i',
                  completedAt: t0,
                ),
            ],
          ),
        },
      );

  Future<GoRouter> pumpPrograms(
    WidgetTester tester, {
    String location = AppRoutes.programs,
    AdaptiveProgramsState? state,
    FitnessGoal goal = FitnessGoal.generalFitness,
    bool includeProfile = true,
    bool dark = false,
    bool reduced = true,
    double scale = 1,
    Size size = const Size(390, 844),
    List<Override> extra = const [],
    bool settle = true,
    bool isolateOverview = false,
    double? pageWidth,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({
      if (state != null)
        AdaptiveProgramsStorage.key: AdaptiveProgramsStorage.encode(state),
    });
    // Fault-injection presentation tests isolate the scoped screen from the
    // unchanged Workouts parent; normal navigation tests use the full router.
    final router = isolateOverview
        ? GoRouter(
            initialLocation: AppRoutes.programs,
            routes: [
              GoRoute(
                path: AppRoutes.programs,
                builder: (context, state) => const ProgramsOverviewScreen(),
              ),
            ],
          )
        : programTestRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...programOverrides(
            profile: programTestProfile(goal: goal),
            includeProfile: includeProfile,
          ),
          ...extra,
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: MaterialApp.router(
            theme: dark ? AppTheme.dark : AppTheme.light,
            routerConfig: router,
            builder: pageWidth == null
                ? null
                : (context, child) =>
                    Center(child: SizedBox(width: pageWidth, child: child)),
          ),
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
    return router;
  }

  Finder cardFor(String id) => find.byKey(ValueKey('v2_program_card_$id'));
  Finder rowFor(String id) => find.byKey(ValueKey('v2_program_session_$id'));
  Finder coverIn(Finder parent) =>
      find.descendant(of: parent, matching: find.byType(FitFlowProgramImage));

  group('Visual V2 program covers', () {
    test('five canonical IDs and real structures are unchanged', () {
      expect(AdaptiveProgramCatalog.allIds, [
        'balanced_foundations',
        'strength_foundations',
        'endurance_builder',
        'mobility_movement',
        'stay_active_starter',
      ]);
      expect(AdaptiveProgramCatalog.validate(), isEmpty);
      expect(
        AdaptiveProgramCatalog.all
            .map((d) => [d.weekCount, d.sessionsPerWeek, d.totalSessionCount]),
        [
          [4, 3, 12],
          [6, 3, 18],
          [4, 4, 16],
          [4, 3, 12],
          [4, 3, 12],
        ],
      );
      expect(
          AdaptiveProgramCatalog.allIds.map(FitFlowV2ProgramCover.motifFor), [
        FitFlowV2ProgramMotif.balancedPlatforms,
        FitFlowV2ProgramMotif.structuralFrame,
        FitFlowV2ProgramMotif.continuousRoute,
        FitFlowV2ProgramMotif.crossingArcs,
        FitFlowV2ProgramMotif.gentleSteps,
      ]);
      expect(FitFlowV2ProgramCover.motifFor('Balanced Foundations'),
          FitFlowV2ProgramMotif.neutral);
      expect(FitFlowV2ProgramCover.motifFor('unknown_id'),
          FitFlowV2ProgramMotif.neutral);
    });

    test('painter repaints only for motif or any palette-input change', () {
      for (final motif in FitFlowV2ProgramMotif.values) {
        final painter =
            FitFlowV2ProgramCoverPainter(motif: motif, style: _style);
        expect(
          painter.shouldRepaint(
              FitFlowV2ProgramCoverPainter(motif: motif, style: _style)),
          isFalse,
        );
        final other = motif == FitFlowV2ProgramMotif.neutral
            ? FitFlowV2ProgramMotif.crossingArcs
            : FitFlowV2ProgramMotif.neutral;
        expect(
          painter.shouldRepaint(
              FitFlowV2ProgramCoverPainter(motif: other, style: _style)),
          isTrue,
        );
        for (var i = 0; i < 5; i++) {
          final changed = FitFlowV2ArtStyle(
            panel: i == 0 ? Colors.black : _style.panel,
            panelEdge: i == 1 ? Colors.black : _style.panelEdge,
            ink: i == 2 ? Colors.black : _style.ink,
            wash: i == 3 ? Colors.black : _style.wash,
            accent: i == 4 ? Colors.black : _style.accent,
          );
          expect(
            painter.shouldRepaint(
                FitFlowV2ProgramCoverPainter(motif: motif, style: changed)),
            isTrue,
            reason: 'palette input $i',
          );
        }
      }
    });

    testWidgets('five distinct rasterizations are static and deterministic',
        (tester) async {
      await tester.runAsync(() async {
        final hashes = <int>{};
        for (final id in AdaptiveProgramCatalog.allIds) {
          final motif = FitFlowV2ProgramCover.motifFor(id);
          final first = await _rasterize(motif);
          final second = await _rasterize(motif);
          expect(second, orderedEquals(first), reason: id);
          var hash = 2166136261;
          for (final byte in first) {
            hash = ((hash ^ byte) * 16777619) & 0xffffffff;
          }
          hashes.add(hash);
        }
        expect(hashes, hasLength(5));
      });
    });

    testWidgets('approved covers map exact IDs into compact 4:3 rows',
        (tester) async {
      await pumpPrograms(tester, size: const Size(840, 1000));
      for (final definition in AdaptiveProgramCatalog.all) {
        await programScrollTo(tester, cardFor(definition.id));
        final cover = coverIn(cardFor(definition.id));
        expect(cover, findsOneWidget);
        final image = tester.widget<FitFlowProgramImage>(cover);
        expect(image.programId, definition.id);
        expect(image.decorative, isTrue);
        expect(image.width / image.height, closeTo(4 / 3, .001));
        expect(image.width, lessThanOrEqualTo(112));
        final media = tester.widget<FitFlowMediaImage>(find.descendant(
            of: cover, matching: find.byType(FitFlowMediaImage)));
        expect(media.asset, ProgramMediaRegistry.lookup(definition.id)!.cover);
        expect(find.descendant(of: cover, matching: find.byType(Text)),
            findsNothing);
      }
      expect(find.byType(FitFlowV2ProgramCover), findsNothing);
    });
  });

  group('Visual V2 Programs overview', () {
    testWidgets(
        'compact header, photographic rows and canonical facts appear once',
        (tester) async {
      await pumpPrograms(tester);
      expect(find.text('FITFLOW'), findsNothing);
      expect(find.text('Adaptive programs'), findsNothing);
      expect(find.text('Programs'), findsOneWidget);
      final scaffoldFinder = find.descendant(
          of: find.byType(ProgramsOverviewScreen),
          matching: find.byType(Scaffold));
      // The scoped Slate + Citrus theme sits between the screen widget and
      // its content, so the V2 roles must be read inside the content subtree.
      final context = tester.element(scaffoldFinder);
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.backgroundColor, FitFlowVisualV2.of(context).page);
      for (final definition in AdaptiveProgramCatalog.all) {
        await programScrollTo(tester, cardFor(definition.id));
        expect(find.text(definition.name), findsOneWidget);
        expect(
            find.descendant(
                of: cardFor(definition.id),
                matching: find.text(definition.focus)),
            findsOneWidget);
        expect(
            find.descendant(
                of: cardFor(definition.id),
                matching: find.byType(ProgramStructureLine)),
            findsOneWidget);
        expect(coverIn(cardFor(definition.id)), findsOneWidget);
      }
      expect(find.text('Active program'), findsNothing);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('Balanced schedule wraps fully below focus without clipping',
        (tester) async {
      for (final width in [320.0, 360.0]) {
        for (final scale in [1.0, 2.0]) {
          for (final dark in [false, true]) {
            await pumpPrograms(tester,
                size: Size(width, 700), scale: scale, dark: dark);
            final row = cardFor(balanced.id);
            final schedule = find.descendant(
                of: row, matching: find.byType(ProgramStructureLine));
            final copy =
                find.descendant(of: schedule, matching: find.byType(Text));
            final paragraph = tester.renderObject<RenderParagraph>(copy);
            expect(tester.widget<Text>(copy).data,
                '4 weeks \u2022 3 sessions/week');
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(
                tester.getTopLeft(schedule).dy,
                greaterThan(
                    tester.getBottomLeft(find.text(balanced.focus)).dy));
            expect(tester.getBottomRight(schedule).dy,
                lessThan(tester.getBottomRight(row).dy));
            expect(tester.getBottomRight(schedule).dx,
                lessThanOrEqualTo(tester.getBottomRight(row).dx));
            await programScrollTo(tester, schedule);
            expect(
                tester.getTopLeft(schedule).dy,
                greaterThanOrEqualTo(
                    tester.getBottomLeft(find.byType(AppBar)).dy));
            expect(tester.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('active program leads once and Continue uses the real next ID',
        (tester) async {
      final state = stateFor(balanced,
          done: [balanced.sessions[0].id, balanced.sessions[2].id]);
      await pumpPrograms(tester, state: state, size: const Size(840, 1000));
      final active = cardFor(balanced.id);
      expect(find.text('Active program'), findsOneWidget);
      expect(find.text('2 of 12 sessions'), findsOneWidget);
      expect(find.text('Week 1 • Next: Session 2'), findsOneWidget);
      expect(tester.widget<FitFlowProgramImage>(coverIn(active)).programId,
          balanced.id);
      for (final definition in AdaptiveProgramCatalog.all) {
        await programScrollTo(tester, cardFor(definition.id));
        expect(cardFor(definition.id), findsOneWidget);
        expect(find.text(definition.name), findsOneWidget);
      }
      await programScrollToTop(tester);
      final nextCard = cardFor(strength.id);
      expect(tester.getTopLeft(active).dy,
          lessThan(tester.getTopLeft(nextCard).dy));
      final cta = find.widgetWithText(FilledButton, 'Continue');
      await tester.ensureVisible(cta);
      expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);
      expect(
          GoRouterState.of(
                  tester.element(find.byType(ProgramSessionPreviewScreen)))
              .uri
              .path,
          AppRoutes.programSessionPreview(
              balanced.id, balanced.sessions[1].id));
      expect(find.text('Week 1 • Session 2'), findsOneWidget);
    });

    testWidgets('recommendation is only the existing policy match',
        (tester) async {
      for (final goal in FitnessGoal.values) {
        await pumpPrograms(tester, goal: goal);
        final definition =
            AdaptiveProgramRecommendationPolicy.recommendedFor(goal);
        await programScrollTo(tester, cardFor(definition.id));
        expect(find.text('Matches your selected goal'), findsOneWidget);
        expect(
            find.descendant(
                of: cardFor(definition.id),
                matching: find.text('Matches your selected goal')),
            findsOneWidget);
      }
      await pumpPrograms(tester, includeProfile: false);
      for (final definition in AdaptiveProgramCatalog.all) {
        await programScrollTo(tester, cardFor(definition.id));
        expect(find.text('Matches your selected goal'), findsNothing);
      }
    });

    testWidgets('completed program is restrained, factual and opens detail',
        (tester) async {
      final definition = AdaptiveProgramCatalog.stayActiveStarter;
      await pumpPrograms(tester,
          state: stateFor(definition,
              done: definition.sessions.map((s) => s.id).toList()));
      final card = cardFor(definition.id);
      expect(find.text(definition.name), findsOneWidget);
      expect(find.text('Program complete'), findsOneWidget);
      expect(find.text('12 of 12 sessions'), findsOneWidget);
      expect(tester.widget<FitFlowProgramImage>(coverIn(card)).programId,
          definition.id);
      expect(
          find.descendant(
              of: card, matching: find.byIcon(Icons.check_circle_outline)),
          findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      await tester.tap(find.text(definition.name));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
      expect(find.text('Program complete'), findsOneWidget);
      expect(find.text('Restart program'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('readable rows stay ordered in wide and constrained panes',
        (tester) async {
      for (final width in [840.0, 650.0]) {
        await pumpPrograms(tester,
            size: const Size(840, 1000), pageWidth: width);
        final first = tester.getTopLeft(cardFor(balanced.id));
        final second = tester.getTopLeft(cardFor(strength.id));
        expect(first.dx, second.dx);
        expect(first.dy, lessThan(second.dy));
        expect(tester.getSize(cardFor(balanced.id)).width, greaterThan(500));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('loading/error/retry preserve the existing state surfaces',
        (tester) async {
      final delayed = _DelayedStorage();
      await pumpPrograms(tester,
          settle: false,
          isolateOverview: true,
          extra: [adaptiveProgramsStorageProvider.overrideWithValue(delayed)]);
      expect(find.text('Loading program progress…'), findsOneWidget);
      expect(find.byType(FitFlowProgramImage), findsNothing);
      delayed.result.complete(AdaptiveProgramsState.empty);
      await tester.pumpAndSettle();
      expect(find.text(balanced.name), findsOneWidget);

      final failing = _FailOnceStorage();
      await pumpPrograms(tester,
          isolateOverview: true,
          extra: [adaptiveProgramsStorageProvider.overrideWithValue(failing)]);
      expect(find.byType(ProgramProgressState), findsOneWidget);
      expect(find.byType(FitFlowProgramImage), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text(balanced.name), findsOneWidget);
    });
  });

  group('Visual V2 Program detail and timeline', () {
    testWidgets('each original cover, title, description and facts stay real',
        (tester) async {
      for (final definition in AdaptiveProgramCatalog.all) {
        await pumpPrograms(tester,
            location: AppRoutes.programDetail(definition.id));
        final art = find.byType(FitFlowProgramImage);
        expect(art, findsOneWidget);
        expect(
            tester.widget<FitFlowProgramImage>(art).programId, definition.id);
        expect(find.text(definition.name), findsOneWidget);
        expect(find.text(definition.description), findsNothing);
        final imageSize = tester.getSize(art);
        expect(imageSize.width / imageSize.height, closeTo(4 / 3, .001));
        expect(find.text(definition.focus), findsOneWidget);
        expect(find.textContaining('${definition.weekCount} weeks'),
            findsOneWidget);
        expect(
            find.textContaining('${definition.sessionsPerWeek} sessions/week'),
            findsOneWidget);
        expect(find.textContaining('${definition.totalSessionCount} workouts'),
            findsOneWidget);
        await programScrollTo(tester, find.text('Start program'));
        expect(
            tester
                .getSize(find.widgetWithText(FilledButton, 'Start program'))
                .height,
            greaterThanOrEqualTo(48));
        await programScrollTo(tester, find.text('About this program'));
        await tester.tap(find.text('About this program'));
        await tester.pumpAndSettle();
        expect(find.text(definition.description), findsOneWidget);
        final scaffoldFinder = find.descendant(
            of: find.byType(ProgramDetailScreen),
            matching: find.byType(Scaffold));
        // Scoped theme: read the V2 roles inside the themed content subtree.
        final scaffold = tester.widget<Scaffold>(scaffoldFinder);
        expect(scaffold.backgroundColor,
            FitFlowVisualV2.of(tester.element(scaffoldFinder)).page);
      }
    });

    testWidgets(
        'ordered timeline keeps completed/next/planned and exact routing',
        (tester) async {
      await pumpPrograms(tester,
          location: AppRoutes.programDetail(balanced.id),
          state: stateFor(balanced,
              done: [balanced.sessions[0].id, balanced.sessions[2].id]));
      final expected = [
        AdaptiveProgramSessionStatus.completed,
        AdaptiveProgramSessionStatus.next,
        AdaptiveProgramSessionStatus.completed,
        AdaptiveProgramSessionStatus.planned,
      ];
      for (var i = 0; i < expected.length; i++) {
        final session = balanced.sessions[i];
        final row = rowFor(session.id);
        await programScrollTo(tester, row);
        final widget = tester.widget<ProgramSessionRow>(row);
        expect(widget.session, session);
        expect(widget.status, expected[i]);
        expect(widget.isFirst, session.session == 1);
        expect(widget.isLast, session.session == balanced.sessionsPerWeek);
        expect(
            find.descendant(
                of: row,
                matching: find.text(
                    '${session.focus} • Goal: ${session.generationGoal.label}')),
            findsOneWidget);
        expect(
            find.descendant(
                of: row, matching: find.byType(ProgramSessionStatusChip)),
            findsOneWidget);
        final action = find.descendant(of: row, matching: find.byType(TextButton));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      }
      final session = balanced.sessions[3];
      final action = find.descendant(of: rowFor(session.id), matching: find.byType(TextButton));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
          GoRouterState.of(
                  tester.element(find.byType(ProgramSessionPreviewScreen)))
              .uri
              .path,
          AppRoutes.programSessionPreview(balanced.id, session.id));
      expect(find.byType(ProgramSessionPreviewScreen), findsOneWidget);
      expect(find.text(session.title), findsOneWidget);
      expect(find.text('Session goal: ${session.generationGoal.label}'), findsNothing);
      await tester.tap(find.byKey(const Key('program_session_about')));
      await tester.pumpAndSettle();
      expect(find.text('Session goal: ${session.generationGoal.label}'),
          findsOneWidget);
    });

    testWidgets('rendering/navigating never writes progress or adds metrics',
        (tester) async {
      final state = stateFor(strength,
          done: [strength.sessions[0].id, strength.sessions[2].id]);
      await pumpPrograms(tester,
          state: state,
          goal: FitnessGoal.buildMuscle,
          size: const Size(840, 1000));
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString(AdaptiveProgramsStorage.key);
      for (final definition in AdaptiveProgramCatalog.all) {
        await programScrollTo(tester, cardFor(definition.id));
        _expectNoInventedMetrics();
      }
      await programScrollTo(tester, cardFor(strength.id), step: -180);
      await tester.tap(find.text(strength.name));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramDetailScreen), findsOneWidget);
      expect(find.text('2 of 18 sessions'), findsOneWidget);
      await programScrollTo(tester, rowFor(strength.sessions.last.id));
      _expectNoInventedMetrics();
      expect(prefs.getString(AdaptiveProgramsStorage.key), before);
      expect(before, AdaptiveProgramsStorage.encode(state));
    });
  });

  group('Visual V2 Programs accessibility, themes and performance', () {
    testWidgets('native keyboard activation, headings and button semantics',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpPrograms(tester, size: const Size(840, 1000));
        final heading = tester.getSemantics(find.text('Programs'));
        expect(heading.flagsCollection.isHeader, isTrue);
        final link = find.byKey(ValueKey('v2_program_link_${balanced.id}'));
        expect(tester.getSize(link).height, greaterThanOrEqualTo(48));
        final node = tester.getSemantics(link);
        expect(node.flagsCollection.isButton, isTrue);
        expect(
            node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
        var focused = false;
        for (var i = 0; i < 10; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          focused = tester
                  .getSemantics(link)
                  .flagsCollection
                  .isFocused
                  .toBoolOrNull() ==
              true;
          if (focused) break;
        }
        expect(focused, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(ProgramDetailScreen), findsOneWidget);
        expect(
            tester
                .getSemantics(find.text(balanced.name))
                .flagsCollection
                .isHeader,
            isTrue);
        await programScrollTo(tester, find.text('Week 1'));
        expect(
            tester.getSemantics(find.text('Week 1')).flagsCollection.isHeader,
            isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
        'program explanation disclosure announces expanded and collapsed state',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpPrograms(tester,
            location: AppRoutes.programDetail(balanced.id));
        final title = find.text('About this program');
        await programScrollTo(tester, title);
        expect(find.text(balanced.description), findsNothing);
        expect(tester.getSemantics(title).getSemanticsData().hint,
            contains('Collapsed'));
        await tester.tap(title);
        await tester.pumpAndSettle();
        expect(find.text(balanced.description), findsOneWidget);
        expect(tester.getSemantics(title).getSemanticsData().hint,
            contains('Expanded'));
        await tester.tap(title);
        await tester.pumpAndSettle();
        expect(find.text(balanced.description), findsNothing);
        await programScrollTo(tester, find.text('Start program'), step: -150);
        expect(
            tester
                .widget<FilledButton>(
                    find.widgetWithText(FilledButton, 'Start program'))
                .onPressed,
            isNotNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('light/dark text and action roles have readable contrast',
        (tester) async {
      for (final dark in [false, true]) {
        await pumpPrograms(tester, dark: dark, state: stateFor(balanced));
        final context = tester.element(cardFor(balanced.id));
        final v = FitFlowVisualV2.of(context);
        final t = FitFlowTheme.of(context);
        for (final pair in [
          [v.onAction, v.action],
          [t.textPrimary, v.page],
          [t.textSecondary, v.page],
          [t.brand, v.page],
        ]) {
          expect(fitflowContrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5));
        }
      }
    });

    testWidgets(
        'row images stay 4:3 at large text without continuous animation',
        (tester) async {
      await pumpPrograms(tester, state: stateFor(balanced), scale: 1);
      await programScrollTo(tester, cardFor(balanced.id));
      final normal = tester
          .widget<FitFlowProgramImage>(coverIn(cardFor(balanced.id)))
          .height;
      for (final reduced in [false, true]) {
        await pumpPrograms(tester,
            state: stateFor(balanced), scale: 2, reduced: reduced);
        await programScrollTo(tester, cardFor(balanced.id));
        final art = coverIn(cardFor(balanced.id));
        expect(
            tester.widget<FitFlowProgramImage>(art).height, lessThan(normal));
        final image = tester.widget<FitFlowProgramImage>(art);
        expect(image.width / image.height, closeTo(4 / 3, .001));
        expect(MediaQuery.textScalerOf(tester.element(art)).scale(16), 32);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      }
    });
  });

  const sizes = [
    Size(320, 700),
    Size(390, 844),
    Size(600, 900),
    Size(840, 1000),
    Size(900, 320),
  ];
  for (final size in sizes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Programs/Detail $size dark=$dark text=$scale fully scroll',
            (tester) async {
          final state = stateFor(strength,
              done: [strength.sessions[0].id, strength.sessions[2].id]);
          await pumpPrograms(tester,
              state: state,
              goal: FitnessGoal.buildMuscle,
              size: size,
              dark: dark,
              scale: scale);
          // The real active card is promoted first, not duplicated later.
          for (final definition in [
            strength,
            ...AdaptiveProgramCatalog.all.where((d) => d.id != strength.id),
          ]) {
            await programScrollTo(tester, cardFor(definition.id));
            expect(find.text(definition.name), findsOneWidget);
            expect(tester.takeException(), isNull,
                reason: 'overview ${definition.id}: $size/$dark/$scale');
          }
          await pumpPrograms(tester,
              location: AppRoutes.programDetail(strength.id),
              state: state,
              goal: FitnessGoal.buildMuscle,
              size: size,
              dark: dark,
              scale: scale);
          await programScrollTo(tester, find.text(strength.name));
          expect(find.text(strength.name), findsOneWidget);
          expect(
              MediaQuery.textScalerOf(
                      tester.element(find.byType(ProgramDetailScreen)))
                  .scale(16),
              16 * scale);
          expect(tester.takeException(), isNull);
          for (final label in ['Continue', 'Restart program']) {
            await programScrollTo(tester, find.text(label));
            final button = label == 'Continue'
                ? find.widgetWithText(FilledButton, label)
                : find.widgetWithText(OutlinedButton, label);
            await tester.ensureVisible(button);
            expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull);
          }
          for (final week in strength.weeks) {
            await programScrollTo(tester, rowFor(week.sessions.last.id),
                step: 200, maxSteps: 100);
            final row =
                tester.widget<ProgramSessionRow>(rowFor(week.sessions.last.id));
            expect(row.session, week.sessions.last);
            expect(row.isLast, isTrue);
            final action =
                find.descendant(of: rowFor(week.sessions.last.id), matching: find.byType(TextButton));
            await tester.ensureVisible(action);
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
            expect(tester.takeException(), isNull,
                reason: 'detail week ${week.number}: $size/$dark/$scale');
          }
        });
      }
    }
  }
}

const _style = FitFlowV2ArtStyle(
  panel: Color(0xFFEAF5EF),
  panelEdge: Color(0xFFCCDCD4),
  ink: Color(0xFF0E6B5A),
  wash: Color(0xFF80BAA9),
  accent: Color(0xFF8A4E16),
);

Future<Uint8List> _rasterize(FitFlowV2ProgramMotif motif) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  FitFlowV2ProgramCoverPainter(motif: motif, style: _style)
      .paint(canvas, const Size(300, 160));
  final picture = recorder.endRecording();
  final image = await picture.toImage(300, 160);
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return Uint8List.fromList(bytes.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void _expectNoInventedMetrics() {
  for (final banned in [
    RegExp(r'\d\s*%'),
    RegExp(r'calories|kcal|difficulty score|muscle percentage|prediction',
        caseSensitive: false),
    RegExp(r'\bXP\b|trophy|achievement|transformation estimate',
        caseSensitive: false),
  ]) {
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && banned.hasMatch(widget.data ?? '')),
        findsNothing);
  }
}

class _DelayedStorage extends AdaptiveProgramsStorage {
  final result = Completer<AdaptiveProgramsState>();
  @override
  Future<AdaptiveProgramsState> load() => result.future;
}

class _FailOnceStorage extends AdaptiveProgramsStorage {
  var attempts = 0;
  @override
  Future<AdaptiveProgramsState> load() async {
    if (attempts++ == 0) throw StateError('test load failure');
    return AdaptiveProgramsState.empty;
  }
}
