# Push-up animation batch

Knee Push-Up was approved by the user. Its published loop is now 2.5 seconds (40 fps for 100 frames), instead of the original review pilot's four seconds. Geometry is unchanged. Incline and Decline Push-Up reuse the same licensed vector character with separately posed bodies, two-bone arm positioning, stationary hands/feet and visible bench support. Their loops are also 2.5 seconds. These are source-derived adaptations, not releases by the original artist.

Published assets:
- assets/animations/knee_pushup.json -> pushup_knee
- assets/animations/pushup_incline.json -> pushup_incline
- assets/animations/pushup_decline.json -> pushup_decline

The central ExerciseAnimationRegistry exposes these exact IDs through the existing shared hero/thumbnail renderer. No other exercise is substituted. The original three Lotties remain unchanged. There are now six Lottie mappings in the 88-exercise catalog; this is not a complete animation rollout. Existing media fallbacks remain available, including for reduced motion and asset errors. Session timing, rep counts and prescriptions do not follow demonstration speed.

The new bench variants were rendered over their complete loops, visually inspected at raised/intermediate/lowered positions, and checked for identical start/end frames. Device review is still needed. The old two-exercise procedural Player pilot is outside this batch and is unchanged.

Rebuild from the project root:
1. python design/animation_pilots/pushup_variants/build_variants.py
2. python design/animation_pilots/pushup_variants/publish_assets.py
3. flutter test --no-pub design/animation_pilots/pushup_variants/render_variants_test.dart
4. python design/animation_pilots/pushup_variants/package_previews.py

package_previews.py also uses the existing knee review render frames. Preview GIFs alternate 20/30 ms frames to reproduce the 2.5-second Lottie loop despite GIF's 10 ms time resolution.

License/source: Military Push Ups by Dinh Bui Xuan, https://lottiefiles.com/free-animation/military-push-ups-sFmjfnsBQ9
Derivative terms and attribution: assets/animations/PUSHUP_ADAPTATIONS_LICENSE.md. Original source assets and all photographs are untouched.

Remaining movements require their own appropriate rigs, support/equipment drawings and review. Rotating or relabeling a push-up cannot accurately demonstrate squats, lunges, pulling exercises and the rest of the catalog.
