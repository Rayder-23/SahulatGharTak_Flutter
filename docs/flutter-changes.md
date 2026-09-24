# Flutter App Changes Tracker

Running checklist of backend changes that the Flutter app needs to adopt to complete a feature's integration, or that are being deliberately held back as breaking changes pending approval. Updated incrementally as each backend feature lands — **`api.txt` (repo root, currently v3.20) is the exact, authoritative request/response contract of every endpoint referenced below**; read the cited `api.txt` section before implementing, since this file only summarizes.

Sections are removed once the Flutter app has fully adopted them — this file tracks *pending/active* work, not a history of everything ever shipped. Completed feature history lives in git log and `api.txt`'s own version notes, not here.

**Standing constraint (2026-09-21):** the Flutter app is live on the Play Store and App Store, both of which have review/approval lag, while the backend/API can be updated instantly. Every backend change in this project is therefore built to be **additive and optional** — a currently-published app build must keep working completely unchanged against the updated backend, with zero risk of breakage while store approval for the new app version is pending. New fields on existing endpoints are nullable/optional with a legacy fallback; new endpoints are new routes an old app simply never calls. Nothing here is a hard cutover.

Legend:
- **Available now** — backend is live, app can adopt whenever convenient (non-breaking, optional).
- **Held for approval** — a genuinely breaking change to a live endpoint contract (not just optional-field additions) that hasn't been implemented at all yet; listed here so the scope is visible ahead of time. Per the constraint above, when these are eventually implemented they should also default to an optional/additive interim contract rather than a hard break, unless explicitly decided otherwise at that time.
- **TODO(remove after old app retired)** — inline code/doc comments marking legacy-fallback branches that exist ONLY to support currently-published app builds. Once the new app version is confirmed live on both stores (i.e. no meaningfully active install base still hits these code paths), these branches can be deleted — grep the codebase for this exact marker to find all of them. Do not remove any of these until that confirmation, even if it looks safe.

---

## Provider Document: Police Verification

**Status: backend ready and live (2026-09-24); adopted in the Flutter app the same day.**

Adopted: `PoliceVerification` is now a 4th, optional image slot on both the provider
registration document-upload screen (`lib/screens/provider_document_upload_screen.dart`)
and the "My Documents" screen (`lib/screens/provider/profile/verification_documents_screen.dart`),
following the same pattern as Profile Photo/CNIC Front/CNIC Back — including the
CNIC-style lock (`DocumentImageSlot(locked: ...)`) once the provider is verified. Per the
explicit product decision for this document type, it has **no image-recognition/live-detection
validation** — `lib/widgets/provider/document_capture_sheet.dart` routes this slot through a
plain camera/gallery capture with a free-aspect crop, bypassing `LiveCameraCaptureScreen`'s
face/CNIC framing guide and `_validateStaticImage`'s ML Kit check entirely. Threaded through
`ProviderDocumentProvider` (new `ProviderDocumentSlot.policeVerification`), the repository/API
service (new optional `policeVerification`/`PoliceVerification` param), and
`ProviderDocumentsModel.policeVerificationPath`. `canUpload` intentionally does not require this
slot, matching the backend's "never required" contract.

A new, fully optional 4th provider document slot alongside the existing Profile Photo / CNIC
Front / CNIC Back. Unlike those three, Police Verification is **never required** — not on
first-time registration, not on edit — so a currently-published app build that only ever sends
the original three fields is completely unaffected and keeps working unchanged.

Backend contract reference (already live):
- `POST /api/provider/upload-documents` (multipart) gained a new optional form field
  `PoliceVerification` (file, jpg/jpeg/png, max 5 MB) — see `api.txt`'s
  `POST Upload Provider Documents` section under `PROVIDER DOCUMENT APIs`. Send it alongside
  (or instead of) the existing fields on either first submission or edit; omit it entirely and
  nothing changes for that provider's row.
- `GET`/`POST /api/provider/{providerUID}/documents` and the admin
  `POST /api/provider/verify-documents` response now include a new `policeVerificationPath`
  field (nullable string, `null` until uploaded) alongside the existing three path fields.
- Uploading/replacing Police Verification does **not** reset `isVerified` (that flag tracks CNIC
  identity verification only, unrelated to this document).

Suggested build spec once the Flutter team picks this up (not started, no urgency — this document
type has no deadline tied to it):
1. Wherever the app currently captures Profile Photo / CNIC Front / CNIC Back during provider
   registration or document-edit (mirror whatever screen/widget handles those three today), add
   a 4th optional image-picker slot for "Police Verification" — same picker/crop/upload pattern,
   just marked optional in the UI (no red-asterisk/required styling).
2. Send it as `PoliceVerification` in the same multipart request as the other three when present;
   omit the field entirely when the user hasn't provided one (do not send an empty/placeholder
   file).
3. Wherever the app reads back a provider's documents (e.g. a provider's own profile/documents
   screen), surface `policeVerificationPath` the same way it already surfaces the other three
   paths (thumbnail/"view" link when non-null, an empty/"not uploaded" state when null).
4. No app-version gate needed — this is a new optional field on an existing endpoint; old and new
   app builds both keep working against the updated backend with no coordination required.

**Future decision, not yet made (flagged, not scheduled):** whether Police Verification should
become *required* on first-time provider registration once the new app version (with the 4th
upload slot) is confirmed live on both stores and old-app usage has dropped off. If/when that
decision is made, the change is: add `PoliceVerification` to the `isFirstSubmission` required-file
check in `ProviderDocumentsApiService.UploadDocumentsAsync`
(`HomeServicesPortal/Services/ProviderDocumentsApiService.cs`) alongside `ProfilePhoto`/
`CnicFront`/`CnicBack`, and the equivalent check in the admin `ProviderDocumentService.CreateAsync`
(`HomeServicesPortal/Services/ProviderDocumentService.cs`). Do not make this change until that
confirmation — flipping it early would break first-time registration for any still-active old
app build.