# Knee Plank and Forearm Plank previews

Status: approved and integrated 15 November 2026. Sixteen of 25
exercises are approved and integrated. No APK built.

The latest previews use Military Push Ups artwork by Dinh Bui Xuan under the
bundled Lottie Simple License. The joined-arm redraw has been removed.
Shoulder, upper-arm and forearm parts come directly from the original held
bottom pose (frame 31), including its authored muscle curves. They are reposed
without redrawing their contours. Original hand parts are repositioned at the
wrists. Head, torso, clothing, legs and camera retain the prior setup.
Knee Plank retains the approved fuller supported-knee contours.

Both show isometric holds with subtle shirt expansion for breathing. Elbows
stay within the shoulder footprint and forearms remain horizontal. The 2.68s
display loop does not change the prescribed workout hold duration.

Validation: arm path equality against the original bent-arm pose, other source
path equality except approved knee contours, retained arm segment lengths,
horizontal forearms and unchanged installed asset hashes. The targeted plank
render test passed (40 frames per candidate, posters and 4x elbow renders).
Rendered joint views were inspected. No broad suite or APK build.

Authoring: tools/squat_sample/build_plank_review.py
Rendering: tools/squat_sample/render_plank_test.dart
Packaging: tools/squat_sample/package_plank_review.py
Latest previews:
- build/plank-pair-review/plank_knee-source-muscles.gif
- build/plank-pair-review/plank_forearm-source-muscles.gif

Integration: tools/squat_sample/publish_plank_pair.py copied both reviewed
compositions and matching posters into assets/animations/launch25. Motion and
artwork match the approved candidates; only approval metadata changed. All
other 23 JSON/poster pairs were hash-verified unchanged. The three targeted
launch25 tests passed, covering catalog/posters, preserved push-up source and
pause/reduced-motion behavior. No APK built.
