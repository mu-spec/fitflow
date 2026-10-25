import 'package:fitflow/features/settings/presentation/widgets/profile_settings_theme.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:flutter/material.dart';

/// In-app explanation of FitFlow V1 data handling.
///
/// This is not a published web policy and does not invent a developer
/// contact. External placeholders belong only in docs/privacy-policy.html.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String title = 'Privacy Policy';

  static const List<({String heading, String body})> sections = [
    (
      heading: 'No account and no FitFlow service',
      body:
          'FitFlow does not create an account and does not operate a FitFlow backend, cloud sync service, or advertising service. The app works on this device without a login.',
    ),
    (
      heading: 'Information stored on this device',
      body:
          'FitFlow stores your fitness profile, movement levels and progress, workout history, custom workouts, adaptive program progress, reminder choices, and appearance preference locally on this device. Those values are not sent to a FitFlow server.',
    ),
    (
      heading: 'Backups you create',
      body:
          'A backup file is created only when you choose Backup & restore. The file is saved wherever you select with the system file picker. FitFlow does not upload that file. Android automatic backup and device-to-device transfer of FitFlow app data are turned off, so FitFlow data is not silently copied by the operating system. A file you already saved stays where you put it until you delete it.',
    ),
    (
      heading: 'Workout reminders',
      body:
          'If you turn reminders on, FitFlow asks for notification permission when Android requires it and uses notifications only for workout reminders and the test notification you request. After a restart, the boot permission lets FitFlow restore those scheduled reminders. FitFlow does not use exact alarms.',
    ),
    (
      heading: 'Voice coaching',
      body:
          'Voice coaching uses the text-to-speech service already configured on this device. FitFlow does not operate a speech server. The engine you or the device selected may be offline or online; FitFlow does not control that provider.',
    ),
    (
      heading: 'No ads, analytics, or sale of data',
      body:
          'FitFlow does not include an advertising SDK or an analytics SDK, and it does not sell FitFlow user data.',
    ),
    (
      heading: 'Removing the app',
      body:
          'Uninstalling FitFlow removes the app-owned local state, subject to ordinary operating-system behavior. Backup files you saved outside the app remain until you delete them.',
    ),
    (
      heading: 'Contact',
      body:
          'Privacy contact information is available through the developer contact associated with the published app.',
    ),
    (
      heading: 'Not medical advice',
      body:
          'FitFlow provides general workouts and exercise routines. It does not diagnose disease, treat a medical condition, provide rehabilitation, or act as a medical device.',
    ),
  ];

  @override
  Widget build(BuildContext context) =>
      ProfileSettingsTheme(child: Builder(builder: _buildContent));

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final titleScale = MediaQuery.textScalerOf(context).scale(16);
    final largeText = titleScale > 20;

    return Scaffold(
      backgroundColor: visual.page,
      appBar: AppBar(
        toolbarHeight: largeText ? (titleScale > 28 ? 120 : 104) : null,
        title: Semantics(
          header: true,
          child: const Text(title),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FitFlowLayout.maxReadableWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                viewportWidth < 360
                    ? FitFlowSpace.md
                    : FitFlowSpace.screenHorizontal,
                FitFlowSpace.md,
                viewportWidth < 360
                    ? FitFlowSpace.md
                    : FitFlowSpace.screenHorizontal,
                FitFlowSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FitFlowV2InfoSurface(
                    tonal: true,
                    child: Text(
                      'This page describes how FitFlow handles information in this version of the app.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: FitFlowTheme.of(context).textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.md),
                  FitFlowV2InfoSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0;
                            index < sections.length;
                            index++) ...[
                          Semantics(
                            header: true,
                            child: Text(
                              sections[index].heading,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: FitFlowSpace.xs),
                          Text(
                            sections[index].body,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (index < sections.length - 1) ...[
                            const SizedBox(height: FitFlowSpace.md),
                            const Divider(height: 1),
                            const SizedBox(height: FitFlowSpace.md),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
