import 'dart:math' as math;

import 'package:fitflow/core/design/fitflow_radius.dart';
import 'package:fitflow/core/design/fitflow_theme_extension.dart';
import 'package:fitflow/core/design/media/exercise_media_spec.dart';
import 'package:flutter/material.dart';

/// Shared local-image frame. No catalog, provider, network, or painter access.
/// Dimensions are reserved even when an asset is missing or still decoding.
class FitFlowMediaImage extends StatelessWidget {
  const FitFlowMediaImage({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    this.decorative = true,
    this.semanticLabel,
  })  : assert(width > 0 && width < double.infinity),
        assert(height > 0 && height < double.infinity),
        assert(decorative || (semanticLabel != null && semanticLabel != ''));

  final FitFlowMediaAsset? asset;
  final double width;
  final double height;

  /// Adjacent exercise/program text should normally own the semantics.
  final bool decorative;

  /// Supplied/localized by the caller. Also describes the neutral fallback;
  /// avoid wording that claims a photo is available.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FitFlowTheme.of(context);
    final placeholder = ColoredBox(
      key: const ValueKey('fitflow_media_placeholder'),
      color: colors.subtleSurface,
      child: Center(
        child: Icon(Icons.fitness_center_outlined,
            size: math.min(28, math.min(width, height) / 2),
            color: colors.textMuted),
      ),
    );
    final frame = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: FitFlowRadius.mediumBorder,
        child: ColoredBox(
          color: colors.subtleSurface,
          child: LayoutBuilder(builder: (context, constraints) {
            final media = asset;
            if (media == null || constraints.biggest.isEmpty) {
              return placeholder;
            }
            final pixels =
                constraints.biggest * MediaQuery.devicePixelRatioOf(context);
            final fitted = applyBoxFit(
                media.fit,
                Size(media.pixelWidth.toDouble(), media.pixelHeight.toDouble()),
                pixels);
            // Quantize decode sizes to avoid a new cache entry for every small
            // resize. Preserve the source aspect ratio and never upscale decode.
            final ratio = math.max(
              fitted.destination.width / fitted.source.width,
              fitted.destination.height / fitted.source.height,
            );
            final decodeWidth = math.min(media.pixelWidth,
                math.max(1, (media.pixelWidth * ratio / 64).ceil() * 64));
            final decodeHeight = math.max(1,
                (decodeWidth * media.pixelHeight / media.pixelWidth).round());
            return Image.asset(
              media.path,
              key: ValueKey(media.path),
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: media.fit,
              alignment: media.alignment,
              cacheWidth: decodeWidth,
              cacheHeight: decodeHeight,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              gaplessPlayback: false,
              frameBuilder: (_, child, frame, synchronouslyLoaded) =>
                  synchronouslyLoaded || frame != null ? child : placeholder,
              errorBuilder: (_, __, ___) => placeholder,
            );
          }),
        ),
      ),
    );
    return Semantics(
      container: !decorative,
      label: decorative ? null : semanticLabel,
      excludeSemantics: true,
      child: frame,
    );
  }
}
