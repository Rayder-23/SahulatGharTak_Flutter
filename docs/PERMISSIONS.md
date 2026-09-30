# Permissions & Platform Configuration Report

Last reviewed: 2026-09-30. Covers what the app requests on Android and iOS, why, how each is handled in code, and the store-review implications. Cross-check with `docs/PRIVACY_POLICY.md` and `docs/APP_STORE_AUDIT_REPORT.md` when anything here changes.

## 1. What the app actually uses

| Capability | Feature | Code |
|---|---|---|
| Camera | Live capture of profile photo / CNIC (`LiveCameraCaptureScreen`, audio disabled) | `lib/services/camera_permission_service.dart` (`Permission.camera`) |
| Photo library | Picking profile photo / CNIC images | `image_picker` → Android system Photo Picker / iOS PHPicker (no runtime prompt on Android) |
| Location (while in use) | Centering the address pin-drop map on the device position | `lib/services/location_permission_service.dart` (`Permission.locationWhenInUse`), `Geolocator.getCurrentPosition` in `add_address_screen.dart` |
| Network | All API calls (HTTPS only) | — |
| Microphone | **Not used.** Camera runs with `enableAudio: false`. | `live_camera_capture_screen.dart` |
| Background location, contacts, tracking (ATT) | **Not used** | — |

Requests are always made in context (when the user opens the relevant feature), never at launch, and the app degrades gracefully if denied.

## 2. Android

### 2.1 Declared in `android/app/src/main/AndroidManifest.xml`

| Permission | Purpose |
|---|---|
| `INTERNET` | API access |
| `CAMERA` | Live document/profile capture |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Pin-drop map; Android requires both to be declared, the user may grant approximate only |

No background-location permission is declared.

### 2.2 Permissions merged in by plugins (release manifest)

| Permission | Source | Needed? |
|---|---|---|
| `RECORD_AUDIO` | `camera` plugin | No — audio is disabled |
| `READ_EXTERNAL_STORAGE` | `image_cropper` / picker libs | No — Photo Picker needs no storage permission |
| `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=28`) | plugin | Legacy only, harmless |
| `ACCESS_NETWORK_STATE` | Google Maps | Yes |

### 2.3 Stripping change — ENABLED and verified

The manifest contains two `tools:node="remove"` entries (`RECORD_AUDIO`, `READ_EXTERNAL_STORAGE`) that drop the unused permissions above from the final manifest. It was briefly commented out, then re-enabled on 2026-09-30 and verified on a physical device: live camera capture, gallery pick, and crop all work. If a future plugin upgrade breaks any of these, check the merged manifest (`build/app/intermediates/merged_manifests/release/.../AndroidManifest.xml`) first.

### 2.4 Network security (`res/xml/network_security_config.xml`)

Now `<base-config cleartextTrafficPermitted="false"/>` — HTTPS only. The previous config allowed cleartext to `sahulatghartak.com`, which nothing needed (`kApiBaseUrl` is HTTPS in both debug and release; local dev uses `https://10.0.2.2:7265`). Basis: Android's guidance to restrict cleartext at all times, per-domain exceptions only when unavoidable, and Play's rejection of blanket cleartext ([Android docs](https://developer.android.com/privacy-and-security/security-config), [Cleartext risks](https://developer.android.com/privacy-and-security/risks/cleartext-communications), [Flutter docs](https://docs.flutter.dev/release/breaking-changes/network-policy-ios-android)). If a future dev workflow needs plain HTTP, put a config in `android/app/src/debug/` only — never in `main`.

### 2.5 Play Console declarations

Data safety: location (approximate/precise, address pin, not tracked, not shared), photos (profile/CNIC, collected, encrypted in transit), personal info (name, phone, CNIC, address), account deletion URL `https://sahulatghartak.com/delete-account`. Third-party SDK: Google Maps. ML Kit runs on-device.

## 3. iOS (`ios/Runner/Info.plist`)

| Key | Purpose string (summary) | Notes |
|---|---|---|
| `NSCameraUsageDescription` | Capture profile photo and CNIC | Used |
| `NSPhotoLibraryUsageDescription` | Select profile photo and CNIC | Used |
| `NSLocationWhenInUseUsageDescription` | Center map / drop address pin | Used |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Same, states never tracked in background | **Added 2026-09-30 for Apple error 90683.** `geolocator_apple` references the "Always" API, so Apple requires the key even though the app never requests Always. |
| `NSMicrophoneUsageDescription` | Camera needs mic to initialize; nothing is recorded | Present because the `camera` plugin references the API |

`ITSAppUsesNonExemptEncryption = false` (HTTPS only). No ATT key: no tracking/ads/analytics SDKs.

### `permission_handler` compile flags (`ios/Podfile`)

`permission_handler` compiles code for every permission type unless enabled explicitly, causing review to flag APIs the app never uses. `post_install` sets `PERMISSION_CAMERA=1` and `PERMISSION_LOCATION_WHENINUSE=1` only. **If you add a new permission request in `lib/`, add its `PERMISSION_*` flag and Info.plist string in the same change.** After editing the Podfile run `pod install` (macOS/CI).

## 4. Dependencies / third-party disclosure

| Package | Data implications |
|---|---|
| `google_maps_flutter` | Google receives IP/map usage; disclose in policy and store forms |
| `google_mlkit_*` | On-device only |
| `geolocator`, `permission_handler`, `camera`, `image_picker`, `image_cropper` | Device access described above |
| `flutter_secure_storage` | Local encrypted session storage |
| ~~`sqflite`~~, ~~`fl_chart`~~, ~~`path`~~ | Removed 2026-09-30 (never imported) |

No analytics, advertising, crash-reporting, or social SDKs.

## 5. Maintenance checklist

1. New permission → manifest / Info.plist string / Podfile flag / policy / store forms, together.
2. Re-run `flutter build appbundle --release` and inspect the merged manifest for surprise plugin permissions.
3. Keep `docs/PRIVACY_POLICY.md` and the live page at `https://sahulatghartak.com/privacy-policy` identical.
