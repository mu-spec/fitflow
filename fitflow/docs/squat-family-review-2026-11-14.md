# Partial Squat and Chair Sit-to-Stand review

Status: approved and integrated into app assets on 14 November 2026.
The owner requested implementation without building an APK.

Both candidates resample the approved chest-hands Bodyweight Squat asset.
The head, torso, arm and hand contours are unchanged. Shoe transforms remain
fixed. Partial Squat uses 32 source-coordinate units of vertical travel versus
68 for the approved squat. Chair Sit-to-Stand starts seated, includes seated
and standing pauses, and returns slowly to a stationary chair.

Authoring: `tools/squat_sample/build_family_review.py`.
Rendering: `tools/squat_sample/render_family_test.dart`.
Packaging: `tools/squat_sample/package_family_review.py`.

Preview: `build/squat-family-review/partial-and-chair-review.gif`.
Candidate JSON files and verification report are in the same directory.
The approved source SHA-256 is embedded in each candidate's metadata.

Validation: Flutter rendered both full loops at 12 samples/second (48 and 72
frames). The source-contour and fixed-shoe assertions passed. Standing, seated,
intermediate and shallow-bottom poses were visually inspected. Front-view
artwork does not show sagittal trunk lean clearly; no clinical form validation
is claimed.

## Integration

Replaced the Partial Squat and Chair Sit-to-Stand compositions and their 720px
posters in `assets/animations/launch25`. Existing shared registry entries serve
the new artwork in the library, details, preview, player and skill paths.
Published motion data is identical to the reviewed candidates; only display
names and approval metadata changed. All other 23 animation/poster pairs are
byte-identical to their pre-publish versions. Backups and hashes are stored in
`build/squat-family-review/before-publish`.

The batch generator preserves all three approved squat-family compositions.
Eight of the 25 exercise demonstrations now have owner-approved artwork and
motion; the other 17 adaptations still await refinement and visual review.
The 94 focused animation/player tests passed after integration. No APK was built.

## Hand-position check

The owner accepted the character artwork and requested verification of the hand
positions. In both previews the hands remain together in front of the chest,
with bent elbows, without pushing on the knees or chair. This is an appropriate
unassisted option; arm swinging is not required. Retain this pose.

- Cleveland Clinic's air-squat instructions allow hands together as an
  alternative to crossed arms: https://health.clevelandclinic.org/quad-exercises
- NARI's sit-to-stand Level 2 allows arms in front of the body or crossed over
  the chest: https://www.nari.net.au/FAQs/qr-sit-to-stand

This check supports the arm-position choice, not independent validation of all
exercise mechanics. The chair animation depicts the unassisted variation.
