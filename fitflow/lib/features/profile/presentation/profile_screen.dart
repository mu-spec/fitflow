import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/profile_summary_format.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_copy.dart';
import 'package:fitflow/features/settings/presentation/widgets/utility_presentation.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/l10n/enum_labels.dart';
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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: FitFlowLayout.maxReadableWidth),
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
  Widget build(BuildContext context) =>
      FitFlowLoading(label: context.l10n.assessmentLoading);
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: FitFlowErrorState(
          title: context.l10n.utilityProfileError,
          message: context.l10n.utilityRetryBody,
          action:
              TextButton(onPressed: onRetry, child: Text(context.l10n.retry))));
}

class _ProfileMissingState extends StatelessWidget {
  const _ProfileMissingState({required this.onSetup});
  final VoidCallback onSetup;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      child: FitFlowEmptyState(
          title: context.l10n.utilityProfileMissing,
          message: context.l10n.utilityProfileSetupBody,
          action: FilledButton(
              onPressed: onSetup, child: Text(context.l10n.setUpProfile))));
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
          Semantics(
              header: true,
              child: Text(context.l10n.yourProfile,
                  style: theme.textTheme.headlineMedium)),
          const SizedBox(height: 4),
          Text(
            'Your settings shape how FitFlow adapts future workouts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileSummaryRow(
            icon: Icons.tune_rounded,
            title: 'Fitness Profile',
            subtitle:
                '${fitnessProfileSummaryPrimary(profile, l10n: context.l10n)}\n${fitnessProfileSummarySecondary(profile, l10n: context.l10n)}',
            onTap: () => context.go(AppRoutes.fitnessProfile),
          ),
          _ProfileSummaryRow(
            icon: Icons.build,
            title: 'Equipment',
            subtitle: formatEquipmentSummary(profile.equipment,
                l10n: context.l10n, showAll: true),
            onTap: () => context.go(AppRoutes.equipment),
          ),
          _ProfileSummaryRow(
            icon: Icons.tune,
            title: 'Workout Preferences',
            subtitle: formatPreferencesSummary(profile.preferences,
                l10n: context.l10n, showAll: true),
            onTap: () => context.go(AppRoutes.workoutPreferences),
          ),
          const Divider(height: 24),
          const _MovementSummary(),
          const Divider(height: 24),
          _ProfileSummaryRow(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: context.l10n.utilitySettingsSummary,
            isEditing: false,
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

/// A wrapping, editable summary backed by persisted values.
class _ProfileSummaryRow extends StatelessWidget {
  const _ProfileSummaryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isEditing = true,
  });

  final bool isEditing;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
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
          trailing: Tooltip(
              message:
                  isEditing ? context.l10n.utilityEditSection(title) : title,
              child: Icon(isEditing ? Icons.edit_outlined : Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

/// Read-only: the existing assessment is a first-run gate, not an editor.
class _MovementSummary extends ConsumerWidget {
  const _MovementSummary();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final current = ref.watch(capabilityProfileProvider);
    return UtilityDisclosure(
        title: l.utilityMovementTitle,
        summary: l.utilityMovementSummary,
        children: [
          Text(l.utilityMovementBody),
          const SizedBox(height: 12),
          current.when(
              loading: () => FitFlowLoading(label: l.assessmentLoading),
              error: (_, __) => FitFlowErrorState(
                  title: l.utilityMovementError,
                  message: l.utilityRetryBody,
                  action: TextButton(
                      onPressed: () =>
                          ref.invalidate(capabilityProfileProvider),
                      child: Text(l.retry))),
              data: (profile) => profile == null
                  ? Text(l.utilityMovementMissing)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          for (final value in profile.all)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Wrap(
                                    spacing: 16,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.spaceBetween,
                                    children: [
                                      Text(movementPatternLabel(
                                          l, value.movementPattern)),
                                      Text(assessmentChoice(l, value.level),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall),
                                    ])),
                        ])),
        ]);
  }
}
