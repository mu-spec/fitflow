import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_spacing.dart';

/// Existing spacing names, now backed by the design-system scale.
class AppDimens {
  const AppDimens._();

  static const double radiusSmall = FitFlowRadius.small;
  static const double radiusMedium = FitFlowRadius.medium;
  static const double cardRadius = FitFlowRadius.card;
  static const double screenPadding = FitFlowSpace.screenHorizontal;
  static const double itemGap = FitFlowSpace.list;
}
