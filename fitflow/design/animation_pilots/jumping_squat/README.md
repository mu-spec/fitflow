# Grounded Bodyweight Squat adaptation

The user selected adapting their Jumping_squats.json into the existing non-jumping Bodyweight Squat, rather than adding Jump Squat to the catalog.

Source: Jumping_squats by Dinh Bui Xuan, https://lottiefiles.com/free-animation/jumping-squats-9hzVV8Ohi6
The exact-name page lists 87.3 KB Lottie JSON and the Lottie Simple License. The initially supplied Squat kicks and Split Jump links described different movements. License and attribution are retained in assets/animations/BODYWEIGHT_SQUAT_LICENSE.md and bundled with the derivative.

source.json preserves the supplied file unchanged. Its loopOut('pingpong') expression did not loop in the Flutter renderer: the character held the airborne pose. jump_squat_loop.json is an isolated loop repair study, not an app asset or catalog entry.

bodyweight_squat.json reuses the character artwork and ground/standing poses, removes flight displacement and fixes both original shoes at constant transforms. The lower-body transforms follow the fixed ankle contacts while the torso lowers and rises. Expressions are baked into explicit keyframes. The resulting 720 x 720 Lottie loops in 2.5 seconds. The original source is never overwritten.

App mapping: squat_bodyweight -> assets/animations/bodyweight_squat.json.
The previous procedural Player squat pilot is no longer selected. The remaining marching pilot is unchanged. Shared exercise hero and thumbnail rendering handles this animation everywhere it is used, with existing pause, reduced-motion, loading/error fallback and offscreen behavior. No catalog definitions, eligibility, prescriptions or workout timing are changed.

Rebuild:
1. python design/animation_pilots/jumping_squat/build_bodyweight.py
2. Copy the generated bodyweight_squat.json to assets/animations/bodyweight_squat.json.
3. flutter test --no-pub design/animation_pilots/jumping_squat/render_bodyweight_test.dart
4. python design/animation_pilots/jumping_squat/package_preview.py

The render test verifies published/review bytes match, feet have static unparented transforms and static artwork, and the rendered loop closes on an identical pose with a distinct squat midpoint. Focused app tests cover shared hero/thumbnail usage, both themes, reduced motion, pause/rest/background handling and unchanged session state. Device visual/performance review remains needed. No APK/AAB was built.
