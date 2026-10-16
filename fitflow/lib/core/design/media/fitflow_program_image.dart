import 'package:fitflow/core/design/media/fitflow_media_image.dart';
import 'package:fitflow/core/design/media/program_media_registry.dart';
import 'package:flutter/material.dart';

/// Program identity only; this image never selects a workout or exercise.
class FitFlowProgramImage extends StatelessWidget {
  const FitFlowProgramImage({
    super.key,
    required this.programId,
    this.width = 320,
    this.height = 240,
    this.decorative = true,
    this.semanticLabel,
  });

  final String programId;
  final double width;
  final double height;
  final bool decorative;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => FitFlowMediaImage(
        asset: ProgramMediaRegistry.lookup(programId)?.cover,
        width: width,
        height: height,
        decorative: decorative,
        semanticLabel: semanticLabel,
      );
}
