import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/features/backup/presentation/widgets/backup_restore_settings_entry.dart';
import 'package:fitflow/features/reminders/presentation/widgets/workout_reminders_section.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Secondary settings screen, opened from the Profile tab.
///
/// Sections (M19 Part 2): Appearance, Workout reminders (M17), Data (M18
/// backup & restore), plus a small factual local-data footer. Appearance
/// selection uses persist-first semantics: a failed write keeps the previous
/// mode active and shows an honest error message.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  /// Exact copy shown when an appearance change could not be persisted.
  static const String appearanceSaveFailedMessage =
      "Couldn't save appearance. Try again.";

  /// Factual footer copy — FitFlow has no accounts and stores data locally.
  static const String localDataFooter =
      'FitFlow works without an account. Your workout data is stored on this device unless you create a backup.';

  static const Key privacyPolicyTileKey = Key('privacy_policy_settings_tile');

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Whether an appearance write is in flight; blocks duplicate selections.
  bool _savingAppearance = false;

  Future<void> _selectAppearance(AppearanceMode mode) async {
    if (_savingAppearance) {
      return;
    }
    setState(() => _savingAppearance = true);
    final saved = await ref
        .read(appearanceControllerProvider.notifier)
        .setMode(mode);
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
    final mode = ref.watch(appearanceControllerProvider).value ??
        AppearanceMode.system;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(theme, 'Appearance'),
                  const SizedBox(height: AppDimens.itemGap),
                  RadioGroup<AppearanceMode>(
                    groupValue: mode,
                    onChanged: (value) {
                      // Duplicate in-flight writes are blocked here and in
                      // the controller; the tiles are also disabled below.
                      if (value == null || _savingAppearance) {
                        return;
                      }
                      // ignore: discarded_futures
                      _selectAppearance(value);
                    },
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _AppearanceOption(
                            title: 'System default',
                            subtitle: 'Follow your device setting.',
                            value: AppearanceMode.system,
                            selected: mode == AppearanceMode.system,
                            enabled: !_savingAppearance,
                          ),
                          _AppearanceOption(
                            title: 'Light',
                            subtitle: 'Always use the light theme.',
                            value: AppearanceMode.light,
                            selected: mode == AppearanceMode.light,
                            enabled: !_savingAppearance,
                          ),
                          _AppearanceOption(
                            title: 'Dark',
                            subtitle: 'Always use the dark theme.',
                            value: AppearanceMode.dark,
                            selected: mode == AppearanceMode.dark,
                            enabled: !_savingAppearance,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const WorkoutRemindersSection(),
                  const SizedBox(height: 24),
                  _sectionTitle(theme, 'Data'),
                  const SizedBox(height: AppDimens.itemGap),
                  const BackupRestoreSettingsEntry(),
                  const SizedBox(height: AppDimens.itemGap),
                  const _PrivacyPolicyEntry(),
                  const SizedBox(height: 24),
                  Text(
                    SettingsScreen.localDataFooter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _PrivacyPolicyEntry extends StatelessWidget {
  const _PrivacyPolicyEntry();

  static const Key tileKey = SettingsScreen.privacyPolicyTileKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: tileKey,
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Privacy Policy'),
        subtitle: const Text('How FitFlow handles information on this device.'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go(AppRoutes.privacyPolicy),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selected,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final AppearanceMode value;
  final bool selected;

  /// Disabled while an appearance write is in flight.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: selected ? '$title, selected' : title,
      hint: subtitle,
      child: ExcludeSemantics(
        child: RadioListTile<AppearanceMode>(
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          enabled: enabled,
        ),
      ),
    );
  }
}
