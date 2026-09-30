# Improvement Plan 1 — Takedown IQ (PHASE 4+5 Iteration 1)

## Issues Found (Phase A Analysis)

| Issue ID | Description | Severity | Fix | Status |
|----------|-------------|----------|-----|--------|
| ISSUE-001 | 55 compile errors: @Model classes lacked explicit initializers (SwiftData macro requires init) | Critical | Added explicit `init() {}` to all 8 @Model classes in Models.swift | Implemented |
| ISSUE-002 | `@Generable` types declared as local types inside function — Swift macro restriction | Critical | Moved FMPlan/FMDrill to file scope with `@available(iOS 26.0, *)` in AppleAICoach.swift | Implemented |
| ISSUE-003 | HealthKit query used non-existent `HKSortDescriptor` + async misuse | Critical | Rewrote `latestWeight()` with HKSampleQuery + CheckedContinuation<Double?, Never> + HKQuantitySample cast | Implemented |
| ISSUE-004 | `guard let` on non-failable `AVAssetReaderTrackOutput` init | Major | Changed to plain `let` binding | Implemented |
| ISSUE-005 | Missing `import SwiftData` in FilmCaptureView / `import StoreKit` in SettingsView | Major | Added imports | Implemented |
| ISSUE-006 | `#Predicate` with static property reference in PlanView @Query filters | Major | Replaced with unfiltered @Query + in-code filtering | Implemented |
| ISSUE-007 | Designated init declared in extension of @Model DrillItem (OnboardingView) | Major | Replaced with property assignment after `DrillItem()` | Implemented |
| ISSUE-008 | Duplicate `convenience init` for BreakdownResult (extension collided with explicit @Model init) | Major | Removed extension from FilmViewModel | Implemented |
| ISSUE-009 | `await` in autoclosure / conditional binding on non-optional Bool in PurchaseManager | Minor | Restructured `seasonPassEntitlementActive()` usage | Implemented |
| ISSUE-010 | Thumbnail→event matching logic keyed on wrong type (UUID vs t) | Critical (logic) | Rebuilt as `[Double: String]` t-anchored map (matches validator's ±0.05s rounding) | Implemented |

## Verification
- Build (iPhone 16, iOS 26.4 simulator): **BUILD SUCCEEDED**
- Signing (generic/platform=iOS, real identity "Apple Development: he zhou"): **BUILD SUCCEEDED**
- Hardcoded version scan: none
- TODO/FIXME/stub scan: none
- `DEVELOPMENT_TEAM = ""` scan: 0 occurrences
- PrivacyInfo.xcprivacy: present in app target

## Scores After Iteration 1
- Usability: 4/5 (onboarding ≤15s, FILM IT on Home, honest quota UX)
- UI Consistency: 4/5 (single Mat Room Dark token set in Theme.swift, volt CTA everywhere)
- Feature Completeness: 4/5 (12/12 primary features implemented; sub-features incl. honest "unclear" cards, meme loading, revive card, parent report share)
- Download-to-Use: 4/5 (free tier fully usable offline; template fallbacks for AI; HealthKit optional)
- Competitive Level: 4/5 (timestamped+confidence-gated feedback, Safe Cut blacklist, transparent paywall)
- Contact Support: 5/5 (7 preset tiles, 5 required fields, backend https://msg.calcs.top, privacy microcopy, success/error states)
- Accessibility: 4/5 (labels on all interactive elements, Dynamic Type fonts, combined elements)

EXIT CRITERIA: ALL MET (0 Critical/Major remaining, build green, no stubs)

## Known Manual Items (carried to PHASE 8.5)
- Deploy Proxy/ Cloudflare Worker (`tdiq-glm-proxy.calcs.top`) + KV namespace + GLM_API_KEY secret (wrangler OAuth on this machine expired 2026-05-06)
- Create 3 IAP products in App Store Connect (IDs already wired in code)
- CloudKit container auto-provisions on first signed run with logged-in Apple ID
