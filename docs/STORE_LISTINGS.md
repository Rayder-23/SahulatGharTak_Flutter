---
status: current
type: reference
---

# Store Listings and App Identifiers

Public identifiers for Sahulat Ghar Tak, e.g. for backend configuration (push notifications, store links). None of these are secrets.

## Android (Google Play)

| Field | Value |
|---|---|
| Package ID (application ID) | `com.coditiumsols.sahulatghartak` |
| Play Store URL | https://play.google.com/store/apps/details?id=com.coditiumsols.sahulatghartak |
| Defined in | `android/app/build.gradle.kts` (`applicationId`) |

## iOS (App Store)

| Field | Value |
|---|---|
| Bundle ID | `com.coditiumsols.sahulatghartak.ios` |
| App Store ID (Apple ID) | `6810184599` (numbers only) |
| App Store URL | https://apps.apple.com/pk/app/sahulat-ghar-tak/id6810184599 |
| Defined in | `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`) |

The iOS bundle ID differs from the Android package ID by the `.ios` suffix.

## Firebase

| Field | Value |
|---|---|
| Project ID | `sahulatghartak-ef6ed` |
| Project number / FCM sender ID | `384526721514` |
| Android app ID | `1:384526721514:android:ee1b3a08c96b00b2fa9293` |
| iOS app ID | `1:384526721514:ios:e4a39da742503ecbfa9293` |

Signing certificate fingerprints (debug, upload, Play app signing) are kept in the local, gitignored `.env`.
