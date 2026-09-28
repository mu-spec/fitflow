import 'package:fitflow/features/workouts/data/adaptive_progression_evidence_storage.dart';
import 'package:fitflow/features/workouts/domain/adaptive/adaptive_progression_evidence.dart';
import 'package:fitflow/features/workouts/domain/capability_profile.dart';
import 'package:fitflow/features/workouts/domain/movement_pattern.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AdaptiveProgressionEvidenceStorage', () {
    test('empty storage → zero evidence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      for (final p in CapabilityProfile.trainablePatterns) {
        expect(evidence.countFor(p), 0);
      }
    });

    test('save/load round trip', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      var evidence = AdaptiveProgressionEvidence.zero();
      evidence = evidence.withCount(MovementPattern.push, 1);
      evidence = evidence.withCount(MovementPattern.squat, 1);
      await storage.save(evidence);
      final loaded = storage.load();
      expect(loaded.countFor(MovementPattern.push), 1);
      expect(loaded.countFor(MovementPattern.squat), 1);
      expect(loaded.countFor(MovementPattern.pull), 0);
    });

    test('malformed JSON safe', () async {
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey: 'not json',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      expect(evidence.countFor(MovementPattern.push), 0);
    });

    test('unknown movement ignored', () async {
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            '{"version":1,"counts":{"push":1,"unknownPattern":1,"squat":1}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      expect(evidence.countFor(MovementPattern.push), 1);
      expect(evidence.countFor(MovementPattern.squat), 1);
    });

    test('warmup/cooldown ignored', () async {
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            '{"version":1,"counts":{"push":1,"warmup":1,"cooldown":1}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      expect(evidence.countFor(MovementPattern.push), 1);
      // warmup/cooldown not trainable, so countFor returns 0
      expect(evidence.countFor(MovementPattern.warmup), 0);
    });

    test('negative count sanitized', () async {
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            '{"version":1,"counts":{"push":-5}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      expect(evidence.countFor(MovementPattern.push), 0);
    });

    test('excessive count sanitized', () async {
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            '{"version":1,"counts":{"push":5}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      expect(evidence.countFor(MovementPattern.push), 1);
    });

    test('corrupted value does not crash', () async {
      SharedPreferences.setMockInitialValues({
        AdaptiveProgressionEvidenceStorage.evidenceKey:
            '{"version":1,"counts":{"push":"not int","squat":null}}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      final evidence = storage.load();
      expect(evidence.countFor(MovementPattern.push), 0);
      expect(evidence.countFor(MovementPattern.squat), 0);
    });

    test('clear/reset behavior', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = AdaptiveProgressionEvidenceStorage(prefs);
      var evidence = AdaptiveProgressionEvidence.zero().withCount(MovementPattern.push, 1);
      await storage.save(evidence);
      await storage.clear();
      final loaded = storage.load();
      expect(loaded.countFor(MovementPattern.push), 0);
    });
  });
}
