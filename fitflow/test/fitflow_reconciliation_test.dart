import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/widgets/fitflow_buttons.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/core/design/widgets/fitflow_navigation.dart';
import 'package:fitflow/core/design/widgets/fitflow_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child,
        {bool dark = false, bool reduced = false, double scale = 1}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale), disableAnimations: reduced),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void window(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const destinations = [
  FitFlowNavDestination(
      icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
  FitFlowNavDestination(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      label: 'Workouts'),
  FitFlowNavDestination(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      label: 'Progress'),
  FitFlowNavDestination(
      icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
];

void main() {
  testWidgets('shared actions retain native semantic tap and focus actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await tester.pumpWidget(host(
          Column(children: [
            FitFlowPrimaryButton(label: 'Start', onPressed: () => taps++),
            FitFlowSecondaryButton(label: 'Adjust', onPressed: () => taps++),
            FitFlowTertiaryButton(label: 'Details', onPressed: () => taps++),
            const FitFlowPrimaryButton(label: 'Unavailable', onPressed: null),
            FitFlowPrimaryButton(
                label: 'Save', loading: true, onPressed: () => taps++),
          ]),
          reduced: true));
      for (final label in ['Start', 'Adjust', 'Details']) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
        expect(data.hasAction(SemanticsAction.focus), isTrue, reason: label);
        expect(data.flagsCollection.isButton, isTrue);
        await tester.tap(find.text(label));
      }
      expect(taps, 3);
      for (final label in ['Unavailable', 'Save, loading']) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(label))
            .getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isFalse, reason: label);
      }
      await tester.tap(find.text('Save'));
      expect(taps, 3);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shared button stays keyboard activatable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
        host(FitFlowPrimaryButton(label: 'Start', onPressed: () => taps++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  for (final dark in [false, true]) {
    testWidgets('icon actions and status wrap at 320dp/2x, dark=$dark',
        (tester) async {
      window(tester, const Size(320, 640));
      await tester.pumpWidget(host(
          SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FitFlowPrimaryButton(
                      label: 'Begin your next workout',
                      icon: Icons.play_arrow,
                      onPressed: () {}),
                  FitFlowSecondaryButton(
                      label: 'Adjust workout preferences',
                      icon: Icons.tune,
                      onPressed: () {}),
                  const FitFlowStatusChip(
                      label: 'Workout completed successfully',
                      status: FitFlowStatus.success),
                ]),
          )),
          scale: 2,
          dark: dark));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byType(OutlinedButton)).height,
          greaterThanOrEqualTo(48));
    });
  }

  testWidgets(
      'reduced motion replaces indeterminate loops but preserves progress',
      (tester) async {
    await tester.pumpWidget(host(
        Column(children: [
          FitFlowPrimaryButton(label: 'Save', onPressed: () {}, loading: true),
          const FitFlowLoading(label: 'Loading sessions'),
          const FitFlowProgress(label: 'Preparing'),
          const FitFlowProgress(label: 'Session', value: .5),
        ]),
        reduced: true));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        .5);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Loading sessions'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('normal motion keeps indeterminate indicators', (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      FitFlowPrimaryButton(label: 'Save', onPressed: null, loading: true),
      FitFlowLoading(),
      FitFlowProgress(label: 'Preparing'),
    ])));
    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        isNull);
  });

  testWidgets('stat, progress and loading announce a single meaningful label',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host(
          const Column(children: [
            FitFlowStat(label: 'Sessions', value: '12'),
            FitFlowLoading(label: 'Loading sessions'),
            FitFlowProgress(label: 'Session', value: .5),
          ]),
          reduced: true));
      expect(find.bySemanticsLabel('Sessions 12'), findsOneWidget);
      expect(find.bySemanticsLabel('Loading sessions'), findsOneWidget);
      expect(find.bySemanticsLabel('Session, 50 percent'), findsOneWidget);
      expect(
          tester
              .getSemantics(find.byType(FitFlowProgress))
              .getSemanticsData()
              .value,
          '50%');
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('navigation uses available width, not the enclosing window',
      (tester) async {
    window(tester, const Size(1000, 700));
    await tester.pumpWidget(host(SizedBox(
        width: 500,
        child: FitFlowNavigationShell(
          body: const Text('Branch'),
          destinations: destinations,
          selectedIndex: 0,
          onSelected: (_) {},
        ))));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets(
      'expanded rail scrolls in short landscape without losing selection',
      (tester) async {
    window(tester, const Size(900, 220));
    var selected = 0;
    await tester.pumpWidget(host(
        StatefulBuilder(
          builder: (context, setState) => FitFlowNavigationShell(
              body: const Text('Branch'),
              destinations: destinations,
              selectedIndex: selected,
              onSelected: (i) => setState(() => selected = i)),
        ),
        scale: 2));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom bar selection respects reduced motion', (tester) async {
    window(tester, const Size(320, 640));
    await tester.pumpWidget(host(
        FitFlowNavigationShell(
          body: const Text('Branch'),
          destinations: destinations,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        reduced: true));
    expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .animationDuration,
        Duration.zero);
  });

  testWidgets('dialog content scrolls and preserves cancel and confirm results',
      (tester) async {
    window(tester, const Size(320, 480));
    bool? result;
    await tester.pumpWidget(host(
        Builder(
            builder: (context) => TextButton(
                  onPressed: () async {
                    result = await FitFlowConfirmDialog.show(context,
                        title: 'Discard changes?',
                        message: List.filled(
                                12, 'Your unsaved changes will be lost.')
                            .join(' '),
                        confirmLabel: 'Discard',
                        cancelLabel: 'Keep editing');
                  },
                  child: const Text('Open'),
                )),
        scale: 2,
        reduced: true));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final route = ModalRoute.of(tester.element(find.byType(AlertDialog)))!;
    expect(route.animation!.value, 1);
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    await tester.ensureVisible(find.text('Keep editing'));
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(result, false);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Discard'));
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet scrolls around keyboard and closes at large text',
      (tester) async {
    window(tester, const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(host(
        Builder(
            builder: (context) => TextButton(
                  onPressed: () => FitFlowSheet.show<void>(context,
                      title: 'Workout options',
                      child: Builder(
                        builder: (context) =>
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          const TextField(
                              decoration: InputDecoration(labelText: 'Name')),
                          const Text(
                              'Choose the options that suit your next workout.'),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Done')),
                        ]),
                      )),
                  child: const Text('Open'),
                )),
        scale: 2,
        reduced: true));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final route = ModalRoute.of(tester.element(find.byType(FitFlowSheet)))!;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Done')).bottom, lessThanOrEqualTo(400));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });
}
