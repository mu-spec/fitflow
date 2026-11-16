# Workout music and layout review — 9 November 2026

## Implemented
- Session-scoped offline audio for adaptive, custom and program workouts, with explicit enable/disable, track selection and volume. Music is off until enabled; preferences are saved locally.
- EDM Detection Mode (128 BPM) and Club Diver (140 BPM) by Kevin MacLeod, CC BY 4.0; source and attribution are in assets/audio/NOTICE.txt and the music sheet.
- Work, rest and transitions play music. Ready, section breaks, manual pause, lifecycle pause and completion are silent. Resume retains track position. Exit disposes playback. Async asset loading cannot restart music after pause or disposal.
- Audio interruptions and unplugged headphones pause the workout and music. Foregrounding does not auto-resume. Speech ducks music to 25% of the selected level.
- Music settings and the exit dialog pause the workout. Audio failures show retry and leave the workout usable.
- Corrected selected profile field padding; enlarged card artwork proportions without cropping; reduced Programs hub height; simplified Home setup facts; visible skill thumbnails; removed repetitive empty report tabs/totals; changed Ready from an apparent frozen countdown to a prompt; section-by-section custom builder retaining workout entries.

## Verification
- 10 music tests: interruption/no-auto-resume, headphone disconnect, overlapping speech/system ducking, sheet at 320px/2x text, speech ducking, retry after load error, pause/resume, pause during loading, exit during loading, track switch while paused.
- 41 responsive/settings save/card tests across 320/390 widths and 1x/2x text; 11 custom-builder state tests.
- 33 player navigation/lifecycle tests, 1 new Ready/music-sheet integration test, 40 active-player responsive tests.
- 8 program-route responsive tests passed. Two older program tests still expect retired combined metadata strings; broader legacy player composition tests also contain old ring/geometry expectations. Full legacy suite is not green.
- Focused analyzer: no issues. Full analyzer reports unnecessary non-null assertions after SDK constraint update and an existing unused import in exercise_animation_test.dart.
- Rendered screenshots inspected in build/redesign-qa. Real-device sound, phone-call interruption, Bluetooth disconnect and long-session looping still need physical-device verification; no device connected via ADB.

- Android debug APK build succeeded; final source rebuild succeeded (build/music-apk-final.txt). Verified both MP3s and the final interruption/headphone handlers are packaged in the APK.

## Follow-up — 10 November 2026
See launch25-animation-review.md for the animation rollout, setup-question access and replacement electronic music.
