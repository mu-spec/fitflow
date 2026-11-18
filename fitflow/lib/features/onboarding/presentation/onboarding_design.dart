import 'package:flutter/material.dart';

/// Light first-run design tokens.
///
/// The onboarding flow is a self-contained white surface: these values are used
/// directly by its widgets instead of the global palette, so the flow stays
/// light and readable regardless of the device theme, and no other screen
/// changes colour. Greens come from the app icon family: [accent] is the icon
/// green used for accents and selection, [accentDeep] is its deeper shade,
/// which is what carries white text and selection glyphs at readable contrast
/// (4.9:1 on white).
abstract final class OnboardingColors {
  /// Page background on every step.
  static const Color page = Color(0xFFFFFFFF);

  /// Step headings.
  static const Color heading = Color(0xFF111111);

  /// Option titles.
  static const Color title = Color(0xFF171717);

  /// Descriptions and supporting text.
  static const Color body = Color(0xFF555555);

  /// Secondary descriptions and metadata (>= 4.5:1 on white and on [surface]).
  static const Color muted = Color(0xFF5F6873);

  /// Unselected option card and quiet note surfaces.
  static const Color surface = Color(0xFFF5F6F7);

  /// Selected option card wash.
  static const Color surfaceSelected = Color(0xFFF3FCE9);

  static const Color border = Color(0xFFE6E9EB);
  static const Color borderSoft = Color(0xFFEDEFF1);

  /// Icon green: selection border, progress fill, decorative tints.
  static const Color accent = Color(0xFF48E61D);

  /// Pale green chip behind decorative icons.
  static const Color accentTint = Color(0xFFEAFBDD);

  /// Deeper icon green: primary button, selection glyphs, leading icons.
  static const Color accentDeep = Color(0xFF1E8214);

  /// Inactive progress segments.
  static const Color track = Color(0xFFECEEEF);

  /// Disabled controls stay clearly inert but still legible as controls.
  static const Color disabledSurface = Color(0xFFE9EBED);
  static const Color disabledInk = Color(0xFF9AA1A9);

  static const Color error = Color(0xFFB42318);
  static const Color errorSurface = Color(0xFFFEF3F2);
  static const Color errorBorder = Color(0xFFFDA29B);
}

/// A flat light card: quiet surface, hairline border, no elevation or imagery.
class OnboardingSurface extends StatelessWidget {
  const OnboardingSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.background = OnboardingColors.surface,
    this.borderColor = OnboardingColors.borderSoft,
    this.radius = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background, borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor)),
        child: Padding(padding: padding, child: child),
      );
}

/// A quiet supporting note. Explanatory only: it never becomes a selectable
/// control, so it is excluded from the choice semantics of the step.
class OnboardingNote extends StatelessWidget {
  const OnboardingNote({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final body =
        type.bodySmall?.copyWith(color: OnboardingColors.muted, height: 1.4);
    final glyph = icon;
    return OnboardingSurface(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (glyph != null) ...[
          ExcludeSemantics(
              child: Icon(glyph, size: 18, color: OnboardingColors.muted)),
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(text, style: body)),
      ]),
    );
  }
}
