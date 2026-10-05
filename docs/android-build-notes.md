---
status: current
type: reference
---

# Android build notes: Kotlin warning, built-in Kotlin, secure storage upgrade

Findings from 2026-10-02 (Flutter 3.44.8, AGP 9.0.1, Kotlin 2.3.20). Read this before touching
`android/gradle.properties`, upgrading `camera`, `firebase_core`, `package_info_plus` or
`flutter_secure_storage`, or when someone asks "why does every build print a Kotlin warning?".

## 1. The warning every `flutter run` / `flutter build` prints

```
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): firebase_core
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.
```

**It is harmless today.** The build completes. Do not "fix" it by hand.

- Flutter is moving to *built-in Kotlin* (AGP 9+), where plugins stop applying the Kotlin Gradle Plugin (KGP)
  themselves. Docs: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers
- Flutter finds offenders by **regex-scanning each plugin's `android/build.gradle` text** for `kotlin-android`
  (`FlutterPluginUtils.kt`, `detectApplyingKotlinGradlePlugin`). It does not evaluate conditions, so a plugin that has
  already migrated but still contains a guarded line is listed anyway. Tracked in flutter/flutter#189770; the fix
  (flutter/flutter PR #190339, check the plugins that *actually* applied KGP) was still open on 2026-10-02.
- **`firebase_core` 4.15.0** only applies KGP conditionally:
  `if (agpMajor < 9 || !builtInKotlin) { apply plugin: 'kotlin-android' }`. It is a false positive. The Firebase team
  said they will remove the remaining apply when they raise their minimum Flutter SDK (flutterfire#18715). Because this
  app sets `android.builtInKotlin=false` (section 2), the guard is true and the plugin does apply KGP here, which is the
  supported legacy path.
- **There is no flag, Gradle property or setting that turns the warning off.** It is silent only on AGP < 9, or when no
  plugin matches the scan. Options we rejected: editing the plugin in the pub cache (lost on `pub get`, not shared with
  other machines/CI), vendoring a patched `firebase_core` via `dependency_overrides` (a fork to maintain), and
  filtering console output in `scripts\*.bat` (hides real warnings too). Decision: leave it.
- Expect it to disappear on its own once Flutter ships PR #190339 or `firebase_core` drops the line. Re-check after
  each Flutter or Firebase upgrade.

## 2. Keep `android.builtInKotlin=false`

`android/gradle.properties` must keep:

```
android.newDsl=false
android.builtInKotlin=false
```

We tested `android.builtInKotlin=true` (2026-10-02): **`flutter build apk --debug` fails** in
`camera_android_camerax` 0.7.4+8 (a transitive plugin of `camera: ^0.12.1`) with
"The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0". It puts KGP on its own
buildscript classpath and uses a `kotlin { }` block.

- **The warning's plugin list is incomplete.** `camera_android_camerax` blocks built-in Kotlin but is *not* named in the
  warning (its build file is `build.gradle.kts` and does not contain the scanned text). Do not assume "the warning
  lists one plugin, so only that one blocks us".
- `camera_android_camerax` 0.7.5+1 exists but did not install: it is held back by the `camera` version. We did not test
  whether 0.7.5+1 fixes it.
- The app's own `android/app/build.gradle.kts` is already migrated (no `kotlin-android` plugin; it uses a top-level
  `kotlin { compilerOptions { jvmTarget = JVM_17 } }` block).

**To enable built-in Kotlin later:**
1. Upgrade `camera` so it resolves a `camera_android_camerax` that supports built-in Kotlin, then re-test live document
   capture (`LiveCameraCaptureScreen`) on a device.
2. Set `android.builtInKotlin=true`, run `flutter build apk --debug`, then a release build.
3. Install a release APK on a device and smoke-test.
4. Re-scan the other plugins: a plugin that unconditionally applies KGP fails the build once the flag is true.

## 3. `flutter_secure_storage` / `package_info_plus` upgrade (applied in the working tree, not yet device-verified)

Why: `package_info_plus` 8.3.1 applies KGP unconditionally (a real use of the old approach); 10.2.0+ adds built-in Kotlin
support. 10.1+ needs `win32` ^6, which conflicts with `flutter_secure_storage` 9.x (`flutter_secure_storage_windows`
needs `win32` ^5), so both must move together.

Resolved set (`pubspec.yaml`: `flutter_secure_storage: ^10.3.1`, `package_info_plus: ^10.2.2`):

| Package | Before | After |
|---|---|---|
| `flutter_secure_storage` | 9.2.4 | 10.3.4 |
| `package_info_plus` | 8.3.1 | 10.2.2 |
| `win32` | 5.15.0 | 6.4.0 |
| `flutter_secure_storage_macos` / `js` | present | dropped (replaced by `flutter_secure_storage_darwin`) |

Verified: `flutter pub get`, `flutter analyze lib test` (same 37 info lints as before, none new), `flutter test`
(37/37), `flutter build apk --debug`. The warning then names only `firebase_core`. No Dart change was needed: all six
stores (`session_service`, `request_passcode_store`, `deleted_requests_store`, `rejected_bookings_store`,
`request_progress_history_store`, `time_format_service`) use the default `const FlutterSecureStorage()`. Requirements:
Java 17 (already used) and iOS 12+ (the app targets 16).

**Why 10.3.x and not 11.x:** 11.0 removes the old Android algorithms (`RSA_ECB_PKCS1Padding`,
`AES_CBC_PKCS7Padding`, `encryptedSharedPreferences`) and raises minSdk to 24. 10.x auto-migrates the old storage;
jumping from 9 straight to 11 risks data loss (11.1 added `checkUpgradeStatus()` to report exactly that). Upgrade 9 ->
10 -> later 11, not 9 -> 11.

### Risk: existing installs (must be tested before release)
10.x replaces how Android encrypts stored values and migrates them on first launch. `resetOnError` now defaults to
`true`, so if the migration or a decrypt fails, stored data is **wiped silently**. Worst case per user:

- Logged out once (`SessionService` keys are gone), so they log in again.
- The on-device rejected-bookings list (`RejectedBookingsStore`) is lost.
- Requests the user deleted (`DeletedRequestsStore`) can reappear.
- Request passcodes are refetched from the API, so no loss.

None of this is a security or money problem, but users would see it.

**Upgrade test (do this before committing/releasing):**
1. Install the currently published build, log in, create some local state (reject a booking, delete a request).
2. Install the new build **over it without uninstalling**.
3. Confirm you are still logged in and the lists are intact. Repeat on a physical device, not only the emulator.

Also noted: `SessionService.getSession` has no try/catch around `read`; make sure the caller (splash auto-login) handles
a thrown storage error.

**Undo:** `git checkout -- pubspec.yaml pubspec.lock macos/Flutter/GeneratedPluginRegistrant.swift`.

## 4. Release builds strip the notification sounds unless `res/raw/keep.xml` exists

Found 2026-10-05 on a physical device (fix confirmed there the same day): custom sounds never played in a release APK (default sound, or silence on the
`_v2` channels), while debug worked. `aapt2 dump resources app-release.apk` showed **no `raw/` resources at all**.
Release resource shrinking removed `res/raw/job_request.ogg`, `booking_update.ogg`, `announcement.ogg` because the code
only refers to them by name at runtime (`RawResourceAndroidNotificationSound('job_request')`). `ic_notification` survived
only because the manifest references it directly.

- **Fix:** `android/app/src/main/res/raw/keep.xml` (`tools:keep="@raw/job_request,@raw/booking_update,@raw/announcement"`).
  Add any new sound name there too.
- **Verify every release build that touches sounds or other name-referenced resources.** Release APK paths are renamed
  (`res/Ns.ogg`), so look up by resource name:
  `<sdk>/build-tools/36.0.0/aapt2 dump resources app-release.apk | grep -E "raw/|ic_notification"` and expect the three
  `raw/` entries.
- **Channels are immutable once created.** Phones that ran the broken build already have `job_requests_v2`,
  `booking_updates_v2` and `announcements_v2` pointing at missing files. Uninstall the app (or delete the channels in
  system settings) before re-testing, or mint new channel ids.
- **iOS has no equivalent problem**: there is no resource shrinking, and the `.wav` files are bundled as plain resources
  (registered in `ios/Runner.xcodeproj/project.pbxproj`). Format rules to keep for any new sound: linear PCM / IMA4 /
  mu-law / a-law in `.wav`/`.aif`/`.caf`, under 30 seconds. Current files are 16-bit PCM, 1 to 3 s.
- The Push Tester option "Send on the type's Android channel" off = `high_importance_channel` (default sound, by
  design); on = the `_v2` channel (custom sound).

## 5. Quick reference

| Question | Answer |
|---|---|
| Can I hide the Kotlin warning? | No supported way. Leave it. |
| Can I set `android.builtInKotlin=true`? | Not yet: `camera_android_camerax` breaks the build. See section 2. |
| Is the `firebase_core` entry a real problem? | No. Guarded line, false positive. |
| Why is `package_info_plus` on 10.x? | Real built-in-Kotlin support; needs the secure-storage upgrade (`win32` 6). |
| Upgrading `flutter_secure_storage` to 11? | Not directly from 9. Go through 10.x, and test data migration. |

Sources: Flutter built-in Kotlin guide (link above); https://github.com/flutter/flutter/issues/189770;
https://github.com/flutter/flutter/pull/190339; https://github.com/firebase/flutterfire/issues/18715;
https://github.com/fluttercommunity/plus_plugins/issues/3830;
https://pub.dev/packages/flutter_secure_storage/changelog; https://pub.dev/packages/package_info_plus/changelog.
