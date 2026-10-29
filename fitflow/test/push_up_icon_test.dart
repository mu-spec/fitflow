import 'package:fitflow/app/config/app_theme.dart';
import 'package:fitflow/core/design/media/fitflow_exercise_image.dart';
import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:fitflow/core/design/media/push_up_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  testWidgets(
      'pushup_standard uses exact ID, retains semantics, renders still photo',
      (tester) async {
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

    expect(find.byType(FitFlowMediaImage), findsNWidgets(3));
    expect(find.bySemanticsLabel('Standard Push-Up demonstration'),
        findsOneWidget);
    expect(tester.getSize(find.byType(FitFlowMediaImage).first),
        const Size(56, 56));

    await tester.pumpWidget(host(const PushUpIcon(), reduced: true));
    await settleMedia(tester);
    expect(find.byType(FitFlowMediaImage), findsOneWidget);
    expect(tester.getSize(find.byType(FitFlowMediaImage)),
        const Size(72, 72));
    semantics.dispose();
  });

  testWidgets('offscreen icons in bounded sections render when visible',
      (tester) async {
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
    Finder image(String key) => find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(FitFlowMediaImage));
    expect(image('first'), findsOneWidget);
    scroll.jumpTo(1200);
    await settleMedia(tester);
    expect(image('last'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('builder list does not mount or animate the entire catalog',
      (tester) async {
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
    expect(find.byType(FitFlowMediaImage).evaluate().length,
        lessThanOrEqualTo(7));
    scroll.jumpTo(19000);
    await settleMedia(tester);
    expect(built, contains(190));
    expect(built.length, lessThan(30));
    expect(find.byType(FitFlowMediaImage).evaluate().length,
        lessThanOrEqualTo(7));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
