import 'package:fitflow/app/config/app_dimensions.dart';
import 'package:flutter/material.dart';

/// Polished loading state for Home using normal Flutter widgets, no shimmer dep.
class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header skeleton
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 220,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Hero card skeleton
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Loading your adaptive workout...',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _skeletonLine(context, double.infinity),
                          const SizedBox(height: 12),
                          _skeletonLine(context, 180),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _skeletonBox(context, 60)),
                              const SizedBox(width: 12),
                              Expanded(child: _skeletonBox(context, 60)),
                              const SizedBox(width: 12),
                              Expanded(child: _skeletonBox(context, 60)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _skeletonBox(context, 80),
                  const SizedBox(height: 16),
                  _skeletonBox(context, 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeletonLine(BuildContext context, double width) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _skeletonBox(BuildContext context, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
      ),
    );
  }
}
