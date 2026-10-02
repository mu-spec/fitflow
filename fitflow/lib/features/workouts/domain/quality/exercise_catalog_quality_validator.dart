import 'package:fitflow/features/onboarding/data/workout_equipment.dart';
import 'package:fitflow/features/workouts/data/exercise_catalog.dart';
import 'package:fitflow/features/workouts/domain/exercise.dart';
import 'package:fitflow/features/workouts/domain/exercise_type.dart';
import 'package:fitflow/features/workouts/domain/impact_level.dart';
import 'package:fitflow/features/workouts/domain/noise_level.dart';

/// Severity of a single quality diagnostic.
enum CatalogDiagnosticSeverity {
  /// Blocks production use; the catalog must have zero of these.
  error,

  /// Should be reviewed and eliminated where avoidable.
  warning,
}

/// One structured quality diagnostic for a catalog exercise.
class CatalogQualityDiagnostic {
  const CatalogQualityDiagnostic({
    required this.exerciseId,
    required this.rule,
    required this.message,
    required this.severity,
  });

  /// The exercise this diagnostic refers to (or `<catalog>` for global rules).
  final String exerciseId;

  /// Stable rule identifier, e.g. `id.format` or `progression.no_cycles`.
  final String rule;

  /// Concise human-readable explanation.
  final String message;

  final CatalogDiagnosticSeverity severity;

  bool get isError => severity == CatalogDiagnosticSeverity.error;

  @override
  String toString() =>
      '[${isError ? 'ERROR' : 'WARNING'}] $exerciseId :: $rule :: $message';
}

/// Aggregated result of a catalog quality pass.
class CatalogQualityReport {
  const CatalogQualityReport({
    required this.diagnostics,
    required this.exerciseCount,
  });

  final List<CatalogQualityDiagnostic> diagnostics;
  final int exerciseCount;

  List<CatalogQualityDiagnostic> get errors => diagnostics
      .where((d) => d.severity == CatalogDiagnosticSeverity.error)
      .toList(growable: false);

  List<CatalogQualityDiagnostic> get warnings => diagnostics
      .where((d) => d.severity == CatalogDiagnosticSeverity.warning)
      .toList(growable: false);

  bool get hasErrors => errors.isNotEmpty;

  /// Actionable multi-line description, grouped by severity.
  String describe() {
    final buffer = StringBuffer()
      ..writeln('Catalog quality report ($exerciseCount exercises):')
      ..writeln('errors: ${errors.length}, warnings: ${warnings.length}');
    for (final d in errors) {
      buffer.writeln('  ${d.toString()}');
    }
    for (final d in warnings) {
      buffer.writeln('  ${d.toString()}');
    }
    return buffer.toString();
  }
}

/// Pure, deterministic quality validator for exercise catalogs.
///
/// No widget logic, no persistence. Takes an explicit catalog list so tests
/// can validate synthetic fixtures; [validateCatalog] targets the production
/// [ExerciseCatalog].
abstract final class ExerciseCatalogQualityValidator {
  /// Canonical tag marking a jumping exercise (must stay in sync with
  /// `ExerciseEligibilityEngine`).
  static const String jumpingTag = 'jumping';

  /// Canonical tag marking an explicit no-jumping substitute.
  static const String noJumpingTag = 'no_jumping';

  /// Global identifier for catalog-level diagnostics.
  static const String catalogId = '<catalog>';

  static final RegExp _snakeCase = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');

  /// Phrases that indicate unsupported health/medical claims.
  ///
  /// Each entry is matched as a whole word/phrase (case-insensitive) so that
  /// benign words like "secure" do not trip the "cure" rule.
  static const List<String> _bannedClaimPhrases = <String>[
    'cure',
    'cures',
    'cured',
    'heal',
    'heals',
    'healed',
    'rehab',
    'rehabilitation',
    'treat',
    'treats',
    'treatment',
    'diagnose',
    'diagnosis',
    'injury prevention',
    'prevent injury',
    'prevents injuries',
    'guaranteed',
    'guarantees',
    'guarantee',
    'weight loss',
    'lose weight',
    'burn fat',
    'burns fat',
    'fat loss',
    'muscle gain',
    'gain muscle',
    'pain relief',
    'relieve pain',
    'relieves pain',
    'pain-free',
    'fix posture',
    'fixes posture',
    'corrects posture',
    'medical',
  ];

  /// Vague wording that weakens common-mistake content.
  static const List<String> _vagueMistakePhrases = <String>[
    'bad form',
    'poor form',
    'wrong form',
    'incorrect form',
  ];

  /// Validates the production catalog.
  static CatalogQualityReport validateCatalog() =>
      validate(ExerciseCatalog.all);

  /// Validates an explicit catalog list and returns all diagnostics.
  static CatalogQualityReport validate(List<Exercise> catalog) {
    final diagnostics = <CatalogQualityDiagnostic>[];
    void error(String id, String rule, String message) => diagnostics.add(
          CatalogQualityDiagnostic(
            exerciseId: id,
            rule: rule,
            message: message,
            severity: CatalogDiagnosticSeverity.error,
          ),
        );
    void warning(String id, String rule, String message) => diagnostics.add(
          CatalogQualityDiagnostic(
            exerciseId: id,
            rule: rule,
            message: message,
            severity: CatalogDiagnosticSeverity.warning,
          ),
        );

    // ---- Global: ID uniqueness -------------------------------------------
    final idsSeen = <String, int>{};
    for (final exercise in catalog) {
      idsSeen.update(exercise.id, (count) => count + 1, ifAbsent: () => 1);
    }
    idsSeen.forEach((id, count) {
      if (count > 1) {
        error(id, 'id.unique', 'exercise id appears $count times');
      }
    });

    for (final exercise in catalog) {
      _validateStructural(exercise, error, warning);
      if (exercise.active) {
        _validateContent(exercise, error, warning);
        _validatePrescription(exercise, error, warning);
        _validateEquipment(exercise, error, warning);
        _validateMetadataConsistency(exercise, error, warning);
        _validateTags(exercise, error, warning);
        _validateClaims(exercise, error, warning);
      }
      _validateAsset(exercise, error, warning);
    }

    _validateProgressionFamilies(catalog, error, warning);

    return CatalogQualityReport(
      diagnostics: List.unmodifiable(diagnostics),
      exerciseCount: catalog.length,
    );
  }

  // ---- Structural / ID rules ---------------------------------------------
  static void _validateStructural(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final id = exercise.id;
    if (id.trim().isEmpty) {
      error(id, 'id.not_empty', 'exercise id must not be empty');
      return;
    }
    if (!_snakeCase.hasMatch(id)) {
      error(
        id,
        'id.format',
        'id must be lowercase snake_case without spaces, uppercase, or '
        'leading/trailing underscores',
      );
    }

    // Lightweight model validation (prescription basics, non-negative rank).
    for (final problem in exercise.validate()) {
      error(id, 'model.validate', problem);
    }

    // Non-empty name is required for every catalog entry.
    if (exercise.name.trim().isEmpty) {
      error(id, 'name.not_empty', 'name must not be empty');
    }
  }

  // ---- Content rules -------------------------------------------------------
  static void _validateContent(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final id = exercise.id;

    final description = exercise.shortDescription;
    if (description == null || description.trim().isEmpty) {
      error(id, 'description.present', 'shortDescription must not be empty');
    } else {
      final trimmed = description.trim();
      if (!trimmed.endsWith('.')) {
        warning(
          id,
          'description.style',
          'shortDescription should end with a period',
        );
      }
      final sentenceCount =
          trimmed.split(RegExp(r'(?<=[.!?])\s+')).length;
      if (sentenceCount > 1) {
        warning(
          id,
          'description.one_sentence',
          'shortDescription should be one concise sentence '
          '(found $sentenceCount)',
        );
      }
    }

    if (exercise.primaryMuscles.isEmpty) {
      error(
        id,
        'muscles.primary_not_empty',
        'active trainable exercise needs at least one primary muscle',
      );
    }
    final overlap =
        exercise.primaryMuscles.intersection(exercise.secondaryMuscles);
    if (overlap.isNotEmpty) {
      error(
        id,
        'muscles.no_overlap',
        'muscles listed as both primary and secondary: '
        '${overlap.map((m) => m.name).join(', ')}',
      );
    }

    if (exercise.movementPattern == null) {
      warning(
        id,
        'movement_pattern.present',
        'movement pattern is expected for catalog exercises',
      );
    }

    if (exercise.instructions.isEmpty) {
      error(id, 'instructions.not_empty', 'instructions must not be empty');
    } else if (exercise.instructions.length < 2 ||
        exercise.instructions.length > 6) {
      warning(
        id,
        'instructions.step_count',
        'target roughly 3 concise steps '
        '(found ${exercise.instructions.length})',
      );
    }
    for (final step in exercise.instructions) {
      if (step.trim().isEmpty) {
        error(id, 'instructions.not_empty', 'an instruction step is blank');
      }
    }

    if (exercise.commonMistakes.isEmpty) {
      error(
        id,
        'mistakes.not_empty',
        'common mistakes must not be empty',
      );
    }
    for (final mistake in exercise.commonMistakes) {
      final lowered = mistake.toLowerCase();
      if (mistake.trim().isEmpty) {
        error(id, 'mistakes.not_empty', 'a common-mistake entry is blank');
      }
      for (final vague in _vagueMistakePhrases) {
        if (lowered.contains(vague)) {
          warning(
            id,
            'mistakes.concrete',
            'common mistake "$mistake" is vague; prefer a concrete '
            'movement error',
          );
        }
      }
    }

    final breathing = exercise.breathingGuidance;
    if (breathing == null || breathing.trim().isEmpty) {
      error(id, 'breathing.present', 'breathing guidance must not be empty');
    } else {
      // Flag only instructions that actively encourage holding the breath.
      // Guidance telling users NOT to hold their breath is correct and must
      // not be flagged.
      final withoutNegations = breathing.toLowerCase().replaceAll(
            RegExp(r"do not hold (your )?breath|don't hold (your )?breath|"
                r'avoid holding (your )?breath|never hold (your )?breath|'
                r'rather than holding (your )?breath|'
                r'instead of holding (your )?breath'),
            '',
          );
      if (withoutNegations.contains('hold your breath') ||
          withoutNegations.contains('hold breath') ||
          withoutNegations.contains('holding your breath')) {
        warning(
          id,
          'breathing.no_breath_hold',
          'avoid instructing breath-holding: "$breathing"',
        );
      }
    }
  }

  // ---- Prescription rules --------------------------------------------------
  static void _validatePrescription(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final id = exercise.id;

    switch (exercise.exerciseType) {
      case ExerciseType.reps:
        if (exercise.defaultReps == null || exercise.defaultReps! <= 0) {
          error(
            id,
            'prescription.reps_positive',
            'reps exercise requires a positive defaultReps',
          );
        } else if (exercise.defaultReps! > 60) {
          warning(
            id,
            'prescription.reps_outlier',
            'defaultReps ${exercise.defaultReps} looks unusually high',
          );
        }
        if (exercise.defaultDuration != null) {
          error(
            id,
            'prescription.type_conflict',
            'reps exercise must not carry a defaultDuration',
          );
        }
      case ExerciseType.timed:
        final duration = exercise.defaultDuration;
        if (duration == null || duration <= Duration.zero) {
          error(
            id,
            'prescription.duration_positive',
            'timed exercise requires a positive defaultDuration',
          );
        } else if (duration > const Duration(minutes: 5)) {
          warning(
            id,
            'prescription.duration_outlier',
            'defaultDuration ${duration.inSeconds}s looks unusually long',
          );
        }
        if (exercise.defaultReps != null) {
          error(
            id,
            'prescription.type_conflict',
            'timed exercise must not carry defaultReps',
          );
        }
    }

    final rest = exercise.defaultRest;
    if (rest == null) {
      error(
        id,
        'prescription.rest_present',
        'defaultRest is required so defaults can build a prescription',
      );
    } else if (rest < Duration.zero) {
      error(id, 'prescription.rest_positive', 'defaultRest must not be '
          'negative');
    } else if (rest == Duration.zero) {
      warning(
        id,
        'prescription.rest_zero',
        'zero defaultRest should be intentional',
      );
    } else if (rest > const Duration(minutes: 10)) {
      warning(
        id,
        'prescription.rest_outlier',
        'defaultRest ${rest.inSeconds}s looks unusually long',
      );
    }
  }

  // ---- Equipment rules -------------------------------------------------------
  static const Map<String, WorkoutEquipment> _equipmentByNameFragment =
      <String, WorkoutEquipment>{
    'chair': WorkoutEquipment.chair,
    'bench': WorkoutEquipment.bench,
    'band': WorkoutEquipment.resistanceBands,
    'dumbbell': WorkoutEquipment.dumbbells,
    'kettlebell': WorkoutEquipment.kettlebell,
    'pull-up bar': WorkoutEquipment.pullUpBar,
    'pullup bar': WorkoutEquipment.pullUpBar,
    'towel': WorkoutEquipment.towel,
    'mat': WorkoutEquipment.exerciseMat,
  };

  static void _validateEquipment(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final id = exercise.id;
    final equipment = exercise.requiredEquipment;

    if (equipment.isEmpty) {
      warning(
        id,
        'equipment.empty',
        'requiredEquipment is empty; use {WorkoutEquipment.none} for '
        'equipment-free exercises',
      );
      return;
    }

    if (equipment.contains(WorkoutEquipment.none) && equipment.length > 1) {
      error(
        id,
        'equipment.none_conflict',
        'WorkoutEquipment.none must not coexist with real equipment',
      );
    }

    final loweredName = exercise.name.toLowerCase();
    _equipmentByNameFragment.forEach((fragment, expected) {
      if (fragment == 'mat') {
        // "mat" is too collision-prone for name matching; skip heuristic.
        return;
      }
      if (loweredName.contains(fragment) && !equipment.contains(expected)) {
        warning(
          id,
          'equipment.name_mismatch',
          'name mentions "$fragment" but ${expected.name} is not required',
        );
      }
    });
  }

  // ---- Metadata consistency (impact/noise/tags interplay) --------------------
  static void _validateMetadataConsistency(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final id = exercise.id;
    final jumps = exercise.tags.contains(jumpingTag);

    if (jumps && exercise.impactLevel == ImpactLevel.low) {
      error(
        id,
        'impact.jumping_not_low',
        'jumping-tagged exercise must not be low impact; eligibility '
        'relies on this field',
      );
    }
    if (jumps && exercise.noiseLevel == NoiseLevel.quiet) {
      warning(
        id,
        'noise.jumping_not_quiet',
        'jumping-tagged exercise marked quiet; review noise metadata',
      );
    }
    if (!jumps &&
        exercise.impactLevel == ImpactLevel.high &&
        exercise.tags.contains(noJumpingTag)) {
      warning(
        id,
        'impact.no_jumping_but_high',
        'exercise carries no_jumping tag but is high impact; review',
      );
    }

  }

  // ---- Tag rules ---------------------------------------------------------------
  static void _validateTags(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    for (final tag in exercise.tags) {
      if (tag.trim().isEmpty) {
        error(exercise.id, 'tag.format', 'tag must not be empty');
        continue;
      }
      if (tag != tag.trim()) {
        error(
          exercise.id,
          'tag.format',
          'tag "$tag" has leading/trailing whitespace',
        );
      }
      if (!_snakeCase.hasMatch(tag)) {
        error(
          exercise.id,
          'tag.format',
          'tag "$tag" must be lowercase snake_case',
        );
      }
    }
  }

  // ---- Health/safety claim rules -------------------------------------------------
  static void _validateClaims(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final sections = <String, String>{
      'name': exercise.name,
      'shortDescription': exercise.shortDescription ?? '',
      'instructions': exercise.instructions.join(' '),
      'commonMistakes': exercise.commonMistakes.join(' '),
      'breathingGuidance': exercise.breathingGuidance ?? '',
    };

    sections.forEach((section, text) {
      final lowered = text.toLowerCase();
      for (final phrase in _bannedClaimPhrases) {
        final pattern = RegExp('\\b${RegExp.escape(phrase)}\\b');
        if (pattern.hasMatch(lowered)) {
          error(
            exercise.id,
            'claims.unsupported',
            '$section contains unsupported claim phrase "$phrase"',
          );
        }
      }
    });
  }

  // ---- Asset rules ---------------------------------------------------------------
  static void _validateAsset(
    Exercise exercise,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final path = exercise.assetPath;
    if (path != null && path.trim().isEmpty) {
      error(
        exercise.id,
        'asset.truthful',
        'assetPath must be null or a real path, never blank',
      );
    }
  }

  // ---- Progression family rules ------------------------------------------------
  static void _validateProgressionFamilies(
    List<Exercise> catalog,
    void Function(String, String, String) error,
    void Function(String, String, String) warning,
  ) {
    final byId = <String, Exercise>{
      for (final exercise in catalog) exercise.id: exercise,
    };
    final families = <String, List<Exercise>>{};
    for (final exercise in catalog) {
      final familyId = exercise.progressionFamilyId;
      if (familyId != null) {
        families.putIfAbsent(familyId, () => <Exercise>[]).add(exercise);
      }
    }

    families.forEach((familyId, members) {
      // Rank rules.
      final ranksSeen = <int, int>{};
      for (final member in members) {
        if (member.progressionRank <= 0) {
          error(
            member.id,
            'progression.rank_positive',
            'family "$familyId" members need a positive (one-based) '
            'progressionRank; found ${member.progressionRank}',
          );
        }
        ranksSeen.update(
          member.progressionRank,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      ranksSeen.forEach((rank, count) {
        if (count > 1) {
          error(
            familyId,
            'progression.ranks_unique',
            'family "$familyId" has $count members sharing rank $rank',
          );
        }
      });

      // Movement pattern consistency within the family.
      final patterns = members
          .map((m) => m.movementPattern)
          .toSet();
      if (patterns.length > 1) {
        error(
          familyId,
          'progression.family_pattern',
          'family "$familyId" mixes movement patterns: '
          '${patterns.map((p) => p?.name ?? 'null').join(', ')}',
        );
      }

      // Difficulty should not obviously regress along the ladder.
      final sorted = List<Exercise>.of(members)
        ..sort((a, b) => a.progressionRank.compareTo(b.progressionRank));
      for (var i = 1; i < sorted.length; i++) {
        final previous = sorted[i - 1];
        final current = sorted[i];
        if (current.difficulty.index < previous.difficulty.index) {
          warning(
            current.id,
            'progression.difficulty_direction',
            'rank ${current.progressionRank} is easier than rank '
            '${previous.progressionRank} (${previous.id}) in family '
            '"$familyId"; confirm this is intentional',
          );
        }
      }
    });

    // Link rules (per exercise, both family members and standalone).
    for (final exercise in catalog) {
      final id = exercise.id;
      final easierId = exercise.easierVariationId;
      final harderId = exercise.harderVariationId;

      if (easierId == id || harderId == id) {
        error(id, 'progression.no_self_link', 'exercise links to itself');
      }

      _validateLink(
        exercise: exercise,
        linkId: easierId,
        direction: 'easier',
        byId: byId,
        error: error,
        warning: warning,
      );
      _validateLink(
        exercise: exercise,
        linkId: harderId,
        direction: 'harder',
        byId: byId,
        error: error,
        warning: warning,
      );

      // Reciprocal links where both ends exist in families.
      if (harderId != null && harderId != id) {
        final harder = byId[harderId];
        if (harder != null &&
            harder.active &&
            exercise.active &&
            harder.easierVariationId != id) {
          error(
            id,
            'progression.reciprocal',
            'harder link "$harderId" does not link back with '
            'easierVariationId "$id"',
          );
        }
      }
      if (easierId != null && easierId != id) {
        final easier = byId[easierId];
        if (easier != null &&
            easier.active &&
            exercise.active &&
            easier.harderVariationId != id) {
          error(
            id,
            'progression.reciprocal',
            'easier link "$easierId" does not link back with '
            'harderVariationId "$id"',
          );
        }
      }
    }

    // Cycle detection over harder links.
    for (final exercise in catalog) {
      final visited = <String>{exercise.id};
      var cursorId = exercise.harderVariationId;
      while (cursorId != null) {
        if (!visited.add(cursorId)) {
          error(
            exercise.id,
            'progression.no_cycles',
            'harder-variation chain starting here revisits "$cursorId"',
          );
          break;
        }
        cursorId = byId[cursorId]?.harderVariationId;
      }
    }
    for (final exercise in catalog) {
      final visited = <String>{exercise.id};
      var cursorId = exercise.easierVariationId;
      while (cursorId != null) {
        if (!visited.add(cursorId)) {
          error(
            exercise.id,
            'progression.no_cycles',
            'easier-variation chain starting here revisits "$cursorId"',
          );
          break;
        }
        cursorId = byId[cursorId]?.easierVariationId;
      }
    }
  }

  static void _validateLink({
    required Exercise exercise,
    required String? linkId,
    required String direction,
    required Map<String, Exercise> byId,
    required void Function(String, String, String) error,
    required void Function(String, String, String) warning,
  }) {
    if (linkId == null) {
      return;
    }
    final id = exercise.id;
    final fieldLabel =
        direction == 'easier' ? 'easierVariationId' : 'harderVariationId';
    final target = byId[linkId];
    if (target == null) {
      error(
        id,
        'progression.${direction}_resolves',
        '$fieldLabel "$linkId" does not exist',
      );
      return;
    }
    if (!target.active) {
      error(
        id,
        'progression.${direction}_resolves',
        '$fieldLabel "$linkId" is not active',
      );
      return;
    }

    final familyId = exercise.progressionFamilyId;
    if (familyId == null) {
      // A link without a family is intentionally ignored by the resolver;
      // flag it so catalog authors can decide whether the link is dead.
      warning(
        id,
        'progression.standalone_link',
        '$direction link without a progressionFamilyId is ignored by the '
        'resolver',
      );
      return;
    }
    if (target.progressionFamilyId != familyId) {
      error(
        id,
        'progression.${direction}_same_family',
        '$direction link "$linkId" belongs to family '
        '"${target.progressionFamilyId ?? '<none>'}" instead of '
        '"$familyId"',
      );
      return;
    }
    if (direction == 'easier' &&
        target.progressionRank >= exercise.progressionRank) {
      error(
        id,
        'progression.easier_rank_lower',
        'easier link "$linkId" (rank ${target.progressionRank}) must have a '
        'lower rank than ${exercise.progressionRank}',
      );
    }
    if (direction == 'harder' &&
        target.progressionRank <= exercise.progressionRank) {
      error(
        id,
        'progression.harder_rank_higher',
        'harder link "$linkId" (rank ${target.progressionRank}) must have a '
        'higher rank than ${exercise.progressionRank}',
      );
    }
  }

}
