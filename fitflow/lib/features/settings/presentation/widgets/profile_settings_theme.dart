import 'package:fitflow/features/workouts/presentation/workouts_theme.dart';
import 'package:flutter/material.dart';

/// Opt-in styling for Profile and its utilities; the navigation shell and
/// other screens keep their own themes and the user's selected brightness.
class ProfileSettingsTheme extends StatelessWidget {
  const ProfileSettingsTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      WorkoutsTheme(child: Builder(builder: (context) {
        final base = Theme.of(context);
        final text = base.textTheme;
        return Theme(
            data: base.copyWith(
              textTheme: text.copyWith(
                titleMedium: text.titleMedium
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                bodyLarge: text.bodyLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
                bodySmall:
                    text.bodySmall?.copyWith(fontWeight: FontWeight.w400),
              ),
              listTileTheme: base.listTileTheme.copyWith(
                minTileHeight: 48,
                minVerticalPadding: 4,
                minLeadingWidth: 24,
                horizontalTitleGap: 12,
                visualDensity: VisualDensity.standard,
              ),
              expansionTileTheme: base.expansionTileTheme.copyWith(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
              ),
            ),
            child: child);
      }));
}
