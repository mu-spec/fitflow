import 'package:fitflow/features/settings/presentation/widgets/profile_settings_theme.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_restore_settings_entry.dart';
import 'package:fitflow/features/reminders/presentation/widgets/workout_reminders_section.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/presentation/widgets/utility_presentation.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Secondary settings screen, opened from the Profile tab.
///
/// Sections (M19 Part 2): Appearance, Workout reminders (M17), Data (M18
/// backup & restore), plus a small factual local-data footer. Appearance
/// selection uses persist-first semantics: a failed write keeps the previous
/// mode active and shows an honest error message.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Exact copy shown when an appearance change could not be persisted.
  static const String appearanceSaveFailedMessage =
      "Couldn't save appearance. Try again.";

  /// Factual footer copy — FitFlow has no accounts and stores data locally.
  static const String localDataFooter =
      'FitFlow works without an account. Your workout data is stored on this device unless you create a backup.';

  static const Key privacyPolicyTileKey = Key('privacy_policy_settings_tile');

  @override
  Widget build(BuildContext context) =>
      const ProfileSettingsTheme(child: _SettingsScreenContent());
}

class _SettingsScreenContent extends ConsumerStatefulWidget {
  const _SettingsScreenContent();
  @override
  ConsumerState<_SettingsScreenContent> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<_SettingsScreenContent> {
  /// Whether an appearance write is in flight; blocks duplicate selections.
  bool _savingAppearance = false;

  Future<void> _selectAppearance(AppearanceMode mode) async {
    if (_savingAppearance) {
      return;
    }
    setState(() => _savingAppearance = true);
    final saved =
        await ref.read(appearanceControllerProvider.notifier).setMode(mode);
    if (!mounted) {
      return;
    }
    setState(() => _savingAppearance = false);
    if (!saved) {
      // The previous mode remains active; report the failure truthfully.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(SettingsScreen.appearanceSaveFailedMessage),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = FitFlowVisualV2.of(context);
    final appearance = ref.watch(appearanceControllerProvider);
    final mode = appearance.valueOrNull ?? AppearanceMode.system;
    final l = context.l10n;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final titleScale = MediaQuery.textScalerOf(context).scale(16);
    final largeText = titleScale > 20;

    return Scaffold(
      backgroundColor: visual.page,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.titleLarge
            ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
        toolbarHeight: largeText ? (titleScale > 28 ? 120 : 104) : null,
        title: Semantics(
          header: true,
          child: Text(l.settingsTitle),
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
                FitFlowSpace.sm,
                viewportWidth < 360
                    ? FitFlowSpace.md
                    : FitFlowSpace.screenHorizontal,
                FitFlowSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UtilityHeading(l.utilityPreferences),
                  UtilityDisclosure(
                    title: l.utilityAppearance,
                    icon: Icons.palette_outlined,
                    hideSummaryWhenExpanded: true,
                    summary: _savingAppearance
                        ? l.utilitySaving
                        : appearance.isLoading
                            ? l.utilityUpdating
                            : appearance.hasError
                                ? l.utilityRetryBody
                                : (mode == AppearanceMode.system
                                    ? l.utilitySystemDefault
                                    : appearanceModeLabel(l, mode)),
                    children: [
                      if (appearance.isLoading)
                        FitFlowLoading(label: l.utilityUpdating)
                      else if (appearance.hasError)
                        FitFlowErrorState(
                          title: l.utilityAppearance,
                          message: l.utilityRetryBody,
                          action: TextButton(
                            onPressed: () =>
                                ref.invalidate(appearanceControllerProvider),
                            child: Text(l.retry),
                          ),
                        )
                      else
                        RadioGroup<AppearanceMode>(
                          groupValue: mode,
                          onChanged: (value) {
                            if (value == null || _savingAppearance) return;
                            // ignore: discarded_futures
                            _selectAppearance(value);
                          },
                          child: Column(
                            children: [
                              _AppearanceOption(
                                title: l.utilitySystemDefault,
                                value: AppearanceMode.system,
                                selected: mode == AppearanceMode.system,
                                enabled: !_savingAppearance,
                              ),
                              _AppearanceOption(
                                title: l.appearanceLight,
                                value: AppearanceMode.light,
                                selected: mode == AppearanceMode.light,
                                enabled: !_savingAppearance,
                              ),
                              _AppearanceOption(
                                title: l.appearanceDark,
                                value: AppearanceMode.dark,
                                selected: mode == AppearanceMode.dark,
                                enabled: !_savingAppearance,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 1),
                  const WorkoutRemindersSection(),
                  const Divider(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UtilityHeading(l.utilityData),
                      const BackupRestoreSettingsEntry(),
                      const Divider(
                        height: 1,
                        indent: FitFlowSpace.md,
                        endIndent: FitFlowSpace.md,
                      ),
                      UtilityHeading(l.utilityAbout),
                      const _PrivacyPolicyEntry(),
                    ],
                  ),
                  const SizedBox(height: FitFlowSpace.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: FitFlowSpace.sm),
                      Expanded(
                        child: Text(
                          SettingsScreen.localDataFooter,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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

class _PrivacyPolicyEntry extends StatelessWidget {
  const _PrivacyPolicyEntry();

  static const Key tileKey = SettingsScreen.privacyPolicyTileKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: tileKey,
      minVerticalPadding: FitFlowSpace.xs,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
      ),
      leading: ExcludeSemantics(
        child: Icon(
          Icons.privacy_tip_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text('Privacy Policy',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      trailing: const ExcludeSemantics(
        child: Icon(Icons.chevron_right_rounded),
      ),
      onTap: () => context.go(AppRoutes.privacyPolicy),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.title,
    required this.value,
    required this.selected,
    this.enabled = true,
  });

  final String title;
  final AppearanceMode value;
  final bool selected;

  /// Disabled while an appearance write is in flight.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppearanceMode>(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      selected: selected,
      enabled: enabled,
    );
  }
}
