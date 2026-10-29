# Illustrated exercise athletes — credits and license

These illustrations use artwork by Dinh Bui Xuan, published on LottieFiles under
the Lottie Simple License below. The source pages displayed that license when
checked on 2026-10-28. The app-authored character rigs and motion adaptations
were not created, reviewed or endorsed by Dinh Bui Xuan. They are stylized,
approximate demonstrations and have not been validated by a fitness professional.

## Source and changes

- `jumping_jacks.json`: [Jumping Jack](https://lottiefiles.com/free-animation/jumping-jack-Q3NN7cRkd4).
  The public dotLottie was unpacked and its included shoe image embedded in the
  JSON for offline playback. The movement itself was not intentionally changed.
- `pushup_wide.json`: [Wide arm push up](https://lottiefiles.com/free-animation/wide-arm-push-up-KD96z4DT4Y).
  Public dotLottie unpacked to Lottie JSON for offline playback.
- `squat_bodyweight.webp`, `squat_partial.webp`, `squat_tempo.webp`, and
  `squat_pulse.webp`: rendered, narrowed and retimed derivatives of this app's
  existing grounded `bodyweight_squat.json`,
  which is an adaptation of [Jumping squats](https://lottiefiles.com/free-animation/jumping-squats-9hzVV8Ohi6).
  The partial squat loops only a shallow section; the tempo squat descends over
  three seconds, pauses for one second and rises over one second; the pulse
  repeats a small range near the bottom. Their torso and legs were narrowed
  with a smooth image warp; the head and ground-contact area were kept at
  their original width. They are app-authored adaptations: Dinh Bui Xuan did
  not author or endorse these changes. Source and build
  instructions are in `tools/illustrated_athletes/README.md`.

- `squat_chair.webp`: a chair and wall were drawn behind the transparent,
  grounded and narrowed Jumping squats derivative, to show a sit-to-stand.
  The source squat, proportions and timing are locally modified.
- The other newly added exercise WebPs in this folder extract, rotate and
  reposition actual body-part artwork from the same grounded squat source.
  The app narrows the cross-section of the torso and limbs and tapers the hip,
  inspired by the slimmer Jumping Jack artwork. Joint endpoints are retained;
  the result uses squat-source body parts and is not the original Jumping Jack
  figure redrawn for those movements. The set includes 37 animated pose-rig
  demonstrations and nine single-frame
  holds/stretches. They are new app-authored derivatives, not animations
  originally created by Dinh Bui Xuan. Some side views overlap the two limbs or
  weights; poses and grips are approximate and need qualified form review.
- Motion poses are locally authored or adapted from
  [Open Exercise Figures](https://github.com/AbanoubAmir/open-exercise-figures),
  by Abanoub Amir and contributors, pinned to commit
  `a0574d54baaf23f5784dfdebd5c65f6a87fd5194`. Its figures are CC0 1.0;
  its kinematics/rendering code is MIT-0. The source rig identifiers and
  adaptation details are recorded in `tools/illustrated_athletes/README.md`.
  The upstream project did not author or endorse the combined illustrations.
  CC0 text is bundled at `assets/animations/open_exercise_figures/LICENSE-CC0.txt`;
  the MIT-0 text accompanies the authoring tool.

The Lottie Simple License below also applies to the combined and retimed
illustrations, including the chair, equipment and static poses. No competitor
app's media was copied. See the app's other notices for other providers.

## Lottie Simple License (FL 9.13.21)

Source: https://lottiefiles.com/page/license

Copyright © 2021 Design Barn Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of the public animation files available for download at the LottieFiles site (“Files”) to download, reproduce, modify, publish, distribute, publicly display, and publicly digitally perform such Files, including for commercial purposes, provided that any display, publication, performance, or distribution of Files must contain (and be subject to) the same terms and conditions of this license.

Modifications to Files are deemed derivative works and must also be expressly distributed under the same terms and conditions of this license. You may not purport to impose any additional or different terms or conditions on, or apply any technical measures that restrict exercise of, the rights granted under this license. This license does not include the right to collect or compile Files from LottieFiles to replicate or develop a similar or competing service.

Use of Files without attributing the creator(s) of the Files is permitted under this license, though attribution is strongly encouraged. If attributions are included, such attributions should be visible to the end user.

FILES ARE PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. EXCEPT TO THE EXTENT REQUIRED BY APPLICABLE LAW, IN NO EVENT WILL THE CREATOR(S) OF FILES OR DESIGN BARN, INC. BE LIABLE ON ANY LEGAL THEORY FOR ANY SPECIAL, INCIDENTAL, CONSEQUENTIAL, PUNITIVE, OR EXEMPLARY DAMAGES ARISING OUT OF THIS LICENSE OR THE USE OF SUCH FILES.
