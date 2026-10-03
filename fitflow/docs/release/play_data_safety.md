# Play Console Data Safety worksheet — candidate answers

Do not paste these into Play Console until the developer reviews them against the live form. This is not a submission.

Evidence is in `docs/release/data_safety_audit.md`.

Google treats data as **collected** when it is transmitted off the user's device to the developer or to a third party. Data that stays on the device is not collected. A user-started export to a place the user chooses is not the same as FitFlow receiving the data.

## Candidate result

**FitFlow does not collect or share user data with a FitFlow server, analytics SDK, or ads SDK.**

That candidate is supportable only with the caveats below. Do not check "no data collected" in Play Console without reading them.

### Not transmitted by FitFlow

| Data type | Stored locally? | User-exported backup? | Transmitted by FitFlow or an included SDK? |
| --- | --- | --- | --- |
| Personal info / profile preferences (goal, experience, equipment, preferences) | Yes | Yes, only if the user creates a backup | No |
| Health and fitness information (capability, progression, workout history, programs) | Yes | Yes, only if the user creates a backup | No |
| App activity (completed workouts, reminder choices, appearance) | Yes | Included in the same manual backup | No |
| Files and documents (custom workouts, backup JSON) | Yes, in app storage or a user-selected file | The backup file is the export | No FitFlow upload |
| Device or other identifiers | Not collected by FitFlow | No | No advertising ID |
| Diagnostics / crash logs | No FitFlow analytics or crash SDK | No | No |

### Caveats the developer must still judge

1. **Device text-to-speech.** Coaching text is passed to the device TTS service. FitFlow does not run that service. An online engine selected on the device may process the spoken text. That is not a FitFlow SDK collection, and it is not a guarantee that speech stays on device.
2. **User-selected backup destination.** If the user saves a backup into a cloud folder with the system picker, that transfer is initiated by the user. FitFlow does not receive the file.
3. **Android backup.** The app opts out of automatic cloud backup and device-to-device transfer of FitFlow data. Confirm the merged release manifest in Part 2 before answering the form.
4. **`http` in `pubspec.lock`.** It is pulled in by the `timezone` package. FitFlow loads the bundled time-zone database and does not use `http` to upload user data. It is not an analytics SDK.

## Form sections to answer from this candidate

- Data shared: No.
- Data collected: No FitFlow or included-SDK collection, subject to the caveats. If Play's form asks about third-party speech engines separately, disclose the device TTS behavior rather than claiming every engine is offline.
- Security practices: data is not transmitted by FitFlow, so "encrypted in transit" is not a FitFlow pipeline. Local data is not additionally encrypted by a FitFlow account system because there is no account.
- Data deletion: uninstall removes app-owned local state, subject to the OS. User-created backup files remain until the user deletes them. No account-deletion URL.
- Account creation: none.

Do not invent a Data Safety URL or submit the form from this repository.
