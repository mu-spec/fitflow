# FitFlow motion audit

**Date:** 28 October 2026  
**Scope:** the current local `arena-workouts-redesign` checkout, not necessarily the code already pushed to GitHub.  
**Verdict:** the present demonstrations cannot honestly be certified as correct. The user rejected the earlier motion quality except Jumping Jacks, then approved the **look** of a real-person Bodyweight Squat pilot. These visual preferences are not fitness-professional sign-offs.

> **Release warning:** after the original audit, exactly one assignment (`squat_bodyweight`) was replaced locally with the user-preferred real-person pilot. The default visual gate now shows only that squat and the original Jumping Jack; the other candidate mappings are retained but hidden behind an explicit inspection flag. Neither preferred visual has professional form sign-off; the squat's likeness/publicity rights have not been independently confirmed. Still-image fallbacks also have not been comprehensively validated. Do not present these as verified coaching guidance or publicly release the squat pilot before the outstanding checks.

## What was checked

- The actual app catalog contains 88 exercises, all with written instructions. The registry assigns 59 distinct media assets: 50 moving loops and nine one-frame stills for hold exercises. The other 29 use photo fallbacks; those photos were not form-validated here.
- In the original audit, for each of 43 animated WebP assets, 12 points distributed over the loop time were visually examined against that exercise’s own instructions. Holds can cause repeated frames in a time-spaced sample. For each of the six non-Jumping-Jack Lotties, 20 timeline positions were visually examined; 25 positions across Jumping Jacks were checked. Each of the nine static poses was inspected as a still, not as an animation. The subsequent replacement squat clip was separately inspected frame-by-frame (68 frames), without professional sign-off.
- In that original snapshot, all 1,906 decoded WebP frames, including stills, were scanned with a coarse pixel-difference check for end-to-start discontinuities. No WebP loop seam exceeded the median difference between its consecutive frames by that metric. For the replacement squat, the 120-pixel RGB comparison gave a seam mean of 2.64 versus a 3.37 median consecutive-frame mean. These metrics do **not** establish smooth joints, correct technique, safety, or absence of clipping. Lottie loops were sampled visually, not subjected to that WebP calculation.
- Knee/foot and hand/equipment contact, timing, transitions, side alternation and the limitations of the camera angle were considered. Ground-line gaps are recorded as **visual artifacts**; a 3/4 perspective can make an apparent gap ambiguous. A visible artifact is not automatically a medical conclusion.
- The user’s visual rejection applies even to entries where a particular biomechanical defect could not be established. “Not verified” does not mean “passed.” The report is a targeted inspection, not a clinical assessment or proof that every intermediate pose is correct.
- Full asset and catalog SHA-256 values are recorded in `tools/illustrated_athletes/motion_audit_2026_10_28.json`. `python3 tools/illustrated_athletes/test_motion_audit_consistency.py` detects stale hashes or coverage; it is not a form test.

## Default visual safeguard and inspection flags

By default the app selects only the user's two preferred visuals: the original `jumping_jacks` and the real-person `squat_bodyweight`. The other 86 catalog exercises use existing still-image fallbacks while better demonstrations are sourced and reviewed. The workout player and exercise detail screen label policy-selected and reduced-motion stills as such. This is an interim safeguard, **not** completion of a consistent animation library or validation of the stills.

For developer inspection of the older candidates only:

```sh
flutter run --dart-define=FITFLOW_SHOW_UNREVIEWED_MOTION=true
```

The older, stricter flag remains available and takes precedence, even if both flags are true. It selects only the Jumping Jack and uses a still from the squat for Bodyweight Squat:

```sh
flutter run --dart-define=FITFLOW_JUMPING_JACK_ONLY=true
```

Both flags are compile-time choices. Without either flag, the two-visual default applies. The candidate assets and mappings, exercises, instructions, prescriptions and workout clock are preserved. Opting in to old candidates does not make them approved for release. Neither user's visual preference is a professional form certification.

### Additional fallback check

On 28 October I inspected overview sheets of all 88 then-registered hero images and individually looked at representative larger files. The squat fallback has since been replaced with a still from the real-person pilot. Each shows a single pose; a still cannot communicate movement direction, repetitions, setup, transitions, or tempo. It cannot replace the requested animated demos. Their form, provenance and suitability as coaching guidance were not comprehensively verified, and the people/styles are inconsistent.

`test/motion_fallback_integrity_test.dart` checks that all 88 catalog IDs have bundled hero and thumbnail stills and each decodes as a one-frame image. The gate and the player's special push-up path are checked under the default, inspection and Jack-only modes; a policy-only test also checks that Jack-only overrides the inspection flag. These are technical routing and decoding checks, not visual or biomechanical approval. With reduced motion enabled, the shared renderer also selects the still fallback; that behavior is not evidence of correct form.

## The most important findings

1. **Knee clipping:** Bird Dog’s supporting knee and Mountain Climbers’ moving knee visibly extend below the drawn floor in sampled frames. The existing builder tests check joint centres, which can miss the edge of a rendered limb.
2. **Foot contact:** several side-view animations, including glute bridges, split squats and lunges, depict a supporting shoe floating above the drawn floor; the chair squat’s farther foot is also ambiguous. These are visual-contact defects, not proof about a real person’s biomechanics.
3. **Exercise mismatch:** Mountain Climbers uses planted-foot transitions instead of the app’s specified small hop. Cobra repeats a high backbend rather than demonstrating the app’s small lift and 20-second hold.
4. **Equipment and grip:** the towel row does not clearly show a towel loop and two grips; bar hangs use open fingers across the bar; goblet-squat and kettlebell drawings do not convincingly show the specified hand grips.
5. **Knee alignment cannot be signed off:** most generated poses are side-on and their legs overlap. They cannot establish frontal knee-to-toe tracking or whether both feet are loaded. A knee moving beyond the toes is not by itself proof of incorrect form [11](https://www.acefitness.org/resources/everyone/blog/562/is-it-ever-okay-for-your-knees-to-extend-beyond-your-toes-while-doing-squats-or-lunges/).

## How to read the assessment

- **VISIBLE ISSUE / MISMATCH:** a specific drawing artifact or difference from the catalog text was observed; it is not necessarily a diagnosis of unsafe biomechanics.
- **NOT VERIFIED:** the media suggests part of the movement, but important details are obscured or have not been independently established. The user rejected the earlier candidates, except the original Jumping Jacks; later visual approval of the real-person squat did not establish form correctness.
- **STATIC HOLD:** a single pose, appropriate in principle for an isometric exercise, but it does not show setup, exit or a side change.
- **USER-PREFERRED REFERENCE:** Jumping Jacks only; this records the user’s visual preference, not professional approval.

Across the 59 mapped IDs, the individual labels are 23 visible-issue entries, 27 unverified entries, 8 other static-hold entries and 1 user-preferred reference. Dead Hang is the ninth static hold and is counted under visible issues because its grip is unclear.

## Exercise-by-exercise comparison — all 59 mapped IDs

### Wall Push-Up (`pushup_wall`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/pushup_wall.webp` (25-frame WebP; 1742 ms loop; SHA-256 `ab41b8d165ca7e20…`).
- **App instructions:**
  - Face a solid wall and place palms at shoulder height, slightly wider than shoulders.
  - Step back, brace your trunk, and bend elbows about 45 degrees from your sides to bring your chest toward the wall.
  - Press away smoothly while keeping head, hips, and heels aligned.
- **Observed:** The figure bends and presses against a wall.
- **Not established:** The side view hides hand spacing and the specified elbow angle; palm contact and body alignment need closer review.

### Incline Push-Up (`pushup_incline`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/pushup_incline.json` (Lottie; 100 source frames; approximately 2.50 s; SHA-256 `c25bc69d65fcfc9a…`).
- **App instructions:**
  - Use a sturdy, non-slip bench secured against movement; grip its edge slightly wider than shoulders.
  - Walk feet back into a straight plank and lower your chest toward the edge with elbows angled back.
  - Press back up without letting hips sag.
- **Observed:** The hands lie flat on the bench top rather than clearly gripping its edge, as the instructions specify.
- **Not established:** The depiction cannot establish bench stability, hand pressure, or exact elbow angle.

### Knee Push-Up (`pushup_knee`) — NOT VERIFIED

- **Current asset:** `assets/animations/knee_pushup.json` (Lottie; 100 source frames; approximately 2.50 s; SHA-256 `37a5e14beff54436…`).
- **App instructions:**
  - Place hands slightly wider than shoulders and knees on a comfortable surface.
  - Keep a straight line from head through hips to knees as you lower your chest.
  - Press up with elbows angled back, keeping your trunk braced.
- **Observed:** A knee-supported lowering and press is visible.
- **Not established:** The view does not establish both hands' spacing or the exact elbow angle; head–hip–knee alignment needs professional review.

### Standard Push-Up (`pushup_standard`) — NOT VERIFIED

- **Current asset:** `assets/animations/pushup.json` (Lottie; 67 source frames; approximately 2.68 s; SHA-256 `0b9707d916984d46…`).
- **App instructions:**
  - Set hands just wider than shoulders and extend legs with toes on the floor.
  - Brace your trunk and lower your chest with elbows roughly 45 degrees from your sides.
  - Press to straight arms while keeping the body in one line.
- **Observed:** The original Lottie shows a lowering and press with legs extended.
- **Not established:** Elbow angle and depth cannot be reliably measured from this stylized angle. The user rejected its motion quality.

### Decline Push-Up (`pushup_decline`) — NOT VERIFIED

- **Current asset:** `assets/animations/pushup_decline.json` (Lottie; 100 source frames; approximately 2.50 s; SHA-256 `fc20d1d7e7be6eca…`).
- **App instructions:**
  - Secure a low, stable bench and place your toes on it with hands on the floor.
  - Brace in a straight line and lower your chest between your hands without arching your back.
  - Press up under control; step down carefully to finish.
- **Observed:** The original Lottie lowers and presses with the feet on a raised bench.
- **Not established:** Exact body alignment, elbow angle, and secure toe contact are not independently verified.

### Chair Sit-to-Stand (`squat_chair`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/squat_chair.webp` (83-frame WebP; 3760 ms loop; SHA-256 `1a0dc35aaa94b1e8…`).
- **App instructions:**
  - Secure a firm chair against a wall and sit near the front with feet hip-width apart.
  - Lean your torso forward slightly and press through both feet to stand without using your hands.
  - Send hips back and bend knees to sit gently, keeping knees in line with toes.
- **Observed:** The figure lowers toward a chair, but the farther shoe appears above the single floor line even during the seated portion; hip-to-seat contact is visually ambiguous.
- **Not established:** The view cannot establish that both feet are grounded or that the knees track over the toes. The apparent shoe gap may also be affected by the 3/4 perspective.

### Partial Squat (`squat_partial`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/squat_partial.webp` (49-frame WebP; 2800 ms loop; SHA-256 `9917ab75c2007bba…`).
- **App instructions:**
  - Stand with feet about shoulder-width apart and toes slightly turned out.
  - Send hips back and bend knees through a shallow, comfortable range, keeping heels down.
  - Push through your feet to stand tall without snapping the knees.
- **Observed:** The loop uses a shallow range and returns to standing.
- **Not established:** The warped 3/4 drawing makes knee shape, two-foot pressure and knee-over-toe tracking hard to judge; a shallow range alone is not form validation.

### Bodyweight Squat (`squat_bodyweight`) — NOT VERIFIED

- **Current local pilot:** `assets/animations/real_people/squat_bodyweight.webp` (68-frame WebP; 2720 ms loop; SHA-256 `02841952bcf76665…`). The user approved the real-person look after viewing the complete loop; that is not professional approval of form.
- **App instructions:**
  - Stand with feet around shoulder-width apart and brace your trunk.
  - Bend hips and knees together, tracking knees over toes and keeping the whole foot grounded.
  - Lower only as far as you can control, then drive through your feet to stand.
- **Observed:** A full-body real person bends hips and knees and returns to standing without exercise equipment. All 68 frames were inspected; a still from this footage is used for reduced motion and failure fallback.
- **Not established:** This side view cannot prove tracking for both knees or complete foot contact, nor whether the displayed depth is suitable for every user. No qualified professional has verified the movement. The source is identified as CC BY-SA 4.0, but the depicted person's likeness/publicity rights remain unverified; review before public release.
- **Historical audit:** the previous narrowed illustration (`assets/animations/illustrated_athletes/squat_bodyweight.webp`, 59 frames, 2500 ms, SHA-256 `e85e8040bba75ea3…`) was not verified because it did not show both knees and feet clearly. Its original finding is preserved in the audit JSON.

### Tempo Squat (`squat_tempo`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/squat_tempo.webp` (99-frame WebP; 5200 ms loop; SHA-256 `a831c01d36cb1dad…`).
- **App instructions:**
  - Set your squat stance and brace with weight spread across each foot.
  - Lower for three seconds to a comfortable depth, then pause for one second without relaxing.
  - Stand smoothly in about one second and reset before the next repetition.
- **Observed:** The authoring timeline encodes about three seconds down, one second at the bottom and one second up, plus a reset.
- **Not established:** Correct timing is not evidence of correct knee tracking, foot pressure or depth.

### Wall Sit (`wall_sit`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/wall_sit.webp` (single-frame hold; SHA-256 `5ff39e5b50ee0268…`).
- **App instructions:**
  - Lean your back against a solid wall and walk feet forward about hip-width apart.
  - Slide down to a comfortable bend, no deeper than thighs parallel, with knees above ankles.
  - Hold with back supported and hands off thighs; slide up slowly to finish.
- **Observed:** One static wall-supported bent-knee pose is displayed; there is no entry or exit animation.
- **Not established:** The still cannot show the slide, knee tracking or loading of both feet.

### Dead Bug (`dead_bug`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/dead_bug.webp` (60-frame WebP; 4556 ms loop; SHA-256 `f8ff69729724450f…`).
- **App instructions:**
  - Lie on your back with arms above shoulders and hips and knees bent to right angles.
  - Brace gently; reach one arm overhead and extend the opposite leg only as far as you can keep your lower back from arching.
  - Return slowly and switch sides; the default is eight repetitions per side.
- **Observed:** The rig alternates an arm with the opposite leg, returning toward the start between sides.
- **Not established:** The overlapping side-view limbs do not make left versus right obvious, and lumbar contact cannot be certified from the illustration.

### Knee Plank (`plank_knee`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/plank_knee.webp` (single-frame hold; SHA-256 `618a9077bd6cc2ac…`).
- **App instructions:**
  - Place forearms on the floor with elbows under shoulders and knees down.
  - Move knees back until head, hips, and knees form a straight line.
  - Brace gently and hold without sinking into the shoulders or arching the back.
- **Observed:** One static forearm-and-knee plank pose is displayed.
- **Not established:** It does not show setup or exit; shoulder placement and the full head–hip–knee line require review.

### Forearm Plank (`plank_forearm`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/plank_forearm.webp` (single-frame hold; SHA-256 `0ae03a0205eff0d4…`).
- **App instructions:**
  - Set elbows beneath shoulders with forearms resting on the floor.
  - Extend both legs onto your toes and align head, hips, and heels.
  - Brace abs and glutes, hold steadily, then lower knees to finish.
- **Observed:** One static forearm plank pose is displayed.
- **Not established:** It does not show entering or leaving the plank; trunk bracing and elbow/shoulder loading cannot be proven by the pose.

### Hollow Hold (`hollow_hold`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/hollow_hold.webp` (single-frame hold; SHA-256 `d517c72018acf7bf…`).
- **App instructions:**
  - Lie on your back, brace your abdomen, and keep your lower back gently against the floor.
  - Lift shoulders and legs, reaching arms overhead; raise legs higher if needed to preserve back contact.
  - Hold without arching, then lower gently; stop the set if you lose back contact.
- **Observed:** One static arms-overhead and legs-raised pose is displayed.
- **Not established:** It cannot demonstrate the setup, safe exit, or whether the lower back stays supported for the hold.

### Glute Bridge (`bridge_glute`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/bridge_glute.webp` (30-frame WebP; 2278 ms loop; SHA-256 `80c8e48d7b42d04d…`).
- **App instructions:**
  - Lie on your back with knees bent, feet hip-width apart, and arms resting at your sides.
  - Press through your feet and squeeze glutes to lift hips until shoulders, hips, and knees align.
  - Pause briefly and lower slowly without arching your lower back.
- **Observed:** The hips rise and lower, but the shoe visibly floats above the drawn ground line at the start and peak.
- **Not established:** The apparent foot contact is misleading; both feet, knee alignment and lumbar position cannot be established from the side view.

### Single-Leg Glute Bridge (`bridge_single_leg`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/bridge_single_leg.webp` (30-frame WebP; 2278 ms loop; SHA-256 `0c69b9e11146b955…`).
- **App instructions:**
  - Lie on your back with knees bent and feet near your hips, then lift one foot clear of the floor.
  - Press through the grounded foot to raise hips while keeping the pelvis level.
  - Lower under control; complete eight repetitions, then switch legs.
- **Observed:** The supporting shoe visibly floats above the ground line. The loop starts with the free leg already straight and shows only one side.
- **Not established:** It does not show the instructed two-bent-knee setup or leg switch; pelvis level and pressure through the planted foot are not verifiable.

### March in Place (`march_in_place`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/march_in_place.webp` (60-frame WebP; 3060 ms loop; SHA-256 `70f224b7cf8d9878…`).
- **App instructions:**
  - Stand tall with feet hip-width apart and relaxed shoulders.
  - Lift one knee to a comfortable height while swinging the opposite arm.
  - Set the foot down softly and alternate at a steady pace, always keeping one foot grounded.
- **Observed:** The figure alternates knee lifts; the authored rig checks for a supporting toe.
- **Not established:** The overlapping limbs obscure opposite-arm swing, soft landing and the alignment of each standing knee. Joint checks do not validate the artwork.

### High Knees (`high_knees`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/high_knees.webp` (30-frame WebP; 1360 ms loop; SHA-256 `b6081346567151f3…`).
- **App instructions:**
  - Stand tall and begin a light run in place with bent elbows.
  - Drive alternating knees toward hip height only as far as you can control, with quick arm swings.
  - Land softly under your hips with slightly bent knees; slow to a march to finish.
- **Observed:** Alternating knee drives are shown in a 1.36-second loop.
- **Not established:** The side-on limbs overlap, so natural arm drive, soft landings and knee control are not clearly demonstrated.

### Jumping Jacks (`jumping_jacks`) — USER-PREFERRED REFERENCE — NOT CERTIFIED

- **Current asset:** `assets/animations/illustrated_athletes/jumping_jacks.json` (Lottie; 25 source frames; approximately 1.00 s; SHA-256 `e975bde0a30d9e1a…`).
- **App instructions:**
  - Stand with feet together and arms by your sides, allowing clear space overhead and to either side.
  - Jump feet apart as arms sweep overhead, landing with soft knees and knees tracking over toes.
  - Jump feet together as arms lower; repeat at a controlled rhythm.
- **Observed:** The original front-view animation shows feet apart/together while the arms rise and lower; this is the user's preferred reference.
- **Not established:** Visual preference is not a professional form sign-off. Soft landing and knee tracking still require qualified review.

### Towel Row (`row_towel`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/row_towel.webp` (30-frame WebP; 2278 ms loop; SHA-256 `1bd59ba05b9c35e3…`).
- **App instructions:**
  - Sit on the floor with knees slightly bent and loop an intact towel around the mid-soles of both shoes, holding one end in each hand.
  - Keep your spine tall and pull elbows back toward your ribs while your legs provide gentle opposing pressure through the towel.
  - Ease the arms forward while maintaining light tension; adjust leg pressure so each repetition stays smooth.
- **Observed:** A thin line is drawn from one wrist toward one shoe. It does not visibly loop around both mid-soles or show two hands gripping towel ends.
- **Not established:** The animation cannot teach the specified setup or safe opposing tension.

### Superman (`superman`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/superman.webp` (30-frame WebP; 3079 ms loop; SHA-256 `49d4d005afb01a28…`).
- **App instructions:**
  - Lie face down with arms extended overhead and legs long, keeping your gaze toward the floor.
  - Gently brace and lift arms, chest, and legs a small distance without forcing your lower back.
  - Pause for one second, then lower slowly; use a smaller lift or stop if your back is uncomfortable.
- **Observed:** The arms, chest and legs lift slightly; the encoded peak hold is about one second.
- **Not established:** Back comfort, gaze and the absence of excessive arching cannot be confirmed from this stylized side view.

### Reverse Lunge (`lunge_reverse`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/lunge_reverse.webp` (60-frame WebP; 4556 ms loop; SHA-256 `7c2cf320bd36eadd…`).
- **App instructions:**
  - Stand tall with feet hip-width apart and hands at your hips.
  - Step one foot back, bend both knees, and lower only as far as you can keep the front foot grounded and knee tracking over toes.
  - Push through the front foot to return to standing and alternate; complete eight repetitions per side.
- **Observed:** The figure steps back, but its hands hang at the sides rather than resting on the hips as instructed. The lead shoe also appears above the floor line in the lowered pose.
- **Not established:** Side-view overlap prevents verification of frontal knee tracking and equal alternating steps.

### Forward Lunge (`lunge_forward`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/lunge_forward.webp` (60-frame WebP; 4556 ms loop; SHA-256 `7eff4bc01ec06ae8…`).
- **App instructions:**
  - Stand with feet hip-width apart and brace your trunk.
  - Step forward and bend both knees, controlling your landing while keeping the lead knee aligned with toes.
  - Push through the lead foot to return to the start, then alternate; complete eight repetitions per side.
- **Observed:** A forward step and return are shown, but the lead shoe appears to float above the drawn floor line when the knee is bent, for example at frame 19/60.
- **Not established:** The frontal plane, lead-knee tracking and landing pressure cannot be validated from this side view.

### Static Split Squat (`squat_split_static`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/squat_split_static.webp` (30-frame WebP; 2278 ms loop; SHA-256 `7f3ebe279ed5ee48…`).
- **App instructions:**
  - Take a staggered stance with feet hip-width apart side to side and rear heel raised.
  - Bend both knees to lower vertically through a comfortable range, keeping the front foot grounded.
  - Press through your feet to rise without changing stance; complete eight repetitions and switch sides.
- **Observed:** The fixed split stance bends and rises, but the lead shoe appears above the ground line and only one stance is shown.
- **Not established:** The switch of legs is not demonstrated, and frontal knee/foot alignment cannot be checked.

### Bulgarian Split Squat (`squat_split_bulgarian`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/squat_split_bulgarian.webp` (30-frame WebP; 2278 ms loop; SHA-256 `e4b0784a9f91f3d8…`).
- **App instructions:**
  - Secure a low bench against movement and place the top of one foot on it behind you, with the front foot far enough forward for a comfortable bend.
  - Brace and lower through the front leg with a slight forward torso lean, keeping the front knee aligned with toes and hips square.
  - Press through the front foot to rise; complete six repetitions per side and step down carefully.
- **Observed:** The rear shoe is drawn on a bench, but the front shoe appears above the floor line in both upright and lowered poses; only one side is shown.
- **Not established:** Secure rear-foot/bench contact, front-knee tracking and the leg switch cannot be established.

### Calf Raise (`calf_raise`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/calf_raise.webp` (30-frame WebP; 2278 ms loop; SHA-256 `381cc92c9370fd5c…`).
- **App instructions:**
  - Stand with feet hip-width apart on a flat surface and knees soft.
  - Press through the balls of both feet to raise heels without rolling ankles outward.
  - Pause at the top and lower heels slowly to the floor.
- **Observed:** The figure raises its heels while facing a wall for balance.
- **Not established:** The side view overlaps the two feet; ball-of-foot contact and ankle rolling cannot be reliably checked.

### Bird Dog (`bird_dog`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/bird_dog.webp` (60-frame WebP; 4556 ms loop; SHA-256 `1288c4c2827eb8ee…`).
- **App instructions:**
  - Start on hands and knees with hands under shoulders and knees under hips.
  - Reach one arm forward and the opposite leg back, stopping at trunk height while keeping hips level.
  - Pause briefly, return gently, and switch sides; complete eight repetitions per side.
- **Observed:** The supporting knee artwork visibly extends below the ground line, including frames 1 and 10 of the 60-frame WebP. The rig alternates opposite near/far limbs.
- **Not established:** The image does not clearly convey left versus right, and it cannot establish level hips or spinal control. Joint-centre floor checks missed the knee silhouette.

### Reverse Crunch (`reverse_crunch`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/reverse_crunch.webp` (30-frame WebP; 2278 ms loop; SHA-256 `dbd9c053566e9fa3…`).
- **App instructions:**
  - Lie on your back with arms at your sides and hips and knees bent to right angles.
  - Exhale and gently curl the pelvis toward the ribs, lifting the tailbone slightly without swinging your legs.
  - Lower the pelvis slowly and return knees over hips without arching your back.
- **Observed:** A small pelvic lift and knee movement are visible, with arms alongside the body.
- **Not established:** The curl is subtle; the side-view illustration cannot prove controlled pelvic motion or absence of lumbar arching.

### Mountain Climbers (`mountain_climbers`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/mountain_climbers.webp` (71-frame WebP; 3240 ms loop; SHA-256 `98c87ddb2e2e20b3…`).
- **App instructions:**
  - Set a high plank with hands under shoulders and a straight line from head to heels.
  - Drive one knee toward the chest, then switch feet briskly with a small, light hop, keeping shoulders above hands.
  - Continue at a controlled rhythm without letting hips bounce; lower knees to finish.
- **Observed:** The moving knee artwork passes below the drawn floor line around frames 7 and 66 of 71. The rig uses planted-foot transitions rather than the small hop specified by the app.
- **Not established:** The 3.24-second loop is not a clear brisk switch; hip stability and knee-to-chest trajectory need rebuilding and review.

### Child's Pose (`childs_pose`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/childs_pose.webp` (single-frame hold; SHA-256 `8bc13003c37cea80…`).
- **App instructions:**
  - Kneel on a comfortable surface, separate knees as needed, and gently bring hips toward heels.
  - Fold forward and reach arms along the floor, allowing the forehead to rest if comfortable.
  - Relax into easy breaths without forcing knee bend; come up slowly and stop if knees are uncomfortable.
- **Observed:** One static kneeling, folded-forward pose is shown.
- **Not established:** It cannot show a comfortable entry/exit, knee separation, or whether the range is pain-free.

### Hip Flexor Stretch (`hip_flexor_stretch`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/hip_flexor_stretch.webp` (single-frame hold; SHA-256 `1295c2ea51971e34…`).
- **App instructions:**
  - Kneel on one knee on a comfortable surface with the other foot forward and front knee above the ankle.
  - Gently tuck the pelvis and squeeze the rear glute, then shift forward slightly without arching the back.
  - Hold for twenty-five seconds with an upright torso, then switch sides.
- **Observed:** One static half-kneeling pose is shown.
- **Not established:** Pelvic tuck, rear-glute engagement, entry, exit and switching sides are not demonstrated.

### Standing Hamstring Stretch (`hamstring_stretch_standing`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/hamstring_stretch_standing.webp` (single-frame hold; SHA-256 `bb281703b89d208e…`).
- **App instructions:**
  - Stand tall, place one heel slightly forward, and keep that knee soft rather than locked.
  - Bend the supporting knee and hinge at your hips with a long spine until the back of the front thigh gently stretches.
  - Hold for twenty-five seconds, rise slowly, and switch legs without bouncing.
- **Observed:** One static heel-forward hip hinge is shown.
- **Not established:** The supporting-knee bend is subtle; entry, exit, both knee positions and the side switch are not demonstrated.

### Good Morning (`good_morning`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/good_morning.webp` (30-frame WebP; 2278 ms loop; SHA-256 `ff944ceeb5ce0ab0…`).
- **App instructions:**
  - Stand with feet hip-width apart, knees soft, hands lightly behind head with elbows wide and spine tall.
  - Push hips back and hinge forward with a flat back until you feel a gentle hamstring stretch, keeping shins nearly vertical.
  - Drive hips forward and squeeze glutes to return to standing without rounding your back.
- **Observed:** The hands appear near or behind the shoulders rather than clearly resting behind the head as the instructions specify.
- **Not established:** Elbows-wide positioning and knee/spine alignment cannot be confirmed from the side.

### Hip Hinge (`hip_hinge`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/hip_hinge.webp` (30-frame WebP; 2278 ms loop; SHA-256 `675aaaf80c45eeb1…`).
- **App instructions:**
  - Stand with feet hip-width apart, hands on hips, knees softly bent and weight centered over mid-foot.
  - Push hips straight back with a long spine until torso leans forward, shins stay vertical and back stays flat.
  - Squeeze glutes to bring hips forward to standing, keeping abs gently braced.
- **Observed:** The hands hang alongside the thighs instead of being placed on the hips, contrary to the written setup.
- **Not established:** A hinge is visible, but shin verticality, knee softness and full-foot loading still need review.

### Single-Leg Hip Hinge (`hip_hinge_single_leg`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/hip_hinge_single_leg.webp` (30-frame WebP; 2278 ms loop; SHA-256 `21958e9008db88a0…`).
- **App instructions:**
  - Stand on one leg with knee soft, opposite leg straight, hands on hips or at sides for balance.
  - Hinge by pushing hips back and reaching extended leg behind you, keeping hips square and back flat.
  - Drive through the standing foot to return upright; complete eight repetitions per side without touching the free foot down.
- **Observed:** A single-leg hinge and return are shown with the free foot raised.
- **Not established:** Only one side is shown; hip squareness, soft standing knee and foot contact are not verifiable from the side.

### Donkey Kick (`donkey_kick`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/donkey_kick.webp` (30-frame WebP; 2278 ms loop; SHA-256 `6d85a073af24fcc9…`).
- **App instructions:**
  - Start on hands and knees with hands under shoulders, knees under hips, and neck neutral on a comfortable surface.
  - Keep knee bent at ninety degrees, brace trunk, and lift one heel toward the ceiling by extending the hip without arching the back.
  - Pause briefly at the top and lower with control; complete ten repetitions per side keeping hips level.
- **Observed:** A bent leg is raised behind the torso and lowered.
- **Not established:** Only one side is shown; the precise knee angle, pelvic rotation and comfortable support-knee placement need review.

### Pike Push-Up (`pushup_pike`) — NOT VERIFIED

- **Current asset:** `assets/animations/vital/pushup_pike.webp` (91-frame WebP; 3200 ms loop; SHA-256 `ab271c504c290b75…`).
- **App instructions:**
  - Start in an inverted-V with hands slightly wider than shoulders, hips high, and legs straight with heels toward the floor.
  - Bend elbows and lower the crown of the head toward the floor between your hands while keeping hips elevated.
  - Press back to the start with control, keeping neck neutral and avoiding shrugging shoulders.
- **Observed:** The separate Vital animation shows a pike position, lowering and pressing.
- **Not established:** It is a different visual style; head/floor clearance, shoulder loading and individual range need professional review.

### Wide Push-Up (`pushup_wide`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/pushup_wide.json` (Lottie; 74 source frames; approximately 2.47 s; SHA-256 `434c551e6c9a4740…`).
- **App instructions:**
  - Place hands wider than shoulders with fingers facing forward and legs extended in a straight plank.
  - Brace trunk and lower chest between hands with elbows angled outward around forty-five degrees, keeping hips level.
  - Press back up while maintaining a straight line from head to heels without letting shoulders shrug.
- **Observed:** The original wide push-up Lottie shows a lower and press with hands apart.
- **Not established:** The perspective does not reliably establish the specified elbow angle or shoulder loading.

### Shoulder Tap (`shoulder_tap`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/shoulder_tap.webp` (60-frame WebP; 4556 ms loop; SHA-256 `5b73f61404c06312…`).
- **App instructions:**
  - Begin in a high plank with hands under shoulders, feet hip-width apart, and a straight line from head to heels.
  - Shift weight slightly, lift one hand and tap the opposite shoulder without rotating hips or shoulders.
  - Return hand to the floor with control and alternate; complete eight taps per side.
- **Observed:** One hand lifts toward the upper body and the loop alternates sides in its rig.
- **Not established:** The side view hides whether each hand taps the opposite shoulder and whether the hips rotate.

### Butt Kicks (`butt_kicks`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/butt_kicks.webp` (30-frame WebP; 1530 ms loop; SHA-256 `d156e6873bc70f7b…`).
- **App instructions:**
  - Stand tall with feet hip-width apart and elbows bent at about ninety degrees.
  - Jog lightly in place, flicking each heel toward the glute quickly without leaning far forward.
  - Land softly on the forefoot and stay on the balls of your feet while swinging arms naturally.
- **Observed:** Heels flick back in an alternating loop.
- **Not established:** Overlapping side-view legs and shoes make forefoot landing, knee control and natural arm swing difficult to assess.

### Squat to Knee Drive (`squat_knee_drive`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/squat_knee_drive.webp` (65-frame WebP; 4000 ms loop; SHA-256 `0a9028ddfa415597…`).
- **App instructions:**
  - Stand with feet about shoulder-width apart, brace trunk, and keep weight over mid-foot.
  - Lower into a controlled squat to a comfortable depth with knees tracking over toes.
  - Stand and immediately drive one knee toward hip height without leaning backward, then step down and repeat alternating sides for eight repetitions per side.
- **Observed:** A squat is followed by a knee lift, with a second near/far leg phase in the rig.
- **Not established:** The overlapping side-view knees look stylized and do not make left/right tracking or the softness of the supporting knee clear.

### Single-Leg Stand (`single_leg_stand`) — STATIC HOLD — NOT A MOVEMENT DEMO

- **Current asset:** `assets/animations/illustrated_athletes/single_leg_stand.webp` (single-frame hold; SHA-256 `7d330558ace8ddd9…`).
- **App instructions:**
  - Stand tall with feet hip-width apart and hands on hips, focusing gaze at a fixed point ahead.
  - Shift weight onto one foot and lift the opposite foot a few centimeters, keeping the standing knee soft and hips level.
  - Hold for twenty seconds with steady breathing, then switch sides without hopping.
- **Observed:** One static single-leg balance pose is shown.
- **Not established:** The other side, an intentionally soft supporting knee and level hips are not demonstrated clearly.

### Standing Knee Raise (`standing_knee_raise`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/standing_knee_raise.webp` (60-frame WebP; 4556 ms loop; SHA-256 `aa2c791f42cdbd60…`).
- **App instructions:**
  - Stand tall with feet hip-width apart and hands at hips or holding a wall lightly for balance if needed.
  - Lift one knee toward hip height with a controlled motion, keeping trunk upright and standing leg soft.
  - Lower the foot softly without touching momentum, then alternate for eight repetitions per side.
- **Observed:** The rig alternates controlled knee lifts with the hands at the sides.
- **Not established:** Side-view overlap hides knee tracking, left/right distinction and whether the supporting knee stays soft.

### Triceps Dip on Chair (`dip_chair`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/dip_chair.webp` (30-frame WebP; 2278 ms loop; SHA-256 `30b49b4696262bec…`).
- **App instructions:**
  - Secure a sturdy, non-slip chair against a wall, sit near the front, place palms on the seat edge beside hips with fingers forward, and extend legs with heels on the floor.
  - Slide hips slightly off the seat and bend elbows to lower hips toward the floor with elbows tracking back, keeping trunk close to the chair.
  - Press through palms to extend elbows without locking, keeping shoulders down and chest open.
- **Observed:** The figure bends its elbows and lowers beside a chair with legs extended.
- **Not established:** The hand blends into the seat/body, so both palm contacts and shoulder position are not clear; chair stability cannot be validated from the artwork.

### Squat Pulse (`squat_pulse`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/squat_pulse.webp` (35-frame WebP; 1440 ms loop; SHA-256 `13aa16734d9a90d0…`).
- **App instructions:**
  - Stand with feet about shoulder-width apart, brace trunk, and lower into a comfortable squat with knees over toes and heels down.
  - At the bottom, perform small pulses by rising a few centimeters and lowering again without standing fully between pulses.
  - Complete ten pulses while keeping chest tall and weight over mid-foot, then stand smoothly.
- **Observed:** The loop pulses near the bottom rather than standing between pulses.
- **Not established:** Entry into and exit from the squat are not shown; knee tracking and foot pressure are not established.

### Glute Bridge March (`bridge_march`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/bridge_march.webp` (60-frame WebP; 4556 ms loop; SHA-256 `75014c6b9ced9dc1…`).
- **App instructions:**
  - Lie on your back with knees bent, feet hip-width apart, and lift hips into a bridge with shoulders, hips, and knees aligned.
  - Maintain the bridge height and slowly lift one knee toward chest without dropping or rotating the pelvis.
  - Lower the foot with control and alternate; complete eight lifts per side while keeping hips level.
- **Observed:** The figure lifts alternating knees while its hips stay raised, but the supporting shoe appears above the ground line throughout sampled poses.
- **Not established:** The floating-foot artwork does not show the instructed planted support; pelvic level and rotation are hidden by the side view.

### Plank Reach (`plank_reach`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/plank_reach.webp` (60-frame WebP; 4556 ms loop; SHA-256 `f56ba355854faaf9…`).
- **App instructions:**
  - Begin in a high plank with hands under shoulders, feet hip-width apart, and a straight line from head to heels.
  - Shift weight slightly and extend one arm straight forward to shoulder height without rotating hips or shoulders.
  - Return hand to the floor with control and alternate; complete eight reaches per side.
- **Observed:** An arm reaches forward and returns, with near/far phases in the rig.
- **Not established:** The image does not establish alternating arms, no torso rotation, or stable planted-hand loading clearly.

### Leg Raise (`leg_raise`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/leg_raise.webp` (30-frame WebP; 2278 ms loop; SHA-256 `72e27ac82d54962c…`).
- **App instructions:**
  - Lie on your back with legs extended, hands at sides or lightly under hips for support, and lower back gently pressed toward the floor.
  - Brace abs and lift straight legs toward the ceiling only as far as you can keep the back from arching.
  - Lower legs slowly with control, keeping tension and stopping before the back lifts.
- **Observed:** The straight legs lift and lower together.
- **Not established:** The overlap hides both legs and the drawing cannot demonstrate maintained lower-back contact or the individual's safe range.

### Flutter Kicks (`flutter_kicks`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/flutter_kicks.webp` (30-frame WebP; 2278 ms loop; SHA-256 `f9eb29ee980e71ae…`).
- **App instructions:**
  - Lie on your back with legs extended, hands at sides or under hips, and press lower back gently toward the floor.
  - Lift both legs a few centimeters off the floor, brace abs, and make small alternating up-and-down flutters without letting the back arch.
  - Continue for twenty seconds at a controlled rhythm, keeping legs straight but knees soft.
- **Observed:** Small alternating leg movements are visible.
- **Not established:** The overlapping shoes and legs make left/right timing and soft knees hard to read; lower-back contact cannot be certified.

### Fast Feet (`fast_feet`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/fast_feet.webp` (30-frame WebP; 1530 ms loop; SHA-256 `12af6437b9411e17…`).
- **App instructions:**
  - Stand with feet hip-width apart, knees soft, elbows bent, and weight over the balls of your feet.
  - Take very quick, small steps in place, barely leaving the floor, staying on the forefoot with relaxed arms.
  - Continue for twenty seconds at a fast but controlled tempo, then slow to a march.
- **Observed:** The shoes almost merge and the movement reads as small synchronized hops rather than clearly alternating fast steps.
- **Not established:** This is a visual communication defect, not proof of injury risk; individual foot loading and soft knees are unclear.

### Standing Mountain Climber (`mountain_climber_standing`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/mountain_climber_standing.webp` (60-frame WebP; 3060 ms loop; SHA-256 `36be88025f5bb888…`).
- **App instructions:**
  - Stand tall with feet hip-width apart and arms by your sides or bent at ninety degrees.
  - Drive one knee toward chest to hip height while swinging the opposite arm forward, staying tall without leaning backward.
  - Lower the foot softly and immediately drive the opposite knee, maintaining a brisk alternating rhythm.
- **Observed:** The alternating knee-raise loop takes about 3.06 seconds and includes conspicuous pauses, so it does not communicate the instructed brisk rhythm well.
- **Not established:** Opposite-arm swing, soft landing and knee control are obscured by the side view.

### Cobra Stretch (`cobra_stretch`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/cobra.json` (Lottie; 70 source frames; approximately 2.80 s; SHA-256 `0c36da8cee6287ec…`).
- **App instructions:**
  - Lie face down with legs extended, hands under shoulders, and forehead lightly resting on the floor.
  - Gently press hands to lift chest a small distance, keeping hips and pubic bone grounded and neck long without forcing the range.
  - Hold for twenty seconds with easy breaths, then lower slowly; stop if the lower back feels compressed.
- **Observed:** The existing 2.8-second Lottie repeatedly presses into a high, nearly straight-arm backbend and returns, rather than clearly showing the instructed small lift held for twenty seconds.
- **Not established:** Comfort and lumbar compression cannot be judged from the cartoon; the depicted range and timing need replacement or an explicit instruction change.

### Resistance Band Row (`row_resistance_band`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/row_resistance_band.webp` (30-frame WebP; 2278 ms loop; SHA-256 `66ca912e8b98f599…`).
- **App instructions:**
  - Anchor the band at chest height or loop it around a sturdy post, then step back until there is light tension with arms extended.
  - Hinge slightly at the hips with a braced trunk, and row the handles toward your lower ribs, elbows tracking alongside the body.
  - Squeeze the shoulder blades together at the end of the pull, then extend the arms slowly back to the start.
- **Observed:** A single thin line reaches from a post to an open-looking hand; the two handles and a secure loop/anchor are not shown clearly.
- **Not established:** The grip, two-handed setup and band tension cannot be learned reliably from this illustration.

### Dumbbell Goblet Squat (`squat_goblet_dumbbell`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/squat_goblet_dumbbell.webp` (30-frame WebP; 2278 ms loop; SHA-256 `c9605024c3a4d596…`).
- **App instructions:**
  - Cup one end of a dumbbell with both hands and hold it vertically against your chest, elbows pointing down.
  - Squat down between your knees until thighs reach a comfortable depth, keeping the chest tall and heels planted.
  - Drive through the whole foot to stand back up without locking the knees at the top.
- **Observed:** The dumbbell is drawn near the wrist with open-looking fingers rather than visibly cupped in both hands.
- **Not established:** The side-on knee and foot overlap prevent checking knee tracking or two-foot loading; the knee shapes also look unnatural.

### Dumbbell Bent-Over Row (`row_bent_over_dumbbell`) — NOT VERIFIED

- **Current asset:** `assets/animations/illustrated_athletes/row_bent_over_dumbbell.webp` (30-frame WebP; 2278 ms loop; SHA-256 `f62751c794c055d4…`).
- **App instructions:**
  - Stand holding a dumbbell in each hand, hinge forward about 45 degrees with a flat back and soft knees.
  - Let the dumbbells hang at arm's length, then row them toward your lower hips, keeping elbows close to your sides.
  - Pause briefly with the shoulder blades drawn together, then lower the weights slowly to the start.
- **Observed:** A hinged row is visible, but the side view makes the two dumbbells and both hands overlap.
- **Not established:** Two-handed grips, elbow tracking and flat-back alignment are not reliably visible.

### Kettlebell Deadlift (`deadlift_kettlebell`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/deadlift_kettlebell.webp` (30-frame WebP; 2278 ms loop; SHA-256 `82fba2551ff06c22…`).
- **App instructions:**
  - Place a kettlebell between your ankles, stand with feet about hip-width apart, and hinge down to grip the handle with both hands.
  - Set a flat back and braced trunk, then stand up by driving through the feet and extending hips and knees together.
  - Lower the kettlebell back along the same path with control, keeping the back flat throughout.
- **Observed:** A kettlebell moves with the figure, but the hand does not visibly wrap around the handle and the second hand is obscured.
- **Not established:** Two-handed grip, foot pressure and knee alignment need to be redrawn and reviewed.

### Kettlebell Goblet Squat (`squat_goblet_kettlebell`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/squat_goblet_kettlebell.webp` (30-frame WebP; 2278 ms loop; SHA-256 `6308aabe50c5d674…`).
- **App instructions:**
  - Hold a kettlebell by the horns at chest height with elbows tucked, feet slightly wider than hip-width.
  - Squat down between your knees to a comfortable depth, keeping the chest tall and the weight close to the body.
  - Push through the whole foot to rise, finishing tall without leaning back.
- **Observed:** The kettlebell is drawn at the wrist with open-looking fingers rather than clearly held by both horns.
- **Not established:** The side view cannot show both hands, feet or frontal knee tracking; knee shapes look unnatural.

### Dead Hang on Pull-Up Bar (`dead_hang_pullup_bar`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/dead_hang_pullup_bar.webp` (single-frame hold; SHA-256 `3c01b674f8d25590…`).
- **App instructions:**
  - Grip a secure pull-up bar slightly wider than shoulder-width, then step or hop up until the arms are fully extended.
  - Hang with relaxed shoulders or gently drawn down, body quiet and still, feet clear of the floor.
  - Hold for the target time, then release under control and land softly.
- **Observed:** This is a static hold; open fingers pass across the bar rather than convincingly gripping it.
- **Not established:** It does not show a secure grip, entry, release or landing. A still is appropriate for a hold but is not a motion demonstration.

### Scapular Pull-Up (`scapular_pullup`) — VISIBLE ISSUE / MISMATCH

- **Current asset:** `assets/animations/illustrated_athletes/scapular_pullup.webp` (30-frame WebP; 2278 ms loop; SHA-256 `9d132f6328386eff…`).
- **App instructions:**
  - Hang from a secure pull-up bar with straight arms and shoulders settled, feet clear of the floor.
  - Without bending the elbows, pull the shoulder blades down and back so the body rises a short distance.
  - Hold for a beat at the top, then lower back to the full hang with control before the next rep.
- **Observed:** The raised open hand passes across the bar instead of visibly gripping it; the shoulder movement is very small.
- **Not established:** Secure grip, scapular action and fully straight elbows are not clearly teachable from the drawing.

## Exercises without an assigned animation — all 29

These IDs currently fall back to still photographs. There is no animation or motion cycle to validate. A photo may not demonstrate all phases or be a form-verified substitute.

- Side Plank (`plank_side`)
- Doorway Row (`row_doorway`)
- Reverse Snow Angel (`reverse_snow_angel`)
- Prone Y Raise (`prone_y_raise`)
- Bicycle Crunch (`bicycle_crunch`)
- Heel Taps (`heel_taps`)
- Cat-Cow (`cat_cow`)
- Thoracic Rotation (`thoracic_rotation`)
- Fire Hydrant (`fire_hydrant`)
- Close-Grip Push-Up (`pushup_close_grip`)
- Plank Up-Down (`plank_up_down`)
- Step Jack (`step_jack`)
- Skater Step (`skater_step`)
- Shadow Boxing (`shadow_boxing`)
- Ankle Circles (`ankle_circles`)
- Arm Circles (`arm_circles`)
- World's Greatest Stretch (`world_greatest_stretch`)
- Diamond Push-Up (`pushup_diamond`)
- Push-Up to Downward Dog (`pushup_down_dog`)
- Wall Shoulder Press (`wall_shoulder_press`)
- Sumo Squat (`squat_sumo`)
- Curtsy Lunge (`lunge_curtsy`)
- Lateral Lunge (`lunge_lateral`)
- Frog Pump (`frog_pump`)
- Side Plank Knee Down (`plank_side_knee`)
- Russian Twist (`russian_twist`)
- Low-Impact Burpee (`burpee_low_impact`)
- Figure-Four Stretch (`figure_four_stretch`)
- Resistance Band Pull-Apart (`pull_apart_resistance_band`)

## Reference material used for comparison

- ACE: bodyweight squat and knee/foot alignment [1](https://www.acefitness.org/resources/everyone/exercise-library/135/bodyweight-squat/).
- ACE: opposite arm/leg and level hips for bird dog [1](https://www.acefitness.org/resources/everyone/exercise-library/14/bird-dog/).
- ACE: push-up body alignment and lowering/pressing [4](https://www.acefitness.org/resources/everyone/exercise-library/41/push-up/) and forearm plank [3](https://www.acefitness.org/resources/everyone/exercise-library/32/front-plank/).
- ACE: glute bridge with bent knees and planted feet [1](https://www.acefitness.org/resources/everyone/exercise-library/49/glute-bridge/).
- NHS: stable-chair sit-to-stand and a forward-lunge example [10](https://www.nth.nhs.uk/resources/lower-limb-exercise-and-education/).
- NHS: dead bug opposite arm/leg and back support [3](https://www.newcastle-hospitals.nhs.uk/services/injury-prevention-advice-for-runners/).

These references describe examples and cues; variations and individual limits exist. None has reviewed or endorsed this app or its modified artwork.

## Recommended next steps

1. Do not release the rejected or visibly misleading candidates as confirmed demonstrations. If the product owner chooses to hide them temporarily, use the optional Jumping-Jack-only flag and retain the assets, with the clear understanding that a photo is not a movement demo.
2. Replace or carefully rebuild movement families with explicit contact constraints and a view that makes the critical joints visible. Prioritize Bird Dog, Mountain Climbers, lower-body floor contact, and equipment grips. Do not simply compress the figure or copy one pose to every exercise.
3. Review each replacement as a full moving loop against the exact app instructions, including transitions, both sides, floor and equipment contact, and user visual acceptance. Have a qualified fitness professional sign off before treating any example as coaching guidance.
4. Preserve workout prescriptions, the player clock and existing fallback behavior. Re-run technical tests and review actual Flutter/device rendering; tests and geometric checks are supplementary, not form certification.
