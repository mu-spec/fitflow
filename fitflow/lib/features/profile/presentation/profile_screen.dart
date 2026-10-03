import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/profile_summary_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile tab: real persisted profile summaries with entries into the
/// M19 editors, plus the existing Settings entry.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userFitnessProfileProvider);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: profileAsync.when(
            loading: () => const _ProfileLoadingState(),
            error: (error, stackTrace) => _ProfileErrorState(
              onRetry: () => ref.invalidate(userFitnessProfileProvider),
            ),
            data: (profile) => profile == null
                ? _ProfileMissingState(
                    onSetup: () => context.go(AppRoutes.onboarding),
                  )
                : _ProfileSummaryList(profile: profile),
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.yourProfile, style: theme.textTheme.titleLarge),
          const SizedBox(height: 48),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Loading your profile…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.yourProfile, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 40,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Your profile couldn't be loaded.",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your saved settings are still safe. Try loading them again.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMissingState extends StatelessWidget {
  const _ProfileMissingState({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.yourProfile, style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitness profile not set up',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Answer a few quick questions so FitFlow can tailor your workouts.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onSetup,
                    child: Text(context.l10n.setUpProfile),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryList extends StatelessWidget {
  const _ProfileSummaryList({required this.profile});

  final UserFitnessProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.yourProfile, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Your settings shape how FitFlow adapts future workouts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileSummaryRow(
            icon: Icons.person,
            title: 'Fitness Profile',
            subtitle:
                '${fitnessProfileSummaryPrimary(profile)}\n${fitnessProfileSummarySecondary(profile)}',
            onTap: () => context.go(AppRoutes.fitnessProfile),
          ),
          _ProfileSummaryRow(
            icon: Icons.build,
            title: 'Equipment',
            subtitle: formatEquipmentSummary(profile.equipment),
            onTap: () => context.go(AppRoutes.equipment),
          ),
          _ProfileSummaryRow(
            icon: Icons.tune,
            title: 'Workout Preferences',
            subtitle: formatPreferencesSummary(profile.preferences),
            onTap: () => context.go(AppRoutes.workoutPreferences),
          ),
          _ProfileSummaryRow(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Manage your app.',
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

/// A card-style summary row for the Profile tab (same visual language as the
/// old placeholder rows, but always backed by real persisted data).
class _ProfileSummaryRow extends StatelessWidget {
  const _ProfileSummaryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.itemGap),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
