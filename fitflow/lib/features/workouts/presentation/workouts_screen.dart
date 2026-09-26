import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:fitflow/app/router/app_routes.dart';
import 'package:fitflow/core/widgets/placeholder_row.dart';
import 'package:fitflow/core/widgets/placeholder_section.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exerciseCount = ExerciseCatalog.all.where((e) => e.active).length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your workouts', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            PlaceholderRow(
              icon: Icons.fitness_center,
              title: 'Exercise Library',
              subtitle: 'Browse $exerciseCount exercises',
              onTap: () => context.push(AppRoutes.exerciseLibrary),
            ),
            const PlaceholderSection(title: 'Recommended', subtitle: 'Workouts picked for your level and history.'),
            const PlaceholderSection(title: 'Programs', subtitle: 'Structured multi-week training plans.'),
            const PlaceholderSection(title: 'Create', subtitle: 'Build a custom workout.'),
          ],
        ),
      ),
    );
  }
}
