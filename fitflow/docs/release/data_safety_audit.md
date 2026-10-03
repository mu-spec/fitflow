# FitFlow V1 data, SDK, and permission audit

This audit is the evidence base for the Play Data Safety worksheet. It is not a Play Console submission. It was produced by reading the app source, `pubspec.yaml`, `pubspec.lock`, and the Android manifests in this repository. Plugin library manifests are merged only at build time; Part 2 must re-check the merged release manifest. No release binary was built for this audit.

## Product facts used as evidence

- FitFlow application code under `lib/` does not import `package:http`, Firebase, an ads SDK, or an analytics SDK.
- There is no FitFlow account, backend, or cloud-sync client.
- Persistence is local SharedPreferences plus files the user explicitly saves through the system picker.
- Manual backup schema remains `1` and covers the existing eight areas only.
- Android automatic backup is disabled in the app manifest (`android:allowBackup="false"`) and both rule files exclude FitFlow storage domains, including `sharedpref`.

## Direct runtime dependencies

| Package | Version | Role | Transmits FitFlow user data off device? |
| --- | --- | --- | --- |
| flutter / flutter_localizations | SDK | UI, localization | No. Formatting and widgets only. |
| intl | lockfile | Date/number formatting used by gen-l10n | No. |
| flutter_riverpod / riverpod / state_notifier | 2.6.1 / 1.0.0 | In-memory state | No. |
| go_router | 18.0.1 | In-app navigation | No. |
| shared_preferences | 2.5.5 | Local key-value storage | No. Writes stay on device. |
| flutter_local_notifications | 22.3.1 | Local reminder notifications | No network client. Shows notifications the app schedules. |
| timezone | 0.11.1 | Time-zone data used to schedule reminders | No. Bundled data, no account. |
| flutter_timezone | 5.1.0 | Reads the device time-zone identifier | No. Local platform lookup only. |
| flutter_tts | 4.2.5 | Speaks coaching text through the device TTS engine | FitFlow does not send the text to a FitFlow server. The selected device TTS engine may process speech itself. See TTS below. |
| file_picker | 13.1.0 | System file picker for manual backup save/open | No FitFlow upload. The user chooses the destination. |

## Transitive packages that matter

| Package | Why it is present | Off-device transmission of FitFlow user data |
| --- | --- | --- |
| http 1.6.0 | Transitive dependency of the `timezone` package (`timezone` 0.11.1 depends on `http`). FitFlow loads zones from the bundled `timezone/data/latest_all.dart` and does not call the package's network download API. | Not used by FitFlow to send profile, history, or workout data. |
| shared_preferences_android, file_picker platform packages, flutter_local_notifications platform packages | Platform implementations of the plugins above | Local or system-UI only, except as noted for TTS. |
| dbus, win32, path_provider_* , flutter_*_linux/windows/web | Desktop/web implementations pulled in by Flutter plugins | Not part of the Android phone release path. |

No Firebase, Crashlytics, Google Analytics, AdMob, `google_mobile_ads`, Facebook SDK, or paid AI client is declared in `pubspec.yaml` or `pubspec.lock`.

## TTS disclosure

FitFlow uses `flutter_tts` to speak workout coaching through the text-to-speech service configured on the device.

- FitFlow does not operate a TTS server.
- FitFlow does not choose or certify the engine.
- A system or third-party engine the user has selected may download voices or process speech online.
- This audit does **not** claim that every possible TTS engine is offline.

Voice coaching stays in the app.

## Permissions declared by FitFlow

Release source manifest (`android/app/src/main/AndroidManifest.xml`):

| Permission | Intentional? | Purpose |
| --- | --- | --- |
| `POST_NOTIFICATIONS` | Yes | Show workout reminders the user enabled. Android 13+. |
| `RECEIVE_BOOT_COMPLETED` | Yes | Restore scheduled reminders after reboot. |

Not declared, and not required for V1:

- location
- contacts
- camera
- microphone
- photo or broad storage (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`, `READ_MEDIA_*`)
- exact alarm (`SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`)
- accessibility service
- Health Connect
- advertising ID (`AD_ID`)
- `QUERY_ALL_PACKAGES`

`INTERNET` is declared only in the debug and profile manifests so the Flutter tool can attach. It is not in the main/release manifest.

Plugin library manifests that Gradle will merge into a release build, read from the locked packages:

| Plugin library manifest | Merged into FitFlow? | Notes |
| --- | --- | --- |
| `flutter_local_notifications` 22.3.1 | `VIBRATE`, `POST_NOTIFICATIONS` | `VIBRATE` is a normal permission added by the plugin. `POST_NOTIFICATIONS` is already declared by FitFlow. The plugin library manifest does not declare exact alarms, full-screen intent, or foreground service. Those appear only in the plugin's example app and are not part of FitFlow. |
| `flutter_tts` 4.2.5 | No permissions | Empty plugin manifest. The example app's storage permission is not merged. |
| `android_file_picker` 2.0.0 | No storage permission | Adds a package-visibility query for `GET_CONTENT` / `*/*` so the system picker can be found. Not `QUERY_ALL_PACKAGES`. |
| `flutter_timezone` 5.1.0 | No permissions | Empty plugin manifest. |
| `shared_preferences_android` 2.4.28 | No permissions | Empty plugin manifest. |

Part 2 must still inspect the merged release manifest, because a future plugin upgrade can add permissions.

Package visibility queries, not user-data permissions:

- `android.intent.action.PROCESS_TEXT` with `text/plain` (Flutter text processing)
- `android.intent.action.TTS_SERVICE` (find the device speech engine)

These queries stay narrow. Do not add `QUERY_ALL_PACKAGES`.

## Android backup versus manual backup

The in-app promise is that workout data stays on the device unless the user creates a backup.

Configuration:

- `android:allowBackup="false"`
- `android:fullBackupContent="@xml/backup_rules"` excludes root, file, database, sharedpref, and external for Android 11 and lower
- `android:dataExtractionRules="@xml/data_extraction_rules"` excludes those domains plus device-protected domains from both cloud backup and device-to-device transfer on Android 12+
- `tools:replace` keeps a plugin from turning backup back on during manifest merge

M18 manual backup is unchanged. Schema remains `1`. No automatic-backup preference was added.

## What this audit does not prove

- The merged release manifest after Gradle plugin merge. Part 2 must inspect it.
- 16 KB native-library alignment. No AAB was built.
- Behavior of a user-selected online TTS engine.
- That a user cannot themselves save a backup file into a cloud folder through the system picker. That is a user-directed export, not a FitFlow collection.
