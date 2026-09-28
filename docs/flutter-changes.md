# Flutter App Changes Tracker

Running checklist of backend changes that the Flutter app needs to adopt to complete a feature's integration, or that are being deliberately held back as breaking changes pending approval. Updated incrementally as each backend feature lands — **`api.txt` (repo root, currently v3.22) is the exact, authoritative request/response contract of every endpoint referenced below**; read the cited `api.txt` section before implementing, since this file only summarizes.

Sections are removed once the Flutter app has fully adopted them — this file tracks *pending/active* work, not a history of everything ever shipped. Completed feature history lives in git log and `api.txt`'s own version notes, not here.

**Standing constraint (2026-09-21):** the Flutter app is live on the Play Store and App Store, both of which have review/approval lag, while the backend/API can be updated instantly. Every backend change in this project is therefore built to be **additive and optional** — a currently-published app build must keep working completely unchanged against the updated backend, with zero risk of breakage while store approval for the new app version is pending. New fields on existing endpoints are nullable/optional with a legacy fallback; new endpoints are new routes an old app simply never calls. Nothing here is a hard cutover.

Legend:
- **Available now** — backend is live, app can adopt whenever convenient (non-breaking, optional).
- **Held for approval** — a genuinely breaking change to a live endpoint contract (not just optional-field additions) that hasn't been implemented at all yet; listed here so the scope is visible ahead of time. Per the constraint above, when these are eventually implemented they should also default to an optional/additive interim contract rather than a hard break, unless explicitly decided otherwise at that time.
- **TODO(remove after old app retired)** — inline code/doc comments marking legacy-fallback branches that exist ONLY to support currently-published app builds. Once the new app version is confirmed live on both stores (i.e. no meaningfully active install base still hits these code paths), these branches can be deleted — grep the codebase for this exact marker to find all of them. Do not remove any of these until that confirmation, even if it looks safe.

---

## Available now: Request re-dispatch after provider cancels an accepted booking (v3.22)

**Status: backend ready and live. No code change is required for the app to work correctly against this — it already handles the resulting states. This section documents a behavior/meaning change worth being aware of, not a new field or new endpoint.**

### What changed

Booking-workflow edge case fix. Previously, if a provider accepted a booking and then cancelled it (`PUT /service-bookings/{id}` with `status: "Cancelled"`), the parent request was set to a terminal `Cancelled` state — the client's request was simply over, with no path back, and they'd have to submit a brand-new request from scratch to get the service again.

As of v3.22, that specific case (provider-initiated cancel of an already-accepted booking) now resets the **parent request** back to `Initiated` instead, so staff can re-assign new providers without the client doing anything — mirroring how the existing "all fanned-out providers rejected" case already worked. A staff-initiated cancel via the admin portal is unchanged (still terminal `Cancelled`) — only a provider cancelling their own accepted job now re-dispatches.

**Root cause of "the request disappeared from the client app" (confirmed via testing):** fixing the request's own `Status` wasn't enough on its own — `CustomerServiceRequestService.cs`'s `progressStatus` computation independently looks up "the most recent non-Rejected booking" for the request to decide the stage, and a provider-cancelled booking's `ServiceBookings.Status` is `"Cancelled"`, not `"Rejected"`, so that stale cancelled booking was still being picked up and was wrongly forcing `progressStatus: null` even though `Status` had already correctly reset to `"Initiated"`. Per this doc's own contract (see `docs/status-workflow.md`), `progressStatus: null` means "treat as cancelled, hide the progress bar/entry" — so any app screen that filters an "active requests" list on `progressStatus != null` would legitimately have hidden/dropped this request, exactly matching what testing observed. **Fixed** by also excluding `Cancelled` bookings from that lookup (same treatment as `Rejected` — both are terminal states for one specific booking *attempt*, not the request's own fate). This fix is backend-only and already live; nothing needed on the Flutter side for this part.

### What the app will observe via `GET /customer-service-requests` (list + by-id)

No new fields, no new enum values. This is a **status regression into an existing, already-handled stage**:

| Field | Value after a provider cancels their accepted booking |
|---|---|
| `status` | `"Initiated"` |
| `progressStatus` | `"Requested"` |

This is exactly what a brand-new, not-yet-assigned request looks like — the same combination the app already renders correctly today for a request that was just created. The only thing that's new is the *meaning*: a request the user previously saw progress to "Assigned" (a provider picked up their job) can now legitimately bounce back to "Requested" instead of staying assigned or becoming "Cancelled." If the app has any client-side memory/caching that assumes `progressStatus` only ever moves forward (Requested → Assigned → In Progress → Completed) and never backward, that assumption is no longer safe — this is the one case where it now regresses.

The `ServiceBookings` row the provider cancelled still shows `status: "Cancelled"` if the app ever fetches it directly by id (e.g. `GET /service-bookings/{id}`) — that record isn't deleted or hidden, it's just no longer the request's *active* booking. The app's normal "current status of my request" read path (`GET /customer-service-requests`) won't surface that stale cancelled booking at all once this fix is live — see `api.txt` v3.22 notes under `PUT /service-bookings/{id}` for the exact backend mechanics.

### Suggested (optional) UX improvement — not required

Since nothing forces a UI change, the app can ship with zero changes and this will behave correctly (a cancelled-and-reset request will just quietly show up again as "Requested"). But a small UX improvement worth considering when convenient: today's "Requested" copy/UI likely reads as "we're processing your new request," which might confuse a user who thought their request was already assigned to someone. If desired, the app could distinguish "first time requested" from "bounced back after a provider cancelled" using client-side state it already has (e.g. if it previously observed `progressStatus: "Assigned"` for this request and now sees `"Requested"` again, show a toast/banner like "Your provider had to cancel — we're finding you a new one" instead of silently reverting the progress bar). This is purely additive polish, not required for correctness.

### Admin-side notification (backend/admin portal only, no Flutter impact)

Also fixed as part of this: the admin portal wasn't clearly notified when this reset happened (it reused a generic "provider cancelled" notification type shared with unrelated events). Now fires a distinct `RequestNeedsReassignment` admin notification with its own bell icon, for both this trigger and the pre-existing "all providers rejected" trigger. Purely an admin-portal-side change — no client/provider app API surface involved.

**Reference:** `api.txt` v3.22, `PUT /service-bookings/{id}` section. Full design rationale: `docs/status-workflow.md` (`CustomerServiceRequests.Status` section and the v3.22 addendum under Flutter Q2).
