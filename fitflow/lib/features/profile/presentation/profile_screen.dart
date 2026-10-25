import 'package:fitflow/features/settings/presentation/widgets/profile_settings_theme.dart';
import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/features/onboarding/data/user_fitness_profile.dart';
import 'package:fitflow/features/onboarding/state/user_fitness_profile_controller.dart';
import 'package:fitflow/features/profile/presentation/profile_summary_format.dart';
import 'package:fitflow/features/profile/presentation/widgets/profile_editor_widgets.dart';
import 'package:fitflow/core/design/fitflow_layout.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_feedback.dart';
import 'package:fitflow/features/capability_assessment/presentation/capability_assessment_copy.dart';
import 'package:fitflow/features/workouts/state/capability_profile_controller.dart';
import 'package:fitflow/l10n/enum_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Profile tab: real persisted profile summaries with entries into the
/// M19 editors, plus the existing Settings entry.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProfileSettingsTheme(child: _ProfileContent());
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userFitnessProfileProvider);
    final visual = FitFlowVisualV2.of(context);

    return Material(
      color: visual.page,
      child: SafeArea(
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
    final brand = FitFlowTheme.of(context);
    final l = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FitFlowSpace.screenHorizontal,
        FitFlowSpace.md,
        FitFlowSpace.screenHorizontal,
        FitFlowSpace.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.homeBrand,
            style: theme.textTheme.labelMedium?.copyWith(
              color: brand.brand,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: FitFlowSpace.xs),
          Semantics(
            header: true,
            child: Text(
              l.yourProfile,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _ProfileSummaryRow(
                icon: Icons.tune_rounded,
                title: l.profileFitnessEntry,
                subtitle:
                    '${fitnessProfileSummaryPrimary(profile, l10n: l)}\n${fitnessProfileSummarySecondary(profile, l10n: l)}',
                onTap: () => context.go(AppRoutes.fitnessProfile),
              ),
              const Divider(
                height: 1,
                indent: FitFlowSpace.md,
                endIndent: FitFlowSpace.md,
              ),
              _ProfileSummaryRow(
                icon: Icons.build,
                title: l.homeEquipment,
                subtitle: formatEquipmentSummary(
                  profile.equipment,
                  l10n: l,
                  showAll: true,
                ),
                onTap: () => context.go(AppRoutes.equipment),
              ),
              const Divider(
                height: 1,
                indent: FitFlowSpace.md,
                endIndent: FitFlowSpace.md,
              ),
              _ProfileSummaryRow(
                icon: Icons.tune,
                title: l.profilePreferencesEntry,
                subtitle: formatPreferencesSummary(
                  profile.preferences,
                  l10n: l,
                  showAll: true,
                ),
                onTap: () => context.go(AppRoutes.workoutPreferences),
              ),
            ],
          ),
          const Divider(height: 16),
          _ProfileSummaryRow(
            icon: Icons.settings,
            title: l.settingsTitle,
            subtitle: null,
            isEditing: false,
            onTap: () => context.go(AppRoutes.settings),
          ),
          const Divider(height: 16),
          const _MovementSummary(),
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
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap == null
          ? null
          : () {
              // A previous editor's success toast must not cover the next editor's
              // compact Save action when moving quickly between settings.
              ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
              onTap!();
            },
      minVerticalPadding: FitFlowSpace.xxs,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
      ),
      leading: ExcludeSemantics(
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: Tooltip(
        message: isEditing ? context.l10n.utilityEditSection(title) : title,
        child: ExcludeSemantics(
          child: Icon(
            isEditing ? Icons.edit_outlined : Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
    final theme = Theme.of(context);

    return ProfileDisclosure(
      title: l.utilityMovementTitle,
      summary: null,
      children: [
        Text(l.profileMovementGuide, style: theme.textTheme.bodySmall),
        const SizedBox(height: FitFlowSpace.sm),
        current.when(
          loading: () => FitFlowLoading(label: l.assessmentLoading),
          error: (_, __) => FitFlowErrorState(
            title: l.utilityMovementError,
            message: l.utilityRetryBody,
            action: TextButton(
              onPressed: () => ref.invalidate(capabilityProfileProvider),
              child: Text(l.retry),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Text(l.utilityMovementMissing);
            }
            final values = profile.all;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < values.length; index++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: FitFlowSpace.xs,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: FitFlowSpace.sm,
                      runSpacing: FitFlowSpace.xxs,
                      children: [
                        Text(
                          movementPatternLabel(
                            l,
                            values[index].movementPattern,
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(assessmentChoice(l, values[index].level),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (index < values.length - 1) const Divider(height: 1),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
