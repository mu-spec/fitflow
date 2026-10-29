import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/features/settings/presentation/widgets/profile_settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Offline credit and license text bundled with the exercise illustrations.
class ExerciseArtworkCreditsScreen extends StatelessWidget {
  const ExerciseArtworkCreditsScreen({super.key});

  static const title = 'Exercise artwork credits';
  static const illustrationNoticeAsset =
      'assets/animations/illustrated_athletes/NOTICE.md';
  static const realPeopleNoticeAsset =
      'assets/animations/real_people/NOTICE.md';

  @override
  Widget build(BuildContext context) => ProfileSettingsTheme(
        child: Builder(builder: (context) {
          final visual = FitFlowVisualV2.of(context);
          return Scaffold(
            backgroundColor: visual.page,
            appBar: AppBar(title: const Text(title)),
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FitFlowLayout.maxReadableWidth,
                  ),
                  child: FutureBuilder<List<String>>(
                    future: Future.wait<String>(<Future<String>>[
                      rootBundle.loadString(illustrationNoticeAsset),
                      rootBundle.loadString(realPeopleNoticeAsset),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(
                          padding:
                              EdgeInsets.all(FitFlowSpace.screenHorizontal),
                          child: Text('Artwork credits could not be loaded.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(FitFlowSpace.screenHorizontal),
                        child: SelectableText(
                          snapshot.data!.join('\n\n---\n\n'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      );
}
