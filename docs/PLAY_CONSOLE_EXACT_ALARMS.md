# Google Play Console — Exact alarms (`SCHEDULE_EXACT_ALARM`)

This app declares `android.permission.SCHEDULE_EXACT_ALARM` so study plan reminders can fire at user-chosen times when the user opts in via **Open settings** on the “Precise reminder times” dialog (after creating or editing a study plan).

## What you must do in Play Console

1. Open **Google Play Console** → your app → **Policy** → **App content** (or **Sensitive app permissions** / **Permissions and APIs** depending on Console layout).
2. Find **Exact alarm permission** / **Alarms & reminders** declaration.
3. Declare that the app uses exact alarms for **user-initiated, scheduled reminders** (study plans the user creates in the app).
4. Confirm the app provides a way for users to understand and control this (in-app rationale + optional skip; users can disable reminders via system notification settings).

## Policy reference

- [Use exact alarms permission](https://support.google.com/googleplay/android-developer/answer/14014820)

## Technical note

If the user skips “Alarms & reminders”, reminders still schedule with `preciseAlarm: false` (inexact timing, acceptable for study reminders).
