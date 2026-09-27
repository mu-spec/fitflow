import 'package:fitflow/features/workouts/domain/ranking/exercise_ranking_result.dart';
import 'package:flutter/foundation.dart';

/// Immutable candidate pools for workout generation (5D-1).
///
/// Contains eligible + ranked results split into warmup/main/cooldown intent.
/// Empty pools allowed.
@immutable
class WorkoutGenerationCandidates {
  WorkoutGenerationCandidates({
    List<ExerciseRankingResult>? warmup,
    List<ExerciseRankingResult>? main,
    List<ExerciseRankingResult>? cooldown,
  })  : _warmup = List<ExerciseRankingResult>.unmodifiable(warmup ?? const []),
        _main = List<ExerciseRankingResult>.unmodifiable(main ?? const []),
        _cooldown =
            List<ExerciseRankingResult>.unmodifiable(cooldown ?? const []);

  final List<ExerciseRankingResult> _warmup;
  final List<ExerciseRankingResult> _main;
  final List<ExerciseRankingResult> _cooldown;

  List<ExerciseRankingResult> get warmup => _warmup;
  List<ExerciseRankingResult> get main => _main;
  List<ExerciseRankingResult> get cooldown => _cooldown;

  int get warmupCount => _warmup.length;
  int get mainCount => _main.length;
  int get cooldownCount => _cooldown.length;
  int get totalCount => _warmup.length + _main.length + _cooldown.length;

  bool get hasWarmupCandidates => _warmup.isNotEmpty;
  bool get hasMainCandidates => _main.isNotEmpty;
  bool get hasCooldownCandidates => _cooldown.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutGenerationCandidates) return false;
    if (_warmup.length != other._warmup.length) return false;
    if (_main.length != other._main.length) return false;
    if (_cooldown.length != other._cooldown.length) return false;
    for (int i = 0; i < _warmup.length; i++) {
      if (_warmup[i] != other._warmup[i]) return false;
    }
    for (int i = 0; i < _main.length; i++) {
      if (_main[i] != other._main[i]) return false;
    }
    for (int i = 0; i < _cooldown.length; i++) {
      if (_cooldown[i] != other._cooldown[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (final r in _warmup) {
      hash = Object.hash(hash, r.hashCode);
    }
    for (final r in _main) {
      hash = Object.hash(hash, r.hashCode);
    }
    for (final r in _cooldown) {
      hash = Object.hash(hash, r.hashCode);
    }
    return hash;
  }

  @override
  String toString() =>
      'WorkoutGenerationCandidates(warmup: $warmupCount, main: $mainCount, cooldown: $cooldownCount, total: $totalCount)';
}
