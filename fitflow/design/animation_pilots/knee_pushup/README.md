# Knee Push-Up animation pilot

Status: approved by the user. This folder preserves the original four-second review pilot. The published asset in assets/animations/knee_pushup.json uses the identical geometry at 2.5 seconds; see ../pushup_variants/README.md for integration. This design folder is not bundled.

Source artwork: Military Push Ups by Dinh Bui Xuan
https://lottiefiles.com/free-animation/military-push-ups-sFmjfnsBQ9
Source confirmed by the user on 2026-10-27.
Source SHA-256: 0b9707d916984d464748935502780453d5c552b8595d69dfd4c6501f5d98db97

The original vector drawings are reused in a new knee-supported motion rig. Hands and lower legs remain fixed; the upper body moves around supported knees, with two-bone arm positioning. This is a manually reviewed experimental adaptation, not a new source-author release. Visual quality must be approved before app use; no prescription or exercise rule is changed.

Files:
- knee_pushup_pilot.json: derivative Lottie, 720 x 720, 25 fps, 4-second loop.
- preview.gif: rendering of that exact Lottie in Flutter for visual review.
- build_pilot.py: deterministic generator; refuses a changed source file.
- render_pilot_test.dart: renders all frames and checks loop closure.
- LICENSE.md: same license terms as the source and attribution.

Rebuild from the Flutter project root:
    python design/animation_pilots/knee_pushup/build_pilot.py
    flutter test --no-pub design/animation_pilots/knee_pushup/render_pilot_test.dart
    python design/animation_pilots/knee_pushup/package_preview.py

No additional dependency or APK build was needed. The separate published asset is now mapped to pushup_knee.
