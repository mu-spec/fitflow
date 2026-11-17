import 'package:fitflow/core/design/widgets/fitflow_section_card.dart';
import 'package:fitflow/features/settings/presentation/widgets/profile_settings_theme.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/features/settings/data/privacy_policy_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-app explanation of FitFlow V1 data handling, plus the link to the full
/// hosted policy (`docs/privacy-policy.html`, served at
/// [PrivacyPolicyLinks.privacyPolicyUrl]).
///
/// The offline summary stays the primary content so the screen works with no
/// network; the URL is always shown as selectable text so it can be copied even
/// when no browser can be opened.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String title = 'Privacy Policy';

  static const Key onlinePolicyButtonKey = Key('privacy_policy_online_button');

  /// Opens the hosted policy in the system browser. Never throws: a device with
  /// no browser falls back to the copyable address already on screen.
  static Future<void> openOnlinePolicy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(PrivacyPolicyLinks.privacyPolicyUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'No browser could be opened. Copy the address shown above.')));
    }
  }

  static const List<({String heading, String body})> sections = [
    (
      heading: 'No account and no Home Workout service',
      body:
          'Home Workout does not create an account and does not operate a Home Workout backend, cloud sync service, or advertising service. The app works on this device without a login.',
    ),
    (
      heading: 'Information stored on this device',
      body:
          'Home Workout stores your fitness profile, movement levels and progress, workout history, custom workouts, adaptive program progress, reminder choices, and appearance preference locally on this device. Those values are not sent to a Home Workout server.',
    ),
    (
      heading: 'Backups you create',
      body:
          'A backup file is created only when you choose Backup & restore. The file is saved wherever you select with the system file picker. Home Workout does not upload that file. Android automatic backup and device-to-device transfer of Home Workout app data are turned off, so Home Workout data is not silently copied by the operating system. A file you already saved stays where you put it until you delete it.',
    ),
    (
      heading: 'Workout reminders',
      body:
          'If you turn reminders on, Home Workout asks for notification permission when Android requires it and uses notifications only for workout reminders and the test notification you request. After a restart, the boot permission lets Home Workout restore those scheduled reminders. Home Workout does not use exact alarms.',
    ),
    (
      heading: 'Voice coaching',
      body:
          'Voice coaching uses the text-to-speech service already configured on this device. Home Workout does not operate a speech server. The engine you or the device selected may be offline or online; Home Workout does not control that provider.',
    ),
    (
      heading: 'No ads, analytics, or sale of data',
      body:
          'Home Workout does not include an advertising SDK or an analytics SDK, and it does not sell Home Workout user data.',
    ),
    (
      heading: 'Removing the app',
      body:
          'Uninstalling Home Workout removes the app-owned local state, subject to ordinary operating-system behavior. Backup files you saved outside the app remain until you delete them.',
    ),
    (
      heading: 'Contact',
      body:
          'Privacy contact information is available through the developer contact associated with the published app.',
    ),
    (
      heading: 'Not medical advice',
      body:
          'Home Workout provides general workouts and exercise routines. It does not diagnose disease, treat a medical condition, provide rehabilitation, or act as a medical device.',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This page describes how Home Workout handles information in this version of the app.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: FitFlowTheme.of(context).textPrimary,
                          ),
                        ),
                        const SizedBox(height: FitFlowSpace.sm),
                        Text(
                          'The full, hosted policy is the version referenced by the Play Store listing. The summary below works offline.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: FitFlowTheme.of(context).textSecondary,
                          ),
                        ),
                        const SizedBox(height: FitFlowSpace.sm),
                        SelectableText(
                          PrivacyPolicyLinks.privacyPolicyUrl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: FitFlowTheme.of(context).textSecondary,
                          ),
                        ),
                        const SizedBox(height: FitFlowSpace.sm),
                        OutlinedButton.icon(
                          key: onlinePolicyButtonKey,
                          onPressed: () => openOnlinePolicy(context),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open full policy in browser'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: FitFlowSpace.md),
                  for (final section in sections)
                    FitFlowSectionCard(
                        child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(section.heading,
                                style: theme.textTheme.titleMedium),
                            children: [
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 8),
                              child: SelectableText(section.body,
                                  style: theme.textTheme.bodyMedium))
                        ])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
