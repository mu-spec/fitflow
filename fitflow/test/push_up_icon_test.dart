import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/push_up_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

Widget host(Widget body, {bool reduced = false}) => MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!),
    home: Scaffold(body: body));
Future<void> settleMedia(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> load(WidgetTester tester) async {
  await tester
      .runAsync(() => AssetLottie('assets/animations/pushup.json').load());
}

void main() {
  testWidgets(
      'shared hero and thumbnail use exact push-up ID and retain semantics',
      (tester) async {
    await load(tester);
    await tester.runAsync(
        () => AssetLottie('assets/animations/knee_pushup.json').load());
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(host(const Column(children: [
      FitFlowExerciseImage.thumbnail(
          exerciseId: 'pushup_standard', width: 56, height: 56),
      FitFlowExerciseImage.hero(
          exerciseId: 'pushup_standard',
          width: 240,
          height: 180,
          decorative: false,
          semanticLabel: 'Standard Push-Up demonstration'),
      FitFlowExerciseImage.thumbnail(exerciseId: 'pushup_knee'),
    ])));
    await settleMedia(tester);
    expect(find.byType(PushUpIcon), findsNWidgets(2));
    expect(find.byType(Lottie), findsNWidgets(3));
    expect(find.bySemanticsLabel('Standard Push-Up demonstration'),
        findsOneWidget);
    expect(tester.getSize(find.byType(PushUpIcon).first), const Size(56, 56));
    for (final animation in tester.widgetList<Lottie>(find.byType(Lottie))) {
      expect(animation.repeat, isTrue);
      expect(animation.animate, isTrue);
      expect(animation.fit, BoxFit.contain);
    }
    await tester.pumpWidget(host(const PushUpIcon(), reduced: true));
    await settleMedia(tester);
    expect(find.byType(Lottie), findsNothing);
    expect(tester.getSize(find.byType(PushUpIcon)), const Size(72, 72));
    semantics.dispose();
  });

  testWidgets('offscreen icons in bounded sections load only when visible',
      (tester) async {
    await load(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(host(SingleChildScrollView(
        controller: scroll,
        child: const Column(children: [
          PushUpIcon(key: Key('first')),
          SizedBox(height: 1200),
          PushUpIcon(key: Key('last')),
          SizedBox(height: 700),
        ]))));
    await settleMedia(tester);
    Finder animation(String key) => find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(Lottie));
    expect(animation('first'), findsOneWidget);
    expect(animation('last'), findsNothing);
    scroll.jumpTo(1200);
    await settleMedia(tester);
    expect(animation('first'), findsNothing);
    expect(animation('last'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('builder list does not mount or animate the entire catalog',
      (tester) async {
    await load(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final built = <int>{};
    await tester.pumpWidget(host(ListView.builder(
        controller: scroll,
        itemCount: 200,
        itemExtent: 100,
        itemBuilder: (context, index) {
          built.add(index);
          return const Center(child: PushUpIcon(width: 64, height: 64));
        })));
    await settleMedia(tester);
    expect(built.length, lessThan(15));
    expect(find.byType(Lottie).evaluate().length, lessThanOrEqualTo(7));
    scroll.jumpTo(19000);
    await settleMedia(tester);
    expect(built, contains(190));
    expect(built.length, lessThan(30));
    expect(find.byType(Lottie).evaluate().length, lessThanOrEqualTo(7));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
