import 'package:fitflow/core/design/media/exercise_media_spec.dart';
import 'package:flutter/foundation.dart';

@immutable
class ProgramMediaSpec {
  const ProgramMediaSpec({required this.programId, required this.cover});
  final String programId;
  final FitFlowMediaAsset cover;
}

/// Covers identify existing programs, never their generated session contents.
abstract final class ProgramMediaRegistry {
  static const List<ProgramMediaSpec> entries = [
    ProgramMediaSpec(
      programId: 'balanced_foundations',
      cover: FitFlowMediaAsset(
        path: 'assets/images/programs/balanced_foundations.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ProgramMediaSpec(
      programId: 'strength_foundations',
      cover: FitFlowMediaAsset(
        path: 'assets/images/programs/strength_foundations.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ProgramMediaSpec(
      programId: 'endurance_builder',
      cover: FitFlowMediaAsset(
        path: 'assets/images/programs/endurance_builder.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ProgramMediaSpec(
      programId: 'mobility_movement',
      cover: FitFlowMediaAsset(
        path: 'assets/images/programs/mobility_movement.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
    ProgramMediaSpec(
      programId: 'stay_active_starter',
      cover: FitFlowMediaAsset(
        path: 'assets/images/programs/stay_active_starter.webp',
        pixelWidth: 960,
        pixelHeight: 720,
      ),
    ),
  ];

  static final Map<String, ProgramMediaSpec> _byId = Map.unmodifiable({
    for (final entry in entries) entry.programId: entry,
  });

  static ProgramMediaSpec? lookup(String programId) => _byId[programId];
}
