import 'package:fitflow/app/config/app_dimensions.dart';
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
          'FitFlow stores your fitness profile, capability profile, adaptive progression evidence, workout history, custom workouts, adaptive program progress, reminder choices, and appearance preference locally on this device. Those values are not sent to a FitFlow server.',
    ),
    (
      heading: 'Backups you create',
      body:
          'A backup file is created only when you choose Backup & restore. The file is saved wherever you select with the system file picker. FitFlow does not upload that file. Android automatic backup and device-to-device transfer of FitFlow app data are turned off, so FitFlow data is not silently copied by the operating system. A file you already saved stays where you put it until you delete it.',
    ),
    (
      heading: 'Workout reminders',
      body:
          'If you turn reminders on, FitFlow asks for notification permission and uses it only to show the workout reminders you scheduled. After a restart, the boot permission lets FitFlow restore those scheduled reminders. FitFlow does not use exact alarms.',
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This page describes how FitFlow handles information in this version of the app.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final section in sections) ...[
                    Text(
                      section.heading,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(section.body, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
