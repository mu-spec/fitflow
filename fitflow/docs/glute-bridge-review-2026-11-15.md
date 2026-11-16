# Glute Bridge review

Approved and integrated 15 November 2026. Eighteen of 25 animations are approved
and integrated. No APK built.

tools/squat_sample/publish_bridge.py published the exact approved pelvis/arms
revision and matching poster. Only approval metadata and name changed. The
other 24 animation/poster pairs were hash-verified unchanged. All three
targeted launch25 integration tests passed.

Latest correction after the 1.07.31 PM video (7.50 seconds): the old waist-based
rotation and translated shorts moved the garment independently of the thigh.
The leg now pivots at the source hip landmark. Two copies of the original
shorts paths are clipped into overlapping pelvis/thigh regions: pelvis follows
the torso and thigh follows the leg. Path coordinates and part scales are
unchanged, with explicit masks controlling their overlap. This replaces the
earlier waistband-translation approach described below.

Hands are brought closer to the hips using a relaxed bent-elbow pose. Original
arm segment lengths and hand outlines are retained rather than shortened.
The targeted renderer passed. Across 80 poses, the pelvis shares the torso
transform, head/hands/shoes stay fixed, and the loop closes exactly. Original
source-shape and unchanged-installed-assets assertions also passed.
Latest preview: build/bridge-review/bridge_glute-pelvis-arms-revised.gif

Knee follow-up: calibrated the calf attachment within its original overlapping
cap separately from the thigh attachment. Original vector outlines and rigid
part sizes remain unchanged. The far leg uses a small vertical depth offset;
shorts panels share the front waistband placement to avoid a projecting flap.
Targeted render passed after the changes; 40-frame output and key poses reviewed.
Latest preview: build/bridge-review/bridge_glute-knees-revised.gif

Video correction: the owner's 12.57.09 PM recording shows Glute Bridge, despite
the message naming Hip Hinge. Sampled the 9.96-second recording through repeated
cycles. The fixed head previously separated from the rotating neck/neckline;
all three now use the same resting transform. The far shorts panel now shares
the near waistband placement, removing its projecting edge. All original
shape paths remain unchanged. The targeted 40-frame render passed after both
corrections and its contact sheet was inspected. Installed assets were not
modified. Revised preview: build/bridge-review/bridge_glute-connections-fixed.gif

Original Military Push Ups vector contours are reposed with rigid transforms.
No muscle outlines are redrawn. The source bent-arm parts are used with arms
resting beside the body. Original near-side parts are reused for the far limbs.
Head, hands and shoes stay fixed while the torso rotates about the shoulders.
Knees are solved using the original segment lengths. The original shorts
panels are translated to meet the shirt hem, preserving their outlines.

The 2.68-second loop matches push-up pacing. The builder verifies exact source
paths, rigid transforms and unchanged installed asset hashes. The targeted
Flutter renderer passed and produced 40 frames and a poster. Contact sheets
were inspected. This is an animation review, not clinical form certification.

Authoring: tools/squat_sample/build_bridge_review.py
Rendering: tools/squat_sample/render_bridge_test.dart
Preview: build/bridge-review/bridge_glute-review.gif
