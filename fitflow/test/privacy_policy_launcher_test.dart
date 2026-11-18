import 'package:fitflow/features/settings/data/privacy_policy_links.dart';
import 'package:fitflow/features/settings/presentation/privacy_policy_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_url_launcher_channel.dart';

const _officialUrl = 'https://mu-spec.github.io/home-workout-privacy/';

Widget _harness() => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => openPrivacyPolicyInBrowser(context),
              child: const Text('open policy'),
            ),
          ),
        ),
      ),
    );

void main() {
  test('the app links to the official hosted policy', () {
    expect(PrivacyPolicyLinks.privacyPolicyUrl, _officialUrl);
  });

  testWidgets('opens the official URL outside the app (browser, no WebView)',
      (tester) async {
    final launcher = FakeUrlLauncherChannel()..install();
    addTearDown(launcher.uninstall);

    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open policy'));
    await tester.pumpAndSettle();

    expect(launcher.calls, hasLength(1));
    expect(launcher.calls.single.method, 'launch');
    expect(launcher.lastLaunchedUrl, _officialUrl);
    // url_launcher only sets useWebView for in-app modes; false means the
    // device's own browser handles the link.
    expect(launcher.lastUsedWebView, isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tells the user when no browser can open the link',
      (tester) async {
    final launcher = FakeUrlLauncherChannel(result: false)..install();
    addTearDown(launcher.uninstall);

    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open policy'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining(_officialUrl), findsOneWidget);
  });

  testWidgets('a failing platform call still shows the message, never crashes',
      (tester) async {
    final launcher = FakeUrlLauncherChannel(throws: true)..install();
    addTearDown(launcher.uninstall);

    await tester.pumpWidget(_harness());
    await tester.tap(find.text('open policy'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining(_officialUrl), findsOneWidget);
  });
}
