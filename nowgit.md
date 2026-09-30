# Git Repositories — Takedown IQ

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | TakedownIQ |
| **Repo URL** | https://github.com/asunnyboy861/TakedownIQ |
| **Visibility** | Public |
| **Primary Language** | Swift (SwiftUI + SwiftData + CloudKit) |
| **Bundle ID** | com.zzoutuo.TakedownIQ |
| **Min iOS** | 17.0 |

## Build & Test Results

| Check | Result |
|-------|--------|
| iPhone 16 (iOS 26.4) build | ✅ BUILD SUCCEEDED |
| iPhone 16 run + launch smoke test | ✅ Onboarding rendered (FILM/FIX/WIN, volt CTA) |
| iPad Pro 13" (M5) build | ✅ BUILD SUCCEEDED |
| Archive-path signing (generic/iOS, real identity) | ✅ "Apple Development: he zhou" |
| Simulator cleanup (iPhone + iPad, scope-safe) | ✅ erased after test |
| Secret scan before push | ✅ clean (.env not in repo; icon_raw.png ignored) |

## Repository Structure

```
TakedownIQ/
├── TakedownIQ.xcodeproj/          # xcodegen-generated
├── project.yml                    # xcodegen source of truth (Team JP4TN5PTS3)
├── TakedownIQ/                    # App sources
│   ├── App/                       # Entry + RootTabView
│   ├── Core/                      # Models, AI (GLMClient/AppleAICoach), Video, Engines
│   └── Features/                  # Onboarding/Home/Film/Plan/Library/Weight/Stats/Coach/Paywall/Settings
├── Proxy/                         # Cloudflare Worker (tdiq-glm-proxy) — wrangler deploy
├── us.md / price.md / capabilities.md / icon.md / improvement_plan_1.md
└── .gitignore                     # .env, keytext*.md, COMPETITOR_REPORT.md, icon_raw.png
```

## Policy Pages (GitHub Pages — https://asunnyboy861.github.io/TakedownIQ/)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/TakedownIQ/ | ✅ Active |
| Support | https://asunnyboy861.github.io/TakedownIQ/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/TakedownIQ/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/TakedownIQ/terms.html | ✅ Active |

## Pending (manual / later phases)
- IAP products in App Store Connect (IDs wired: com.takedowniq.pro.monthly / pro.yearly / season.pass)
- Production: switch GLMConfig.devKey → appTransaction (StoreKit 2 JWS) before App Store submission

## Resolved (2026-09-30)
- GLM API: app now uses the shared Cloudflare proxy `https://cramjam-api.calcs.top` (appId `takedown-iq`, per GLM-Cloudflare repo config doc; limits 30/hr + 200/day per appId:userId). Text + vision end-to-end tests passed (HTTP 200). TakedownIQ's own `Proxy/tdiq-glm-proxy` Worker is therefore no longer required (kept as backup).
- Whitelist (2026-09-30 update): `takedown-iq` ↔ `com.zzoutuo.TakedownIQ` registered into the proxy D1 `apps` whitelist via /admin/apps (self-service §8.1). GLMClient now sends `appTransaction` (StoreKit 2 `Transaction.currentEntitlements` JWS) when the user has an active subscription, falling back to test-channel `devKey` otherwise; server switches to whitelist-only JWS verification when DEV_MODE is removed.
