# Build & Submission Guide

This file is a checklist for turning the project in this zip into what
your internship task actually asks you to submit. It's not part of the
app itself — delete it (or leave it) before pushing, your call.

## What's in this zip

A complete Flutter source project with **both** platform folders
included and ready to go:
- `android/` — for running on an emulator/device and building the APK
- `web/` — for running in Chrome straight from Android Studio

Neither needs `flutter create .` run first.

**Two files are always machine-specific** and can't be shipped
pre-filled in any zip: `android/local.properties` (your local SDK
paths) and the Gradle wrapper jar. Android Studio generates both
automatically on first open/sync — you won't usually need to do
anything. These only matter if you're running on Android; Chrome/Web
doesn't need either of them at all.

## Step 1 — Open and run it

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and
   [Android Studio](https://developer.android.com/studio) (with the
   Flutter/Dart plugins). Run `flutter doctor` and resolve anything it
   flags — including making sure Chrome is detected as a device.
2. Unzip this project anywhere.
3. Android Studio → **File → Open** → select the `invoice_generator_app`
   folder. Wait for the initial sync/indexing to finish.
4. Run `flutter pub get` if it doesn't happen automatically.

**To run in Chrome:** use the device dropdown at the top of Android
Studio, select **Chrome**, and hit ▶️ Run. Or from a terminal:
```bash
flutter run -d chrome
```

**To run on Android:** pick an emulator (or a plugged-in phone with USB
debugging on) from the same dropdown instead.

## Step 2 — Generate the APK for submission

Your task says: **upload the APK only, not the project zip.** The APK
has to come from the Android build, not Web (Web doesn't produce an
APK — it produces a `build/web/` folder of static files instead).

```bash
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Check its size — the task caps it at 50MB. A Flutter release APK for an
app like this is typically well under that, but if you're near the
limit, a split-per-ABI build shrinks it a lot:

```bash
flutter build apk --release --split-per-abi
```

Upload the `arm64-v8a` variant — it covers the overwhelming majority of
Android phones from the last several years.

## Step 3 — Take your 5+ screenshots

You can take these from either Chrome or an Android emulator — Chrome
is honestly the fastest for this since there's no emulator boot time.
Capture at least 5 screens showing different functionality:
1. Dashboard (with stats populated — create 2-3 sample invoices first)
2. Invoice list (with search or filter chips visible)
3. Invoice creation form (with items added and totals showing)
4. Invoice detail screen (showing the Download PDF / Share / Print buttons)
5. Settings screen (with a logo uploaded, if possible)

Drop them into `docs/screenshots/` in the project before you push, and
swap them into `README.md`'s "Screenshots" section (there's a
commented-out image tag near the top and a placeholder table near the
bottom — replace both).

## Step 4 — Push to GitHub

```bash
git init
git add .
git commit -m "Invoice Generator App - Flutter internship task"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo-name>.git
git push -u origin main
```

If prompted for a password, GitHub requires a **Personal Access Token**
now — generate one under GitHub → Settings → Developer settings →
Personal access tokens (`repo` scope), and use it in place of the
password.

Double-check `android/local.properties` isn't tracked before you commit
(`git status` — it's already excluded by `.gitignore`).

## Step 5 — Submit

- ✅ APK file (from Step 2 — Android build, not Web)
- ✅ GitHub repo link (from Step 4)
- ✅ README.md in the repo (already included — has overview, features,
  packages, and setup instructions for both platforms; just add your
  screenshots)
- ✅ At least 5 screenshots (in the repo, referenced from the README)

## A note on the Web/Android architecture

This app is built to genuinely run on both platforms from one
codebase, not just "compile without crashing on Web." That mattered for
a few technical choices worth knowing if you get asked about them:

- **Storage** uses `hive` instead of `sqflite`, because `sqflite` has
  no Web implementation at all (it would fail to even build for
  Chrome). Hive is pure Dart and works on Web via IndexedDB.
- **PDF export, sharing, and backups** are all built from raw bytes
  (never a file path), because `dart:io` (`File`/`Directory`) and
  `path_provider` don't exist on Web either. The `printing` and
  `share_plus` packages accept bytes directly and handle the
  platform-appropriate "download" vs. "share sheet" behavior
  internally.
- **The company logo** is stored as bytes (base64-encoded in
  SharedPreferences), not a file path, for the same reason.

## A note on testing

I built and reviewed this project carefully — checked matching
constructor signatures, resolved imports, balanced brackets, and
correct package APIs across every file — but I don't have a Flutter SDK
or browser available in the environment I wrote this in, so I could not
actually run `flutter analyze` or launch the app myself. Please build
and click through it yourself (both Chrome and Android, ideally) before
submitting — if anything doesn't compile or a screen misbehaves, tell
me the exact error and I'll fix it immediately.
