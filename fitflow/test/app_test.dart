import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitflow/app/app.dart';
import 'package:fitflow/core/constants/app_constants.dart';

void main() {
  testWidgets('FitFlow opens on the placeholder splash screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FitFlowApp(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.tagline), findsOneWidget);
  });
}
