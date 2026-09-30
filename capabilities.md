# Capabilities Configuration

## Analysis
Based on operation guide analysis (TR-20260917 摔角AI指南 + us.md):
- CloudKit sync for SwiftData ("CloudKit 私有库 自动同步") → iCloud capability
- HealthKit read-only body mass ("HealthKit 体重/只读") → HealthKit capability
- Camera + PhotosPicker for match video ("拍摄/相册选取") → usage descriptions
- Local notifications (Sunday Weigh-In, streak nudges) → no capability needed (UNUserNotificationCenter)
- StoreKit 2 IAP → no capability file needed (auto-enabled with In-App Purchase in App Store Connect)
- No Widget / Watch / Push (remote) targets in MVP

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| iCloud (CloudKit, container iCloud.com.zzoutuo.TakedownIQ + KV store) | ✅ Configured | xcodegen entitlements |
| HealthKit (read-only weight) | ✅ Configured | xcodegen entitlements |
| Camera usage description | ✅ Configured | INFOPLIST_KEY_NSCameraUsageDescription |
| Photo Library usage description | ✅ Configured | INFOPLIST_KEY_NSPhotoLibraryUsageDescription |
| HealthKit read usage description | ✅ Configured | INFOPLIST_KEY_NSHealthShareUsageDescription |
| PrivacyInfo.xcprivacy (UserDefaults CA92.1, FileTimestamp C617.1, no tracking) | ✅ Configured | App target source folder |
| DEVELOPMENT_TEAM | ✅ Baked at project level | JP4TN5PTS3 (from .env) |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| CloudKit container in Apple Developer portal | ⏳ Auto-created on first signing run with logged-in Apple ID (-allowProvisioningUpdates passed); if container missing in portal: Xcode → Signing & Capabilities → iCloud → add container `iCloud.com.zzoutuo.TakedownIQ` | One click in Xcode |
| In-App Purchase products (3 StoreKit 2 items) | ⏳ Must be created in App Store Connect before release; sandbox testing works with StoreKit configuration file locally | Create in ASC per price.md |
| tdiq-glm-proxy Cloudflare Worker (GLM key) | ⏳ Deploy in PHASE 4+5 (Proxy/ folder ships with app repo); requires Cloudflare account login | `npx wrangler deploy` + `wrangler secret put GLM_API_KEY` |

## No Configuration Needed
- Push Notifications (app uses local notifications only)
- Background Modes (not required for MVP)
- Sign in with Apple (anonymous device identity via Keychain — no account system)
- Apple Watch / Widgets (V1.1+)

## Verification
- Build succeeded after configuration: ✅ (iPhone 16 simulator, 6.0s)
- All entitlements correct: ✅ (plutil lint OK; healthkit + CloudKit + KV store)
- Signing verification (generic/platform=iOS): ✅ PASSED — real identity "Apple Development: he zhou", BUILD SUCCEEDED with -allowProvisioningUpdates
- DEVELOPMENT_TEAM: JP4TN5PTS3 baked at project level (all targets inherit)
- PrivacyInfo.xcprivacy: App target covered
