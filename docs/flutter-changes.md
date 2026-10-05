---
status: current
version: 1.8.0
---

# Flutter App Changes Tracker

Running checklist of backend changes that the Flutter app needs to adopt to complete a feature's integration, or that are being deliberately held back as breaking changes pending approval. Updated incrementally as each backend feature lands — **`api.txt` (repo root, currently v3.33) is the exact, authoritative request/response contract of every endpoint referenced below**; read the cited `api.txt` section before implementing, since this file only summarizes.

Sections are removed once the Flutter app has fully adopted them — this file tracks *pending/active* work, not a history of everything ever shipped. Completed feature history lives in git log and `api.txt`'s own version notes, not here.

**Standing constraint (2026-09-21):** the Flutter app is live on the Play Store and App Store, both of which have review/approval lag, while the backend/API can be updated instantly. Every backend change in this project is therefore built to be **additive and optional** — a currently-published app build must keep working completely unchanged against the updated backend, with zero risk of breakage while store approval for the new app version is pending. New fields on existing endpoints are nullable/optional with a legacy fallback; new endpoints are new routes an old app simply never calls. Nothing here is a hard cutover.

Legend:
- **Available now** — backend is live, app can adopt whenever convenient (non-breaking, optional).
- **Held for approval** — a genuinely breaking change to a live endpoint contract (not just optional-field additions) that hasn't been implemented at all yet; listed here so the scope is visible ahead of time. Per the constraint above, when these are eventually implemented they should also default to an optional/additive interim contract rather than a hard break, unless explicitly decided otherwise at that time.
- **TODO(remove after old app retired)** — inline code/doc comments marking legacy-fallback branches that exist ONLY to support currently-published app builds. Once the new app version is confirmed live on both stores (i.e. no meaningfully active install base still hits these code paths), these branches can be deleted — grep the codebase for this exact marker to find all of them. Do not remove any of these until that confirmation, even if it looks safe.

---

## Forced-update block from the `app_update` push - app done, backend delivered (api.txt v3.34), device test pending

The backend now sends `latest_version`, `store_url` and an informational `platform` per platform (api.txt "Push payload
contract"; test cases in `docs/notification-testing.md` section 11). The app implements this as described below and
does not read `platform`.

**`force_update` (api.txt, always `"true"` or `"false"` on `app_update`):** `"true"` or a missing key blocks as
described below. `"false"` shows the dismissable "Update available" dialog instead (body = the notification body,
"Update now" opens the store, "Maybe later" dismisses) and persists nothing. The dialog is shown when the push arrives
in the foreground or is tapped (also cold start, once the first real screen is up), only if installed < `latest_version`,
at most once per version per launch (the splash config check and the push do not repeat each other), and never over
an existing block. Test cases 14 to 21 in `docs/notification-testing.md` section 11.

The app now blocks itself (full-screen, non-dismissable, single "Update Now" button that opens the store) when an
`app_update` push announces a version newer than the installed one. The comparison is done on the device, so the push
must **carry the version in its FCM data map**. New optional data keys, only on `type = app_update` (channel
`announcements_v2`):

| Key | Required | Example | Meaning |
|---|---|---|---|
| `latest_version` | yes | `1.0.5` | The version users must be on. The app blocks only if installed < this (numeric per segment, `+build` ignored). Absent or empty: the app ignores the push for blocking purposes. |
| `store_url` | no | `https://play.google.com/...` | Store listing for this platform. If empty the app falls back to `store_url` from `GET /api/v1/app/config`. |

Behaviour to know about:
- Android and iOS are told apart by who receives the push (the broadcast is already per platform), so send each
  platform its own `store_url`.
- The requirement is persisted on the device, so an old install stays blocked across restarts until it is updated. It is
  recorded when the push arrives in the foreground, when it is tapped (including a cold start) and, on Android, from the
  data-only background handler. If the user never taps and the OS does not wake the handler (iOS without
  `content-available`), the existing splash check against `GET /api/v1/app/config` is still the safety net.
- Installs already on `latest_version` or newer are never blocked, and the stored requirement is cleared once the app
  updates.
- Builds without this change ignore the extra data keys, so sending them early is safe (additive).
- Code: `lib/utils/update_block.dart`, `lib/widgets/update_block_host.dart` (wraps the navigator via
  `MaterialApp.builder`), tests in `test/update_block_test.dart`.

Still to verify on a device: send an `app_update` with a higher `latest_version` to a build on a lower version (blocks,
button opens the store, survives a restart) and to a build on the same version (does nothing).

---

## Notification appearance, channels and sounds - remaining verification

Still open:
- **Sounds on Android: fixed and confirmed on a physical device (2026-10-05).** Release builds were playing the default
  sound because resource shrinking stripped `res/raw/*.ogg`; see `docs/android-build-notes.md` section 4 for the cause,
  the `res/raw/keep.xml` fix and how to verify an APK. Remember the Push Tester toggle: off sends on
  `high_importance_channel` (default sound, by design), on sends on the type's `_v2` channel (custom sound).
- **Sounds on iOS: statically checked, not yet heard.** The three `.wav` files in `ios/Runner/` are 16-bit PCM, 1 to 3
  seconds (iOS requires linear PCM / IMA4 / mu-law / a-law and under 30 s), they are in the Runner group and in the
  Resources build phase, and iOS has no resource shrinking that could strip them. Still to do on a physical iPhone:
  open the project in Xcode once to confirm Build Phases > Copy Bundle Resources lists them, then confirm each push type
  plays its own sound (the sound name comes from the push, e.g. `job_request.wav`; the app draws no local notifications
  on iOS).
- **Stacking: known issue, accepted and not pursued (decided 2026-10-05).** A real booking (request 396 /
  booking 228: accept, start, complete) gave three separate banners instead of one (`docs/notification-testing.md`
  section 9), and it still did after the app-side change below. That change stays in because it is correct on its own:
  `PushNotificationService._onForegroundMessage` posts keyed pushes (`booking-{id}`, else `request-{id}`) with that tag
  and id 0, matching how the system draws background pushes (Android replaces a notification only when tag and id both
  match). Untested leftovers if this is ever revisited: whether the production backend was running the tag code
  (commit 208c42e) during the test, and whether the device launcher/OEM ignores tags. Each stage still gets its own
  inbox row and banner, so nothing is lost.
- **Channels live:** pushes land on the `_v2` channels once `Notifications:AndroidChannelsEnabled` is on (use the Push
  Tester's channel option to force one send first).
- **Repeat the Android list on a physical device**, including the locked-screen and swiped-away cases.
- **Xcode:** open `ios/Runner.xcodeproj` once and confirm the three `.wav` files show under Build Phases > Copy Bundle
  Resources (added by hand in `project.pbxproj`).
- **iOS delivery** on a physical device (no app code needed: thread-id grouping and sounds are backend-side; the app
  draws no local notifications on iOS).
- Optional: design may want a different `ic_notification` mark (a simplified drawing of the logo today); swap the PNG in
  the five `drawable-*` folders.