# Part 6 — Oppo A12 physical QA route

**Status: ALL physical checks below are PENDING.** Arena widget tests/captures are not device evidence. Do not mark this checklist passed from automated results. No APK/AAB was produced here.

## Setup and evidence

Use an independently installed development build from this exact reviewed source. Record commit, Oppo/ColorOS/Android versions, system font/display size, navigation mode (gesture/three-button), orientation, battery saver, available memory and TalkBack version. Start with disposable local TEST data; back up any valued data before testing Restore. Keep backup files local. Never use real credentials or personal data in recordings.

For **every stage** inspect: clipped or overlapping text, awkward/doubled spacing, readable metadata, primary/secondary hierarchy, duplicated headings/actions, Light/Dark color/contrast, reachable 48dp touch targets, focus/TalkBack order, system bars/insets and visual stutter. Record route, conditions, steps, expected/actual, screenshot/video and pass/fail; leave untested items pending. Time smoothness/frame pacing on the device, not from screenshot impressions.

| # | Stage / actions | Extra acceptance checks | Result |
|---|---|---|---|
| 1 | Fresh install → splash → onboarding | No artificial delay or blocked retry; recoverable read error Retry focus/tap works; no flash of invalid data. | Pending |
| 2 | Complete onboarding; move Back and Next | Selections remain visible/native; short-height scroll reaches actions; no gender/medical claims or unpersisted fake success. | Pending |
| 3 | Movement Check all questions and save | Canonical five human levels, read-only later; large labels wrap; scoring/gates unchanged. | Pending |
| 4 | Home and main navigation | One workout decision area; Home/Workouts/Progress/Profile selected state; nested branch resumes; same-tab resets; nested Back works. | Pending |
| 5 | Standard adaptive workout from Home | Goal/setup and target versus planned duration are honest; generated plan and entry action unchanged. | Pending |
| 6 | Low Energy / Comeback / return to Standard | Temporary mode selected state and copy; no guilt or unsupported recovery promise; no stale plan. | Pending |
| 7 | Workouts overview | Programs, Custom workouts and Library discoverable without card clutter; long names readable; menus distinct. | Pending |
| 8 | Program overview → detail → session preview | Current session/status, progressive disclosure, switch/restart confirmations, native Back; actions accessible at short height. | Pending |
| 9 | Create/edit/view/reorder/delete a TEST custom workout | Draft/discard/save unchanged; human difficulty/equipment labels; add sheet search keyboard and prescription dialog scroll; no destructive accidental tap. | Pending |
| 10 | Library scroll and browse | Lazy scrolling feels smooth; no jump or simultaneous reveal animation; lower results reachable. | Pending |
| 11 | Library search, filters, clear, no results | Real keyboard never obscures close/apply/clear; selection not color-only; filters retained; scroll and focus after dismissal. | Pending |
| 12 | Exercise Detail and skill trees | Readable metadata/instructions, canonical movement labels; no fabricated artwork/media/mastery. | Pending |
| 13 | Progress, chart text alternative, history → detail | No made-up metrics; history pagination/order preserved; empty and failed capability states useful and Retry works. | Pending |
| 14 | Workout Preview including long lists | Target/estimated/planned labels distinct from actual completion time; start and Back reachable. | Pending |
| 15 | Player ready → active timer/reps | Large countdown readable with 2× font; no aggressive TalkBack announcement every second; voice button tooltip/state. | Pending |
| 16 | Pause/resume, background/foreground | Timer/session ownership preserved, no double actions; paused status is explicit text; device lifecycle does not silently advance. | Pending |
| 17 | Rest, next exercise and section break | Phase state clear without color/motion; skip/continue target accessible; no tick-driven surface animation. | Pending |
| 18 | Replace active exercise | Eligible results and workload unchanged; keyboard/focus/scroll; cancel preserves session; same session ID. | Pending |
| 19 | Finish → completion → Done/Tune | One completion/history record; same program origin; labelled tuning load/save; apply/skip works with reduced motion and long text. | Pending |
| 20 | TTS on/off, pause and completion | Existing voice behavior only; no duplicate speech; label follows state; Android engine availability/sound tested physically. | Pending |
| 21 | Profile, all saved Movement levels, edit/save/discard | Actual persisted values, four editor sections, None semantics, invalid/save-failure recovery; no summary disagreement after restart. | Pending |
| 22 | Settings → Appearance System/Light/Dark | Persistence-first choice; expand/collapse readable; system theme change and restart match saved preference. | Pending |
| 23 | Workout reminders | Native time picker/day labels; deny/grant permission, disabled master and OEM battery behavior truthful; notification delivery/launch tested on ColorOS, never guaranteed. | Pending |
| 24 | Backup/Restore, cancel and invalid/valid TEST files | System picker bars/keyboard; no account/network; honest preview; explicit replace/not merge; confirmation/error scroll and rollback copy; local data unchanged on cancel. | Pending |
| 25 | Light/Dark sweep across all above | Borders, disabled text, metadata, chart and phase colors readable; selected/action state not color-only. | Pending |
| 26 | Landscape, device bars and keyboard | Player, onboarding, assessment, Library, Program detail, editors, disclosures and Restore dialog; all controls reachable by scrolling, no font clamp. | Pending |
| 27 | Large system font AND display scaling, TalkBack, keyboard | Repeat essential route at maximum useful settings; headings, native selected/radio/switch/tap actions, readable timer; external keyboard Tab/Enter/Escape where supported. | Pending |
| 28 | Offline and system Remove animations | Complete route with airplane mode; no network imagery assumptions; page/overlay/phase changes immediate and still understandable; loading retains text. | Pending |
| 29 | Force-close/relaunch, restart device, repeat key route | Appearance/profile/custom/history/reminders persistence; route/Back correctness; observe cold-start and long-session stutter/thermal/battery behavior separately. | Pending |

## Automated versus physical boundary

Automated: production Flutter layout under logical constraints, text scaling and theme combinations; native semantics/actions and targets; reduced-motion duration/structure; route and business regression tests. External PNGs are actual production-widget renders with TEST fixtures and loaded fonts, not Oppo screenshots.

Physical still pending: perceived animation smoothness/frame pacing and low-memory longevity; Android font rasterization; actual TalkBack speech/focus/gesture behavior; IME/keyboard interaction; status/navigation/cutout/gesture insets; OEM notification permission, timing and battery policy; TTS engine and audio; system file picker and restart/lifecycle behavior. Publication does not imply device certification or release readiness.
