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
- Season Pass IAP `com.takedowniq.season.pass` ($19.99, non-renewing 90 days): must be created in ASC web UI (API key lacks inAppPurchases CREATE — 403)
- Subscription review screenshots: both subs are MISSING_METADATA until Paywall screenshots are uploaded in ASC web (user)
- Select build 1 and submit for review in ASC web (Apple requires manual submit)
- whatsNew: fill later (state-locked during PREPARE_FOR_SUBMISSION)

## App Store Connect (2026-09-30)
- App record: id 6817645486, name "Takedown IQ", subtitle "AI Wrestling Coach & Film", SKU com.zzoutuo.TakedownIQ, primary locale en-US
- Build 1 (275e038a) uploaded and VALID, attached to version 1.0 (PREPARE_FOR_SUBMISSION)
- Categories: Sports (primary) + Health & Fitness (secondary); age questionnaire submitted (health/wellness topics = true)
- Metadata filled: description (2069 chars), keywords (87 chars), promo text, support/marketing/privacy URLs, copyright "Copyright © 2026 he zhou", review contact HE ZHOU + notes
- Subscription group "Takedown IQ Pro" (id 22427247): Pro Monthly com.takedowniq.pro.monthly ($8.99, id 6817652900), Pro Annual com.takedowniq.pro.yearly ($49.99, id 6817653048, 7-day FREE_TRIAL intro offer, Family Sharing)
- Pricing: USA rows set + global equalization 348/348 POST ok → 175/175 territories both subs
- Landing page download link backfilled with real App ID 6817645486 and pushed to GitHub Pages (live)
- Upload fixes this session: AppIcon Contents.json missing filename (icons absent from bundle), NSHealthUpdateUsageDescription added, UIRequiresFullScreen YES (iPad multitasking warning), Release excludes GLMProxySecret.txt via EXCLUDED_SOURCE_FILE_NAMES

## Previously Pending (superseded above where noted)
- IAP products in App Store Connect (IDs wired: com.takedowniq.pro.monthly / pro.yearly / season.pass — monthly & yearly now created, season pass still manual)
- Production: switch GLMConfig.devKey → appTransaction (StoreKit 2 JWS) before App Store submission

## Resolved (2026-09-30)
- GLM API: app now uses the shared Cloudflare proxy `https://cramjam-api.calcs.top` (appId `takedown-iq`, per GLM-Cloudflare repo config doc; limits 30/hr + 200/day per appId:userId). Text + vision end-to-end tests passed (HTTP 200). TakedownIQ's own `Proxy/tdiq-glm-proxy` Worker is therefore no longer required (kept as backup).
- Whitelist (2026-09-30 update): `takedown-iq` ↔ `com.zzoutuo.TakedownIQ` registered into the proxy D1 `apps` whitelist via /admin/apps (self-service §8.1). GLMClient now sends `appTransaction` (StoreKit 2 `Transaction.currentEntitlements` JWS) when the user has an active subscription, falling back to test-channel `devKey` otherwise; server switches to whitelist-only JWS verification when DEV_MODE is removed.
- glm-api-config spec alignment (2026-09-30): devKey now read from bundle resource `TakedownIQ/GLMProxySecret.txt` (gitignored — recreate locally with content `cramjam-dev-2026` after cloning, then `xcodegen generate`); 401→receiptRejected / 429→rateLimited friendly error mapping in FilmViewModel; JWS revocation check; no cross-line retry on credential/rate-limit errors. E2E verified: 200 / 400 / 401 / 405 all as expected. Whitelist confirmed via register_app.sh list (status=1).
