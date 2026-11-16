# Exercise character refinement — 10 November 2026

## Applied changes

- Corrected the torso's source garment landmarks rather than positioning the shirt with the near arm/leg pivots. This reduces shirt intrusion behind the head.
- Restored the original chest/collar artwork and positioned the head independently with consistent neck clearance.
- Replaced the press-specific shorts outlines with connected rounded hip silhouettes for bent-leg poses.
- Reduced far-side perspective offsets to limit detached-looking shoulder caps and overlaps.
- Improved knee push-up start extension and separated the limbs in the reverse snow angel overhead view.
- Retained original vector head, hand, arm and shoe artwork in the side-view adaptations. Front-view arm circles and step jacks continue to use the original Jumping Jack character artwork.
- Refreshed the 20 adapted animation assets and their still posters. The five approved motion files were verified byte-identical; hashes are in `build/character-refinement/preserved-original-hashes.json`.

## Verification

- Rendered 24 frames throughout each of 25 animation cycles using Flutter/Lottie. The review renderer now decodes embedded shoe images, avoiding misleading shoeless previews.
- Inspected multiple poses across the full catalog, including squat depth, floor poses and overhead limb separation.
- 94 focused animation/player tests passed. Updated obsolete raster-frame checks to test actual Lottie progress and poster fallback. Pause, resume, background behavior, reduced motion and responsive layouts are covered.
- Previous adapted assets are backed up in `build/character-refinement/previous-assets`.

## Limits

These remain locally authored adaptations, not new originals by the reference animator. Visual resemblance is improved but not guaranteed to be identical. Frame rendering and automated checks do not establish professional exercise-form approval or user acceptance. Full-device visual review is still needed, particularly for the stylized overhead reverse snow angel and cat-cow.

Review animation: `build/character-refinement/character-review.gif`.
