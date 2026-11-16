import 'package:fitflow/core/design/widgets/fitflow_section_card.dart';
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
      'Home Workout works without an account. Your workout data is stored on this device unless you create a backup.';

  static const Key privacyPolicyTileKey = Key('privacy_policy_settings_tile');
  static const Key exerciseArtworkCreditsTileKey =
      Key('exercise_artwork_credits_settings_tile');

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
                  FitFlowSectionCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        Text(l.utilityAppearance,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        if (appearance.isLoading)
                          FitFlowLoading(label: l.utilityUpdating)
                        else if (appearance.hasError)
                          TextButton(
                              onPressed: () =>
                                  ref.invalidate(appearanceControllerProvider),
                              child: Text(l.retry))
                        else
                          DropdownButtonFormField<AppearanceMode>(
                              key: ValueKey(mode),
                              initialValue: mode,
                              isExpanded: true,
                              itemHeight: null,
                              decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12)),
                              items: [
                                for (final value in AppearanceMode.values)
                                  DropdownMenuItem(
                                      value: value,
                                      child: Text(value == AppearanceMode.system
                                          ? l.utilitySystemDefault
                                          : appearanceModeLabel(l, value)))
                              ],
                              onChanged: _savingAppearance
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        _selectAppearance(value);
                                      }
                                    }),
                      ])),
                  FitFlowSectionCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: Text(l.reminderSectionTitle),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              showDragHandle: true,
                              builder: (sheetContext) => ProfileSettingsTheme(
                                  child: SizedBox(
                                      height: MediaQuery.sizeOf(sheetContext)
                                              .height *
                                          .85,
                                      child: const SingleChildScrollView(
                                          padding: EdgeInsets.all(20),
                                          child: WorkoutRemindersSection(
                                              initiallyExpanded: true))))))),
                  UtilityHeading(l.utilityData),
                  const FitFlowSectionCard(child: BackupRestoreSettingsEntry()),
                  UtilityHeading(l.utilityAbout),
                  const FitFlowSectionCard(
                      child: Column(children: [
                    _PrivacyPolicyEntry(),
                    Divider(height: 1),
                    _ExerciseArtworkCreditsEntry(),
                  ])),
                  Text(SettingsScreen.localDataFooter,
                      style: theme.textTheme.bodySmall),
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

class _ExerciseArtworkCreditsEntry extends StatelessWidget {
  const _ExerciseArtworkCreditsEntry();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: SettingsScreen.exerciseArtworkCreditsTileKey,
      minVerticalPadding: FitFlowSpace.xs,
      contentPadding: EdgeInsets.zero,
      leading: ExcludeSemantics(
        child: Icon(Icons.animation_outlined, color: theme.colorScheme.primary),
      ),
      title: Text('Exercise artwork credits',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      trailing: const ExcludeSemantics(
        child: Icon(Icons.chevron_right_rounded),
      ),
      onTap: () => context.go(AppRoutes.exerciseArtworkCredits),
    );
  }
}
