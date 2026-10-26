# Setup presentation and two-exercise animation pilot

## Presentation
- Slate launch surface with the existing citrus icon, larger app name and readable tagline. Native launch colors match the Flutter brand screen in both device themes; the saved app theme is unchanged.
- Successful Flutter startup holds the brand screen for a minimum of 5.5 seconds. Storage runs concurrently; failures appear immediately and retries do not add another delay. Android process/engine startup can add time before Flutter appears.
- Full-screen setup photography is no longer washed out. Questions, progress, choices and assessment content use local high-opacity panels for contrast in either theme.
- Preparation content fills the viewport width and centers as a group. Oversized text can scroll. The existing six-second preparation pacing and success-gated 100% remain unchanged.

## Animation pilot
The connected Runway workspace is on the Free plan with no video models. The user authorized the simpler character fallback. No paid generation, purchase, new dependency or video player was used.

Original shaded vector human demonstrations are enabled only for these exact canonical IDs:
- `march_in_place`: alternating supported march with opposite arm swing.
- `squat_bodyweight`: controlled squat with grounded feet and fixed-length leg segments.

These are illustrated characters, not realistic 3D footage. The visual loop runs only during active work, freezes on pause/background, and is static during ready/rest. It never counts reps or drives the workout controller. System reduced-motion uses the existing registered photo. All other exercises retain their photos. Existing timers, prescriptions, replacement eligibility, audio, exit and completion behavior are unchanged.

## Validation
- Scoped Flutter analysis: 17 files, no issues.
- Pilot + splash/preparation layout tests: 40 passed, including 360x640, 360x800 and 412x915, both themes and 2x text.
- Existing Player composition/navigation/behavior subset: 51 passed, including adaptive/custom/program origin, pause, rest, replacement, details, sound, exit and completion.
- Final setup/startup/navigation batch (`visual_v2_setup_test`, `app_test`, `onboarding_test`): 52 passed.
- Startup routing/recovery, capability saving and timer-efficiency tests also passed in the initial focused run. Three new test assumptions failed initially (timed completion used a rep action; large text expected centering even when taller than the viewport), were corrected, and their files passed on rerun.
- Native Android resources compiled with AAPT2; no Gradle or APK/AAB build.
- No screenshot generation, full-suite run or media revalidation.

## Device review
Review the two illustrated movements before expanding the pilot. Check native-to-Flutter launch continuity on the target Android version, perceived splash duration, photo/text contrast, and demonstration cadence. No other exercise animations are included in this milestone.
