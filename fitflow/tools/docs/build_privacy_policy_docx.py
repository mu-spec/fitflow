#!/usr/bin/env python3
"""Builds docs/legal/privacy-policy.docx from the facts of this repository.

The text is written against the real release configuration of the app:
  * android/app/src/main/AndroidManifest.xml  (permissions, allowBackup, queries)
  * pubspec.yaml                              (dependencies actually bundled)
  * lib/**/data/*_storage.dart                (what is persisted, and where)
  * lib/features/backup/**                    (manual backup behaviour)
  * lib/features/workout_player/**            (TTS + bundled music)
  * docs/release/data_safety_audit.md         (evidence base)
  * docs/release/play_data_safety.md          (Play Data safety answers)
  * docs/release/play_health_declaration.md   (Health apps declaration)

Only two facts are unknown to the repository and must be filled in by the
publisher: the developer/publisher name and the privacy contact address
(DEVELOPER_NAME / CONTACT_EMAIL below).

Usage:  python3 tools/docs/build_privacy_policy_docx.py
"""

from __future__ import annotations

from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor, Cm

# --------------------------------------------------------------------------
# Facts about the app (change these only if the app itself changes)
# --------------------------------------------------------------------------
APP_NAME = "Home Workout"
PROJECT_NAME = "FitFlow"
PACKAGE_ID = "com.fitflow.fitflow"
VERSION_NAME = "1.0.0"
VERSION_CODE = "1"
PLATFORM = "Android (Google Play)"
LAST_UPDATED = "16 November 2026"
EFFECTIVE = "16 November 2026"

# The only two blanks in this document.
DEVELOPER_NAME = "[developer or company name]"
CONTACT_EMAIL = "[privacy contact email]"

ACCENT = RGBColor(0x11, 0x62, 0x3A)
GREY = RGBColor(0x55, 0x5F, 0x5A)
OUT = Path(__file__).resolve().parents[2] / "docs" / "legal" / "privacy-policy.docx"


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
def shade(cell, hex_fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_fill)
    tc_pr.append(shd)


def cell_text(cell, text: str, *, bold: bool = False, size: float = 9.0,
              colour: RGBColor | None = None) -> None:
    cell.text = ""
    par = cell.paragraphs[0]
    par.paragraph_format.space_before = Pt(2)
    par.paragraph_format.space_after = Pt(2)
    run = par.add_run(text)
    run.bold = bold
    run.font.size = Pt(size)
    run.font.name = "Calibri"
    if colour is not None:
        run.font.color.rgb = colour


def add_table(doc, headers, rows, widths=None, *, first_col_bold=False,
              size: float = 9.0) -> None:
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    hdr = table.rows[0]
    for i, head in enumerate(headers):
        shade(hdr.cells[i], "E7EFEA")
        cell_text(hdr.cells[i], head, bold=True, size=size, colour=ACCENT)
    for row in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            cell_text(cells[i], value, size=size,
                      bold=(first_col_bold and i == 0))
    if widths:
        for row in table.rows:
            for i, w in enumerate(widths):
                row.cells[i].width = Cm(w)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def body(doc, text: str, *, style: str | None = None) -> None:
    par = doc.add_paragraph(style=style)
    par.paragraph_format.space_after = Pt(6)
    par.paragraph_format.line_spacing = 1.08
    run = par.add_run(text)
    run.font.size = Pt(10.5)
    run.font.name = "Calibri"


def bullets(doc, items) -> None:
    for item in items:
        par = doc.add_paragraph(style="List Bullet")
        par.paragraph_format.space_after = Pt(3)
        par.paragraph_format.line_spacing = 1.08
        if isinstance(item, tuple):
            lead, rest = item
            r = par.add_run(lead)
            r.bold = True
            r.font.size = Pt(10.5)
            r.font.name = "Calibri"
            r2 = par.add_run(rest)
            r2.font.size = Pt(10.5)
            r2.font.name = "Calibri"
        else:
            r = par.add_run(item)
            r.font.size = Pt(10.5)
            r.font.name = "Calibri"


def section(doc, number: int, title: str) -> None:
    heading = doc.add_heading(f"{number}. {title}", level=1)
    heading.paragraph_format.space_before = Pt(14)
    heading.paragraph_format.space_after = Pt(5)
    for run in heading.runs:
        run.font.size = Pt(13)
        run.font.name = "Calibri"
        run.font.color.rgb = ACCENT
        run.bold = True


def callout(doc, text: str) -> None:
    table = doc.add_table(rows=1, cols=1)
    table.style = "Table Grid"
    cell = table.rows[0].cells[0]
    shade(cell, "F4F7F5")
    par = cell.paragraphs[0]
    par.paragraph_format.space_before = Pt(4)
    par.paragraph_format.space_after = Pt(4)
    run = par.add_run(text)
    run.font.size = Pt(10)
    run.font.name = "Calibri"
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_page_field(par) -> None:
    for instr in ("PAGE", "NUMPAGES"):
        fld = OxmlElement("w:fldSimple")
        fld.set(qn("w:instr"), instr)
        run = OxmlElement("w:r")
        txt = OxmlElement("w:t")
        txt.text = "1"
        run.append(txt)
        fld.append(run)
        par._p.append(fld)
        if instr == "PAGE":
            par.add_run(" of ")


# --------------------------------------------------------------------------
# Document
# --------------------------------------------------------------------------
def build() -> Path:
    doc = Document()

    # Page setup: A4, 2.2 cm margins.
    sec = doc.sections[0]
    sec.page_width = Cm(21.0)
    sec.page_height = Cm(29.7)
    sec.top_margin = Cm(2.2)
    sec.bottom_margin = Cm(2.0)
    sec.left_margin = Cm(2.2)
    sec.right_margin = Cm(2.2)

    base = doc.styles["Normal"]
    base.font.name = "Calibri"
    base.font.size = Pt(10.5)
    base.paragraph_format.space_after = Pt(6)

    # Header / footer
    header_par = sec.header.paragraphs[0]
    header_par.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hr = header_par.add_run(f"{APP_NAME} — Privacy Policy")
    hr.font.size = Pt(8)
    hr.font.color.rgb = GREY
    hr.font.name = "Calibri"

    footer_par = sec.footer.paragraphs[0]
    footer_par.alignment = WD_ALIGN_PARAGRAPH.CENTER
    fr = footer_par.add_run(f"{APP_NAME} ({PACKAGE_ID}) · Last updated {LAST_UPDATED} · Page ")
    fr.font.size = Pt(8)
    fr.font.color.rgb = GREY
    fr.font.name = "Calibri"
    add_page_field(footer_par)

    # Core properties
    doc.core_properties.title = f"{APP_NAME} — Privacy Policy"
    doc.core_properties.subject = "Privacy policy for the Home Workout Android app"
    doc.core_properties.author = "Home Workout (FitFlow)"
    doc.core_properties.comments = (
        "Describes the release build of Home Workout (com.fitflow.fitflow). "
        "Fill in the developer name and privacy contact email before publishing."
    )

    # ---------------- Title block ----------------
    title = doc.add_paragraph()
    title.paragraph_format.space_after = Pt(0)
    t_run = title.add_run("Privacy Policy")
    t_run.font.size = Pt(26)
    t_run.font.bold = True
    t_run.font.name = "Calibri"
    t_run.font.color.rgb = ACCENT

    sub = doc.add_paragraph()
    sub.paragraph_format.space_after = Pt(10)
    s_run = sub.add_run(f"{APP_NAME} (project name: {PROJECT_NAME})")
    s_run.font.size = Pt(12)
    s_run.font.color.rgb = GREY
    s_run.font.name = "Calibri"

    add_table(
        doc,
        ["Item", "Detail"],
        [
            ["App name", f"{APP_NAME}"],
            ["Package name", PACKAGE_ID],
            ["Platform", PLATFORM],
            ["App version covered", f"{VERSION_NAME} (version code {VERSION_CODE})"],
            ["Developer / publisher", DEVELOPER_NAME],
            ["Privacy contact", CONTACT_EMAIL],
            ["Last updated", LAST_UPDATED],
            ["Effective date", EFFECTIVE],
        ],
        widths=[5.0, 11.6],
        first_col_bold=True,
    )

    # ---------------- 1. Summary ----------------
    section(doc, 1, "Summary")
    body(doc, (
        f"{APP_NAME} is a home workout app that runs entirely on your phone. It does not create an "
        "account, does not ask for your name, email address, phone number or date of birth, and does "
        "not send your workout information to us or to anyone else. The published release build does "
        "not declare the Android internet permission, so the app cannot upload your data even in "
        "principle."
    ))
    body(doc, (
        "Everything you enter — your training preferences, your capability answers, the workouts you "
        "finish, your custom workouts and your reminder settings — is stored in the app's private "
        "storage on your own device. It leaves the device only if you personally create a backup file "
        "and choose where to save it. Deleting the app deletes that data."
    ))
    callout(doc, (
        "In one line: no account, no server, no ads, no analytics, no data sale — your fitness data "
        "stays on your device unless you export it yourself."
    ))

    # ---------------- 2. Who we are ----------------
    section(doc, 2, "Who we are, and what this policy covers")
    body(doc, (
        f"This policy is published by {DEVELOPER_NAME} (“we”, “us”), the developer of the Android app "
        f"{APP_NAME} (package name {PACKAGE_ID}, project name {PROJECT_NAME}). It explains what the app "
        "does with information, and it applies to the app as distributed through Google Play, including "
        "the copy installed on your device and any updates you install."
    ))
    body(doc, (
        "This policy does not apply to Google Play itself, to your device manufacturer's software, to "
        "the text-to-speech engine installed on your device, or to any other app or service you use "
        "alongside this one. Those are governed by their own policies."
    ))

    # ---------------- 3. What we do not collect ----------------
    section(doc, 3, "Information we do not collect")
    body(doc, (
        f"{APP_NAME} does not collect, request or transmit any of the following, and the release build "
        "contains no component that would:"
    ))
    bullets(doc, [
        ("Account details — ", "there is no sign-up, sign-in, password, email address or profile name."),
        ("Identity and contact data — ", "no name, email, phone number, postal address or contacts. "
                                          "The app does not request the contacts permission."),
        ("Body measurements and demographics — ", "no age, date of birth, sex, height, weight, body-fat "
                                                   "percentage or photographs."),
        ("Location — ", "no GPS, network or coarse location. The app declares no location permission."),
        ("Camera, microphone and files — ", "no camera or microphone access and no permission to read "
                                            "your photos, music or general storage. The only file the app "
                                            "writes is a backup file you explicitly ask it to save."),
        ("Advertising identifiers — ", "no advertising ID, no device fingerprinting, no attribution SDK."),
        ("Usage analytics and diagnostics — ", "no analytics SDK, no crash-reporting SDK and no remote "
                                               "configuration. Nothing is reported back to us when you use the app."),
        ("Health platform data — ", "the app does not connect to Health Connect and does not read or write "
                                    "platform health records."),
        ("Payment data — ", "the app has no purchases, subscriptions or payment processing."),
    ])

    # ---------------- 4. What is stored on the device ----------------
    section(doc, 4, "Information the app stores on your device")
    body(doc, (
        "The app keeps the following records in Android's private app storage for this package "
        f"({PACKAGE_ID}). This storage is not readable by other apps. None of it is transmitted off your "
        "device by the app."
    ))
    add_table(
        doc,
        ["What is stored", "Details", "Why the app keeps it"],
        [
            ["Fitness profile",
             "Your main goal, experience level, typical workout length, training environment, available "
             "equipment and optional workout preferences. No name, age, sex, height or weight.",
             "To build workouts suited to you."],
            ["Capability profile",
             "Your self-reported comfort level for 10 movement patterns (push, pull, squat, lunge, hinge, "
             "core, glute, cardio, mobility, balance).",
             "To choose exercises you can do safely at your level."],
            ["Workout history",
             "Up to the 100 most recent completed workouts: completion date and time, exercise list, sets, "
             "and planned versus estimated durations.",
             "To show your progress and adapt future sessions."],
            ["Adaptive progression records",
             "Evidence the app uses to decide when to make an exercise harder or easier.",
             "To adjust difficulty over time."],
            ["Programme progress",
             "Which adaptive programme you started, and which week and session you are on.",
             "To resume your programme where you left off."],
            ["Custom workouts",
             "Any workout you build yourself: the name you type for it, its exercises, sets and repetitions.",
             "To let you reuse your own routines."],
            ["Reminder settings",
             "Chosen weekdays, time of day and on/off state for workout reminders.",
             "To schedule local reminder notifications."],
            ["App and audio preferences",
             "Light/dark/system appearance, and workout music on/off, track choice and volume.",
             "To remember how you set up the app."],
        ],
        widths=[3.6, 7.6, 5.4],
        first_col_bold=True,
    )
    body(doc, (
        "There is no field in the app for a name, email address, phone number, date of birth or body "
        "measurement, so none of that can be stored even if you wanted to enter it. The only text you can "
        "type about yourself is the name you give your own custom workout, which stays on your device."
    ))

    # ---------------- 5. Permissions ----------------
    section(doc, 5, "Permissions the app requests, and what they can and cannot do")
    add_table(
        doc,
        ["Permission", "Why the app asks for it", "What it does not allow"],
        [
            ["Notifications (POST_NOTIFICATIONS, Android 13 and later)",
             "To show the workout reminders you switch on. The app asks at the moment you enable a "
             "reminder, and you can refuse or revoke it in system settings.",
             "It cannot show ads, promotions or messages from us. Reminders are the only notifications "
             "the app produces."],
            ["Run after restart (RECEIVE_BOOT_COMPLETED)",
             "To restore your saved reminders after your phone restarts, so a reminder is not silently lost.",
             "It does not start the app in the background for any other purpose."],
            ["Internet — NOT declared in the release build",
             "The published app does not request internet access at all. Only development builds, which "
             "you never install from Google Play, declare it so a debugger can attach.",
             "The published app cannot open a network connection, upload data or download updates on "
             "its own."],
        ],
        widths=[4.4, 6.6, 5.6],
        first_col_bold=True,
    )
    body(doc, (
        "The app declares no location, contacts, camera, microphone, broad storage, exact-alarm, "
        "accessibility-service, advertising-ID or health permissions, and it does not ask for the "
        "“query all packages” permission."
    ))
    body(doc, (
        "On Android 11 and later, the app declares three narrow package-visibility queries so that "
        "system features can be found: Android's own text-processing action, the device text-to-speech "
        "service (used for voice coaching), and https links (used only when you tap “Open full policy in "
        "browser”). These queries are not permissions to read your data; they only let the app ask the "
        "system which app can handle a request you started."
    ))

    # ---------------- 6. Android backup ----------------
    section(doc, 6, "Android automatic backup and device-to-device transfer")
    body(doc, (
        "The app opts out of Android's automatic cloud backup and device-to-device transfer of its data "
        "(the release configuration sets android:allowBackup=\"false\" and ships backup and data-extraction "
        "rules that exclude the app's storage, including its preferences). As a result, your workout data "
        "is not copied to your Google account or to a new phone by the operating system on our behalf. If "
        "you want to move your data to a new device, you use the manual backup described next."
    ))

    # ---------------- 7. Manual backup ----------------
    section(doc, 7, "Manual backup and restore (a file you create)")
    body(doc, (
        "The app can export your data to a backup file and read it back later. This only happens when you "
        "start it from the app's settings. The app hands the file to Android's own save dialog, and the "
        "system dialog chooses the destination — local storage, an SD card, or a cloud folder you have "
        "connected to your device, such as your own Google Drive."
    ))
    bullets(doc, [
        ("The file is a plain JSON document ", "marked as a “fitflow_backup” file with a .json extension "
                                               "and a schema version. It contains the profile, capability, history, "
                                               "progression, programme, custom-workout and preference data listed above. "
                                               "It is not encrypted, so treat it like any other personal document."),
        ("We never receive the file. ", "There is no upload step and no FitFlow account. If you save it to a "
                                        "cloud folder, that copy is stored and protected under that provider's terms, not ours."),
        ("Restoring reads a file you pick. ", "The app opens Android's file picker, validates the file, and "
                                             "replaces the matching local data only after you confirm."),
        ("Backup files outlive the app. ", "Uninstalling the app does not delete a backup file you created; "
                                          "delete it yourself from wherever you saved it."),
    ])

    # ---------------- 8. Voice coaching ----------------
    section(doc, 8, "Voice coaching (device text-to-speech)")
    body(doc, (
        "During a workout the app can speak short coaching cues such as a countdown or the name of the "
        "next exercise. The text is synthesized by the text-to-speech engine already installed on your "
        "device, through Android's standard speech service."
    ))
    bullets(doc, [
        ("We do not run a speech server. ", "Coaching text is not sent to us. There is no FitFlow server "
                                            "anywhere in this path."),
        ("Your engine, your rules. ", "We do not choose, control or certify the speech engine on your "
                                      "device. Most engines work offline, but an engine you selected — or a "
                                      "voice you downloaded — may process text online, in which case that "
                                      "provider's own privacy policy applies to it. You can check or change "
                                      "your engine in Android's text-to-speech settings."),
        ("You are in control. ", "Voice coaching can be switched off during a workout, and if the engine "
                                 "is unavailable the app simply stays silent; the workout continues normally."),
    ])

    # ---------------- 9. Music ----------------
    section(doc, 9, "Workout music and audio")
    body(doc, (
        "The workout music track (“EDM Detection Mode”) is shipped inside the app and played from local "
        "storage. The app does not stream music, does not download tracks, does not use a third-party "
        "music service, and does not record or analyse what you listen to. Playing audio uses the phone's "
        "own audio system, which means your device may pause or duck other audio — that behaviour is part "
        "of Android, not data collection."
    ))

    # ---------------- 10. Ads / analytics / sale ----------------
    section(doc, 10, "Advertising, analytics and sale of data")
    body(doc, (
        "The app contains no advertising SDK and no analytics SDK. We do not sell or rent personal data, "
        "and we do not use your data for advertising, profiling or credit decisions. We do not use your "
        "data for any purpose other than providing the workout features described in this policy. Because "
        "the app transmits nothing, there is no data for us to share with advertisers, data brokers or "
        "business partners."
    ))

    # ---------------- 11. Sharing ----------------
    section(doc, 11, "When information can leave your device")
    body(doc, (
        "The app itself does not share your information. The only situations in which data can leave your "
        "device are ones you initiate or that belong to your operating system:"
    ))
    bullets(doc, [
        ("A backup you export ", "to a destination you pick with Android's save dialog, including a cloud "
                                 "folder connected to your device."),
        ("Your device's text-to-speech engine, ", "if you have configured one that processes speech online."),
        ("The browser, ", "if you tap “Open full policy in browser”. Opening a web page is a normal browser "
                          "visit; it does not send the app any of your workout data. The app passes only the "
                          "policy address, not your data."),
        ("Android and your device maker, ", "for ordinary operating-system functions such as notifications, "
                                            "storage and time zone. This is not controlled by the app."),
        ("Legal requirements. ", "We hold no data about you, so we have nothing to disclose. If a lawful "
                                 "request were ever made, we could not comply beyond confirming that we hold nothing."),
    ])

    # ---------------- 12. Retention and deletion ----------------
    section(doc, 12, "Retention and deletion")
    bullets(doc, [
        ("How long data is kept: ", "until you delete it. The app keeps your records on the device "
                                    "indefinitely while it is installed, apart from workout history, which is "
                                    "capped at the 100 most recent workouts."),
        ("Delete everything: ", "open Android Settings → Apps → Home Workout → Storage → Clear storage, or "
                                "uninstall the app. Both remove the app's private data from the device, "
                                "including your workout history."),
        ("Backup files: ", "a backup file you created is not deleted by uninstalling the app. Delete it where "
                           "you saved it."),
        ("No deletion request is needed. ", "We cannot access, retrieve or delete your data because we never "
                                            "receive it. There is no account to close and no server record to erase."),
    ])

    # ---------------- 13. Security ----------------
    section(doc, 13, "How your data is protected")
    body(doc, (
        "Your data is stored in the app's private, sandboxed storage area, which other apps cannot read on a "
        "device that has not been rooted. Because the app does not transmit data, there is no network "
        "transfer to intercept and no server that could be breached, and there is no FitFlow account or "
        "password that could be stolen."
    ))
    body(doc, (
        "The protection of the device itself is provided by Android and by you: keep your screen lock on, "
        "keep your device encrypted, and install app updates. Note that a backup file you export is not "
        "encrypted by the app — store it somewhere you trust, and delete copies you no longer need."
    ))

    # ---------------- 14. Children ----------------
    section(doc, 14, "Children")
    body(doc, (
        "The app is intended for adults and is not directed at children. It does not knowingly collect any "
        "information from anyone, including children, because it collects no information at all. It shows "
        "no advertising and has no social, messaging or user-generated-content features. If a parent or "
        "guardian has a concern, they can remove all app data by clearing storage or uninstalling the app."
    ))

    # ---------------- 15. Health disclaimer ----------------
    section(doc, 15, "Health, fitness and medical disclaimer")
    body(doc, (
        "The app provides general fitness and workout functionality: exercise routines, capability-based "
        "workout selection, reminders and local progress tracking. It does not diagnose disease, does not "
        "treat medical conditions, is not a medical device, and does not claim any rehabilitation "
        "function. It does not read or write platform health records."
    ))
    body(doc, (
        "The exercise animations and audio are demonstrations only. They are not personal instruction, they "
        "have not been checked by an exercise professional, and they do not certify that an exercise is "
        "suitable or safe for you. Consult a qualified professional before starting a new exercise "
        "programme, and stop if you feel pain, dizziness or discomfort."
    ))

    # ---------------- 16. Credits + OSS ----------------
    section(doc, 16, "Artwork credits and open-source software")
    body(doc, (
        "Some exercise animations are adapted from third-party artwork published under licences that require "
        "credit and require the licence text to travel with the work. The app therefore includes an "
        "“Exercise artwork credits” screen in its settings, which reads the credit and licence files bundled "
        "inside the app. It works offline and collects nothing."
    ))
    body(doc, "Sources credited in the app include:")
    bullets(doc, [
        "Wikimedia Commons exercise GIFs by Danielflefil, licensed under Creative Commons "
        "Attribution-ShareAlike 4.0 International (CC BY-SA 4.0), resized and re-encoded for mobile.",
        "Lottie exercise animations by Dinh Bui Xuan, licensed under the Lottie Simple License (FL 9.13.21).",
        "Open Exercise Figures pose artwork released under CC0 1.0.",
    ])
    body(doc, (
        "These creators license their artwork to this app; they do not sponsor, endorse or support the app, "
        "and they are not responsible for how it is used. The app itself is also built on open-source "
        "software: Flutter and flutter_localizations (BSD-3-Clause), flutter_riverpod, go_router, "
        "shared_preferences, just_audio and audio_session, flutter_tts, flutter_local_notifications, "
        "timezone and flutter_timezone, file_picker, lottie, url_launcher, and intl. Each is used under its "
        "own licence, and none of them is an analytics, advertising or tracking component."
    ))

    # ---------------- 17. Your rights ----------------
    section(doc, 17, "Your privacy rights")
    body(doc, (
        "Privacy laws such as the GDPR and the CCPA/CPRA give people rights over personal data held about "
        "them — to access it, correct it, delete it, port it, restrict its use, or object to it, and not to "
        "be discriminated against for exercising those rights. In this app those rights are satisfied "
        "directly on your device, because that is the only place the data exists:"
    ))
    bullets(doc, [
        ("Access and portability: ", "your data is visible in the app, and the manual backup exports it in a "
                                      "standard JSON file you can keep or move."),
        ("Correction: ", "you can edit your fitness profile, your custom workouts, your reminders and "
                         "your appearance and audio settings inside the app at any time. Your movement-"
                         "capability answers are set once during the first-run assessment and are not "
                         "editable afterwards, but they contain no identifying detail."),
        ("Erasure: ", "clearing app storage or uninstalling the app deletes your data."),
        ("No sale, no sharing: ", "we have never sold or shared your data, and we do not process it for "
                                  "targeted advertising."),
    ])
    body(doc, (
        f"If you believe the app does not meet these rights, contact us at {CONTACT_EMAIL}. You also have the "
        "right to complain to your local data-protection authority."
    ))

    # ---------------- 18. Play Data safety ----------------
    section(doc, 18, "Google Play Data safety summary")
    body(doc, (
        "The declarations below are the ones the app makes in Google Play's Data safety section. They are "
        "reproduced here so this policy and the store listing say the same thing."
    ))
    add_table(
        doc,
        ["Question in Play's Data safety form", "Answer for this app"],
        [
            ["Does the app collect or share any of the required user data types?",
             "No. The app has no account, no server, no ads SDK and no analytics SDK. Data stays on the "
             "device, and a backup is only exported where the user chooses."],
            ["Is all of the user data encrypted in transit?",
             "No data is transmitted by the app, so there is no in-transit pipeline to encrypt."],
            ["Does the app provide a way for users to request that their data is deleted?",
             "Yes — deleting the data is done on the device: clear app storage or uninstall the app. "
             "There is no account and no server-side copy, so no deletion request or external deletion "
             "link is required."],
            ["Which data types are declared as collected or shared?",
             "None. For transparency, the kinds of information the app handles on the device only are "
             "fitness and activity data (capability answers, workout history, progression), profile "
             "preferences, app settings and user-created files (custom workouts and backup files). None "
             "of these is collected by the developer or shared with third parties."],
            ["Health apps declaration", "Health and fitness → Activity and Fitness, as a general fitness "
                                        "app; not a medical device, no diagnosis or treatment claims."],
        ],
        widths=[6.2, 10.4],
    )

    # ---------------- 19. Changes ----------------
    section(doc, 19, "Changes to this policy")
    body(doc, (
        f"This policy was last updated on {LAST_UPDATED}. If the app's behaviour changes in a way that "
        "affects your privacy — for example if a future version adds an online feature — this policy will "
        "be updated before that version is published, and the “Last updated” date above will change. "
        "Continuing to use a version of the app after its policy is updated means the updated policy "
        "applies to that version. The current version of this policy is always the one shipped with, or "
        "linked from, the app."
    ))

    # ---------------- 20. Contact ----------------
    section(doc, 20, "Contact us")
    body(doc, (
        "Questions about this policy, or about how the app handles information, can be sent to:"
    ))
    contact = doc.add_paragraph()
    contact.paragraph_format.left_indent = Cm(0.6)
    c1 = contact.add_run(f"{DEVELOPER_NAME}\n{CONTACT_EMAIL}\n")
    c1.font.size = Pt(10.5)
    c1.bold = True
    c2 = contact.add_run(
        f"Developer of {APP_NAME} (package {PACKAGE_ID}). Please include the app version and your Android "
        "version so we can answer accurately. We aim to reply within a reasonable time, and we do not "
        "require you to identify yourself to ask a question."
    )
    c2.font.size = Pt(10.5)

    closing = doc.add_paragraph()
    closing.paragraph_format.space_before = Pt(12)
    cr = closing.add_run(f"— End of policy —")
    cr.font.size = Pt(9)
    cr.font.color.rgb = GREY
    cr.alignment = WD_ALIGN_PARAGRAPH.CENTER

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    return OUT


if __name__ == "__main__":
    path = build()
    print(f"wrote {path} ({path.stat().st_size} bytes)")
