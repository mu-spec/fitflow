import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/features/settings/data/appearance_mode.dart';
import 'package:fitflow/features/settings/state/appearance_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Secondary settings screen, opened from the Profile tab.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(appearanceControllerProvider).value ??
        AppearanceMode.system;
    final controller = ref.read(appearanceControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimens.itemGap),
            RadioGroup<AppearanceMode>(
              groupValue: mode,
              onChanged: (value) {
                if (value != null) {
                  controller.setMode(value);
                }
              },
              child: Card(
                margin: EdgeInsets.zero,
                child: const Column(
                  children: [
                    _AppearanceOption(
                      title: 'System default',
                      subtitle: 'Follow your device setting.',
                      value: AppearanceMode.system,
                    ),
                    _AppearanceOption(
                      title: 'Light',
                      subtitle: 'Always use the light theme.',
                      value: AppearanceMode.light,
                    ),
                    _AppearanceOption(
                      title: 'Dark',
                      subtitle: 'Always use the dark theme.',
                      value: AppearanceMode.dark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final AppearanceMode value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppearanceMode>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
    );
  }
}
