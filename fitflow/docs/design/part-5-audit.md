# Part 5 — preimplementation audit

Baseline: `d04ca98781e458c5a1a0377495d9155556221cfb`; local and fetched main match, clean before audit. Parts 1–4 remain canonical. Scope is utility presentation only; no release, branding, platform, schema, controller, domain or persistence changes planned.

## Profile and editors
- Overview currently stacks four identical cards. Real goal/experience/time/environment are compressed into two lines; equipment/preferences hide additional choices behind +N. No current movement profile is visible. Error copy claims saved settings are safe without checking persistence.
- Three real editors have independent drafts, explicit persist-first saves, validation in existing controllers, failure retention and unsaved Back confirmation. Equipment None is exclusive and the selection never becomes empty. Preserve all these contracts and adaptive invalidation.
- Fitness editor shows every option in four long groups. Use current-value disclosures rather than an onboarding wizard. Reuse Part 2 localized choice language and canonical selection components. Equipment/preferences remain multi-select forms. Add a clearly labelled Cancel through existing Back/discard protection; cap the save area and keep controls accessible at large text/keyboard insets.
- There is **no existing post-setup capability editor**: `/capability-assessment` is a first-run gate that redirects complete profiles to Home. Do not repurpose that flow or add new scoring/editing functionality. Present actual persisted movement levels as a read-only disclosure using canonical Just starting / Basic / Solid / Strong / Advanced labels, with truthful loading/retry/missing states and an explanation of variation selection.

## Settings / Appearance
- Appearance is always expanded, reminders are a full form, Backup repeats its title, and Privacy is incorrectly grouped under Data. Existing actual destinations only: appearance, reminders, backup and in-app privacy. No persisted voice setting, version/About product screen, support link or external privacy URL exists here.
- Use Preferences / Data / About groups, compact rows/disclosures and actual current values. Appearance remains System/Light/Dark and persist-first; retain old mode on failure, block duplicate taps and show saving. Replace excluded native radio semantics with native interactive radio semantics.
- Existing footer is local-data guidance, not a guarantee about Android system backup. Keep language factual.

## Reminders
- Widget refreshes status on mount/resume and listens for sanitized controller outcomes. Native picker, current weekday order, Android permission/settings recovery and scheduler ownership are already implemented. Preserve lifecycle, service/controller calls and all scheduling/rollback/restart behavior.
- Days/time are immediate writes, including when disabled, not an explicit-save draft. Enabled edits atomically reschedule; disabling only reports Off after successful cancellation/persistence. Failed rollback can leave schedule attention required. Never claim the previous schedule is safe.
- Controller busy covers enabled writes but not every disabled preference/test operation. Presentation can add one in-flight action guard without changing controller semantics. Picker cancellation stays quiet. Current custom weekday semantics exclude the native tap action: retain native chip action and supply the full weekday label without duplicating selected state.
- Compact status summary and optional details should reduce initial Settings density. Permission recovery stays inside existing reminder controls; no new requests on disclosure/opening.

## Backup / restore
- Existing file service uses the system picker, no storage permission; save/pick cancellation are distinct and quiet. Actual payload: fitness profile, capability, adaptive progression evidence, history (retained maximum 100), custom workouts, program progress, reminder preferences and appearance. No cloud/account/encryption guarantees.
- Existing screen uses two oversized equal cards plus repeated copy. Keep Create primary, choose-file secondary; only render validated preview. Preview currently exposes “Progression evidence”/patterns: replace presentation terminology, never serialized fields.
- Confirmation already says replace/no merge. Use canonical destructive confirmation and reduced-motion behavior. Preserve transaction validation, rollback distinctions, all provider refreshes and splash gates after success. “Choose a different file” currently only discards pending preview: label that action honestly rather than changing the flow.
- Results distinguish success, reminder attention, complete rollback and incomplete rollback. Keep those distinctions; no raw exception strings.

## Privacy / accessibility / layout
- Existing in-app privacy has nine factual sections. No invented contact, version, legal URL, account, support utility or release-blocker resolution. Public policy URL remains an external release blocker, outside Part 5.
- Reuse Part 1 feedback, tokens, selection, confirmation and Part 2 copy. Headings have semantics; preserve native focus/tap/checked states, 48dp targets and wrapping. No text-scale clamp or duplicate spoken switch state. Use disclosure motion tokens and immediate reduced motion; no decorative animation, images, blur or new packages.
- Check 320/390/430/600/840+ and landscape with 2× text, Light/Dark, readable-width caps and keyboard-safe editor actions. Existing screens cap at 640/720; align utility caps to canonical readable width.

## Validation plan
Preserve functional tests and strengthen them where visible presentation changes require opening disclosures or checking native semantics. Add targeted presentation/interaction tests for current capability labels, disclosure/current values, disabled-write duplicate guard, native semantics, Cancel, responsive Light/Dark/reduced-motion and keyboard. Run relevant profile/capability/settings/appearance/reminder/backup/privacy/localization tests, `flutter analyze`, FULL `flutter test`, and `git diff --check`, serially. No APK/AAB or physical-device claims. Document exact results and an unexecuted Oppo A12 checklist. One focused commit and normal push only.
