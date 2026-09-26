import 'package:fitflow/features/workouts/domain/capability_level.dart';

/// Reusable user-facing descriptions for capability assessment choices.
///
/// Describes ability without making medical claims.
/// Does not imply Level 5 proves advanced physical performance.
class CapabilityLevelDescription {
  const CapabilityLevelDescription({
    required this.level,
    required this.title,
    required this.description,
  });

  final CapabilityLevel level;
  final String title;
  final String description;

  static const List<CapabilityLevelDescription> all = [
    CapabilityLevelDescription(
      level: CapabilityLevel.level1,
      title: 'Just starting',
      description:
          'Little or no experience with this movement, or only comfortable with very easy versions.',
    ),
    CapabilityLevelDescription(
      level: CapabilityLevel.level2,
      title: 'Basic',
      description:
          'Comfortable with easier versions and learning consistent form.',
    ),
    CapabilityLevelDescription(
      level: CapabilityLevel.level3,
      title: 'Solid',
      description:
          'Comfortable with standard versions of the movement with reasonable control.',
    ),
    CapabilityLevelDescription(
      level: CapabilityLevel.level4,
      title: 'Strong',
      description:
          'Comfortable with challenging variations and higher training demand.',
    ),
    CapabilityLevelDescription(
      level: CapabilityLevel.level5,
      title: 'Advanced',
      description:
          'Comfortable with advanced variations and strong movement control.',
    ),
  ];

  static CapabilityLevelDescription forLevel(CapabilityLevel level) {
    return all.firstWhere((d) => d.level == level);
  }
}

extension CapabilityLevelAssessmentX on CapabilityLevel {
  String get assessmentTitle =>
      CapabilityLevelDescription.forLevel(this).title;

  String get assessmentDescription =>
      CapabilityLevelDescription.forLevel(this).description;
}
