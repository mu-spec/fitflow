import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/fitflow_visual_v2.dart';
import 'package:fitflow/core/design/widgets/fitflow_v2_feature_art.dart';
import 'package:flutter/material.dart';

/// How strongly a [FitFlowV2FeatureCard] stands out on the page.
enum FitFlowV2FeatureCardEmphasis {
  /// The page's leading destination: V2 hero band, artwork on the hero.
  primary,

  /// An important but quieter feature: supporting surface with artwork.
  secondary,
}

/// Opt-in V2 media card for feature entries, introduced by Step 3.
///
/// One card anatomy — artwork panel above, heading + concise supporting
/// text below, native action — with controlled emphasis variation so a
/// feature hub does not collapse into identical boxes:
///
/// * [onTap] renders the content as a native [ListTile] (button semantics,
///   focus, ≥48dp target, chevron affordance): navigation-led features.
/// * [primaryAction] renders an explicit CTA below the copy instead:
///   features with a meaningful action of their own (never both at once —
///   that would be CTA competition).
///
/// The slot-based structure (art/title/supporting text/metadata/action)
/// suits later Programs, Library, Progress and Profile entry points without
/// forcing those screens into one layout. Artwork is decorative-only, sized
/// by the caller and always yields before text at large type scales.
class FitFlowV2FeatureCard extends StatelessWidget {
  const FitFlowV2FeatureCard({
    super.key,
    required this.art,
    required this.title,
    required this.subtitle,
    this.emphasis = FitFlowV2FeatureCardEmphasis.primary,
    this.artHeight = 112,
    this.metadata = const [],
    this.onTap,
    this.primaryAction,
  });

  final FitFlowV2FeatureArtKind art;
  final String title;
  final String subtitle;
  final FitFlowV2FeatureCardEmphasis emphasis;

  /// Artwork panel height. Choose per breakpoint and shrink at large text —
  /// artwork yields before text, never the other way around.
  final double artHeight;

  /// Truthful noninteractive facts under the copy.
  final List<Widget> metadata;

  /// Whole-row navigation. Mutually exclusive with [primaryAction].
  final VoidCallback? onTap;

  /// Single explicit CTA, e.g. an empty state's native create button.
  final Widget? primaryAction;

  @override
  Widget build(BuildContext context) {
    assert(onTap == null || primaryAction == null,
        'One action per feature card: navigation or one CTA.');
    final v = FitFlowVisualV2.of(context);
    final text = Theme.of(context).textTheme;
    final onHero = emphasis == FitFlowV2FeatureCardEmphasis.primary;
    final titleStyle = text.titleLarge?.copyWith(
        color: onHero ? v.onHero : null, fontWeight: FontWeight.w600);
    final subtitleStyle = text.bodyMedium?.copyWith(
        color:
            onHero ? v.heroSecondary : FitFlowTheme.of(context).textSecondary);

    final artPanel = FitFlowV2FeatureArt(
      kind: art,
      onHero: onHero,
      width: double.infinity,
      height: artHeight,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.all(FitFlowSpace.xs),
    );

    final Widget content;
    if (onTap != null) {
      content = ListTile(
        contentPadding: const EdgeInsets.fromLTRB(
            FitFlowSpace.md, FitFlowSpace.xs, FitFlowSpace.sm, FitFlowSpace.md),
        title: Text(title, style: titleStyle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: FitFlowSpace.xxs),
          child: Text(subtitle, style: subtitleStyle),
        ),
        trailing: Icon(Icons.chevron_right,
            color:
                onHero ? v.heroSecondary : FitFlowTheme.of(context).textMuted),
        onTap: onTap,
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.all(FitFlowSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: FitFlowSpace.xxs),
            Text(subtitle, style: subtitleStyle),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: FitFlowSpace.sm),
              Wrap(
                  spacing: FitFlowSpace.xs,
                  runSpacing: FitFlowSpace.xs,
                  children: metadata),
            ],
            if (primaryAction != null) ...[
              const SizedBox(height: FitFlowSpace.md),
              primaryAction!,
            ],
          ],
        ),
      );
    }

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: FitFlowRadius.cardBorder,
          gradient: onHero
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [v.heroStart, v.heroEnd])
              : null,
          color: onHero ? null : v.support,
          border:
              Border.all(color: onHero ? v.heroLine : v.subtleBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: FitFlowRadius.cardBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [artPanel, content],
          ),
        ),
      ),
    );
  }
}

/// Compact secondary destination: artwork chip + concise copy + chevron,
/// one native tap. Clearly lighter than [FitFlowV2FeatureCard] so Explorer
/// tools support a feature hub without rivaling its primary cards.
class FitFlowV2ExploreTile extends StatelessWidget {
  const FitFlowV2ExploreTile({
    super.key,
    required this.art,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final FitFlowV2FeatureArtKind art;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = FitFlowVisualV2.of(context);
    final t = FitFlowTheme.of(context);
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Material(
        color: v.support,
        shape: RoundedRectangleBorder(
          borderRadius: FitFlowRadius.mediumBorder,
          side: BorderSide(color: v.subtleBorder),
        ),
        child: InkWell(
          borderRadius: FitFlowRadius.mediumBorder,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.all(FitFlowSpace.sm),
              child: Row(
                children: [
                  FitFlowV2FeatureArt(
                      kind: art,
                      width: 52,
                      height: 52,
                      borderRadius: FitFlowRadius.smallBorder),
                  const SizedBox(width: FitFlowSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: FitFlowSpace.xxs),
                        Text(subtitle,
                            style: text.bodySmall
                                ?.copyWith(color: t.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: FitFlowSpace.xs),
                  Icon(Icons.chevron_right, color: t.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
