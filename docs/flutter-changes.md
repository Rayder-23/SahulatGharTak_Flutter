---
status: current
---

# Flutter App Changes Tracker

Running checklist of backend changes that the Flutter app needs to adopt to complete a feature's integration, or that are being deliberately held back as breaking changes pending approval. Updated incrementally as each backend feature lands — **`api.txt` (repo root, currently v3.29) is the exact, authoritative request/response contract of every endpoint referenced below**; read the cited `api.txt` section before implementing, since this file only summarizes.

Sections are removed once the Flutter app has fully adopted them — this file tracks *pending/active* work, not a history of everything ever shipped. Completed feature history lives in git log and `api.txt`'s own version notes, not here.

**Standing constraint (2026-09-21):** the Flutter app is live on the Play Store and App Store, both of which have review/approval lag, while the backend/API can be updated instantly. Every backend change in this project is therefore built to be **additive and optional** — a currently-published app build must keep working completely unchanged against the updated backend, with zero risk of breakage while store approval for the new app version is pending. New fields on existing endpoints are nullable/optional with a legacy fallback; new endpoints are new routes an old app simply never calls. Nothing here is a hard cutover.

Legend:
- **Available now** — backend is live, app can adopt whenever convenient (non-breaking, optional).
- **Held for approval** — a genuinely breaking change to a live endpoint contract (not just optional-field additions) that hasn't been implemented at all yet; listed here so the scope is visible ahead of time. Per the constraint above, when these are eventually implemented they should also default to an optional/additive interim contract rather than a hard break, unless explicitly decided otherwise at that time.
- **TODO(remove after old app retired)** — inline code/doc comments marking legacy-fallback branches that exist ONLY to support currently-published app builds. Once the new app version is confirmed live on both stores (i.e. no meaningfully active install base still hits these code paths), these branches can be deleted — grep the codebase for this exact marker to find all of them. Do not remove any of these until that confirmation, even if it looks safe.

---

## Available now

### Push notifications - remaining verification

The Flutter side (token registration, foreground/background handling, tap routing, inbox, unread badge, version gate)
is implemented. Android was tested end to end against the local API (`docs/notification-testing.md`), including tap
routing. Still to verify:

- Cold-start tap routing (`getInitialMessage`) on a test APK - kill the app with Home / recents is not enough on every
  OEM; a force-stopped Android app receives no FCM, so test by backgrounding then letting the OS reclaim it, or via
  `adb shell am kill`.
- iOS delivery once the backend changes are in production (APNs key is uploaded to Firebase; `aps-environment` is
  `production` for all build configs). Push does not work on the iOS simulator without a physical device/APNs setup.
- Admin "Push Broadcast" (`app_update` tap opens the store link) and the version gate against real
  `/api/v1/app/config` values.

Remove this section once those pass.
