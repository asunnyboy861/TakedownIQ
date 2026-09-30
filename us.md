# Takedown IQ - iOS Development Guide

> Translated and adapted from: TR-20260917-摔角AI-操作指南.MD (2026-09-17)
> Target market: United States (App Store US) | Monetization: Free + Subscription
> AI stack: Apple Foundation Models (on-device, free) + GLM-5.3-Flash via Cloudflare Worker proxy (vision film breakdown)

## Executive Summary

**Takedown IQ** is an AI-powered American wrestling (folkstyle/freestyle) training app that "points at the film and talks": wrestlers film their matches, the AI returns timestamped, frame-anchored feedback with confidence scores and actionable drill prescriptions, plus a Safe Cut weight-management engine that parents trust. Free tier is genuinely useful (1 full video breakdown per day + full technique library + drills + match log); Pro is transparently priced with a 2-tap cancel path.

**Key differentiators vs. market leader Wrestle AI ($131K revenue in 6 months, but a 6-week MVP):**
1. **Trustworthy feedback** — every AI observation is timestamped + frame-anchored + confidence-gated; when the AI can't see clearly it honestly says so and gives filming guidance (competitors fake accuracy).
2. **Transparent pricing** — real free tier, public price page, "Manage in 2 taps" (competitors have no free tier and trap trials on annual only).
3. **Safe Cut engine (exclusive)** — NWCA-style safe weight-cut monitoring with a hard blacklist against extreme cutting advice. Parents are the real payers; no competitor has this.
4. **Native SwiftUI + on-device Apple AI** — offline-capable, no React Native jank.

**Target audience:** US high school wrestlers (250K+ boys, 25K+ girls and growing), youth club/NCAA/JUCO athletes, and their parents (the payers). Season peak: Nov–Feb.

**App identity (fixed):**
| Item | Value |
|---|---|
| App Name | **Takedown IQ** |
| Subtitle (≤30 chars) | **AI Wrestling Coach & Film** (25 chars) |
| Promo text | Film your match. Get the exact 2 seconds you lost — and the drill that fixes it. |
| Category | Sports (primary) + Health & Fitness (secondary) |
| Age rating | 13+ (contains weight-management content) |
| Bundle ID | com.zzoutuo.TakedownIQ |
| Min iOS | 17.0 (Apple Foundation Models features gated to iOS 18.1+, graceful fallback) |

**ASO keyword field (US, ≤100 chars):** `wrestling,drills,takedown,pin,mat,coach,film,folkstyle,freestyle,grappling,streak,match`

---

## Competitive Analysis

| App | Positioning | Pricing | Strengths | Weaknesses | Our Advantage |
|-----|------------|---------|-----------|------------|---------------|
| **Wrestle AI** (replication target; $131,863 in 6 months, MRR $23K, 4.8★/1.7K ratings, 100K+ downloads) | Personal AI wrestling coach (folkstyle/freestyle) | $9.99/mo, $59.99/yr (3-day trial on annual only) | Validated market, daily drill plans, technique library, Impossible Mode, stats, timers, streaks | No free tier; RN cross-platform feel; generic non-timestamped AI feedback; no weight management; no coach loop; long onboarding paywall trap | Real free tier, timestamped + confidence-gated feedback, Safe Cut engine, native SwiftUI |
| **WrestleKit** | Clone of Wrestle AI | Weekly/annual subscriptions | "Which color am I" friction patch | Same weaknesses, weaker execution | All of the above |
| **SportsReflector** | Generic real-time CV+AR for 22+ sports | Free + Pro | Broad sport coverage | Generic models, no wrestling-rule knowledge | Wrestling-specific prompts + folkstyle drill library |
| **Greco AI** | Greco-Roman niche | Weekly/annual/lifetime | Deep Greco focus | US mainstream is folkstyle; coverage gap | Full folkstyle/freestyle coverage |
| **MatBoss 11.0** | Whole-team platform (film+stats+weight+ops) | Expensive team subscriptions | Team features validated (assignments, attendance) | Individuals can't afford it; Reddit price complaints | Individual pricing + coach loop in V1.1 |
| **TrackWrestling / Flo** | Event infrastructure | $150/yr | Industry standard data | Reddit: "interface is objectively bad"; no API; closed | Modern UI, local-first match log with CloudKit sync |
| **Hudl** | School-purchased film platform | Per-team pricing | Institutional lock-in | Individuals excluded; wrestling not a focus | Personal, affordable, instant |

**Market size:** 275K+ registered HS wrestlers + youth club/NCAA/JUCO = 400K+ reachable. Parents spend $1,000+/yr on youth sports; our $49.99/yr is 5% of that.

---

## ⚠️ App Store Compliance — AI Features

### Hybrid AI Backend Architecture (this app is NOT BYO-key)
- **Apple Foundation Models (on-device)**: Coach Chat + daily drill plan generation. Free, unlimited, offline. Gated to iOS 18.1+ via `#available` / `@available`; on older iOS the app **degrades gracefully** (Coach Chat falls back to keyword search over the built-in technique library; drill plans fall back to a built-in template library). **NEVER show dead AI buttons** — every AI entry point has a working fallback path.
- **GLM-5.3-Flash (cloud vision)**: Film breakdown only. Called through a Cloudflare Worker proxy (`tdiq-glm-proxy`) so **the API key never ships in the client**. Failures queue for retry; the app never shows half-broken results.
- **Dead code prevention**: ❌ NEVER add `freeGenerationsUsed`/`maxFreeGenerations`/`canGenerateFree` for Apple-FM-backed features. The free-tier daily limit applies **only** to cloud film breakdowns (QuotaEngine, §8.9 of source guide), enforced locally (UserDefaults + CloudKit) and softly at the Worker (per-device daily cap).

### Guideline 2.1(a) — App Completeness
- The full free tier works with zero configuration on any device (offline template fallbacks included).
- `app_review_info.md` must be created with a demo video and a note that the free tier needs no AI key.
- Any AI button must either work or degrade with an honest message — never an error dead-end.

### AI Content Safety
- Coach Chat instructions hard-block weight-cutting/dehydration/supplement advice (redirects to Safe Cut tab).
- Safe Cut output NEVER passes through an LLM for red-line/danger messaging — pure rule engine templates (§8.8).
- 13+ rating; health disclaimer on weight features.

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information (Paywall MUST include)
- Functional link to Privacy Policy
- Functional link to Terms of Use (EULA)
- Full price table: Pro Monthly $8.99, Pro Yearly $49.99 (7-day free trial, Family Sharing), Season Pass $19.99/90 days (non-renewing)
- Auto-renewal disclosure text
- "Manage in 2 taps" direct link: `AppStore.showManageSubscriptions` reachable from the paywall AND Settings (one-level entry)
- Restore Purchases button

### StoreKit 2 Product IDs
| Product | ID | Price |
|---|---|---|
| Pro Monthly | `com.takedowniq.pro.monthly` | $8.99/mo |
| Pro Yearly | `com.takedowniq.pro.yearly` | $49.99/yr, 7-day trial |
| Season Pass | `com.takedowniq.season.pass` | $19.99, non-renewing 90 days |

---

## Apple Design Guidelines Compliance

- **Dark-first "Mat Room Dark" design**: near-black background `#0B0D0C`, volt accent `#C8FF2E`, surface `#151918`, 20pt corner radius — gym low-light friendly; full support for light-mode system contrast via dynamic colors where system components are used.
- **SF Pro Display** for Heavy uppercase headlines, **SF Pro Text** for body — American sports-poster feel.
- **Minimum 56pt touch targets** on primary buttons (wrestlers tap with sweaty hands/after practice).
- **HIG: In-App Purchase** — paywall shows prices, trial length, links to EULA/Privacy, restore button.
- **HIG: Health** — weight content includes disclaimer, 13+ rating, no medical claims, "We coach the cut, not the crash."
- **HIG: Privacy** — video stays on-device (only extracted frames leave, temporarily); Data Not Collected privacy-label target; no account system (anonymous device ID in Keychain).
- **HIG: Notifications** — Sunday weigh-in reminder and streak nudges are opt-in with one-screen permission primer; app remains fully usable if all permissions are denied.
- **Accessibility**: VoiceOver labels on all event cards and charts; Dynamic Type in body text; captions on video player controls.

---

## Technical Architecture

- **Language**: Swift 5.9+, strict SwiftUI + async/await
- **Min target**: iOS 17.0 (`iOSApplicationExtension`/SwiftData requires 17+); Apple FM gated `@available(iOS 18.1, *)`
- **Data**: SwiftData (@Model) → CloudKit private database sync (automatic, zero backend); UserDefaults/Keychain for device identity and quota counters
- **Networking**: URLSession only (no third-party networking libs)
- **Video**: AVFoundation (PhotosPicker / AVCaptureSession capture → AVAssetExportSession HEVC 720p ≤60MB → AVAssetImageGenerator frame extraction 1fps + scene-change densified, ≤36 frames @640px JPEG)
- **Cloud AI**: Cloudflare Worker proxy (independent deploy) → GLM-5.3-Flash `https://api.z.ai/api/paas/v4/chat/completions`; `thinking: {level:"low"}` mandatory; `max_tokens ≥ 8192` for vision tasks; `response_format: {"type":"json_object"}`
- **IAP**: StoreKit 2, zero third-party SDK
- **GLM model behavior rules (verified 2026-09-17, MUST follow)**:
  1. `glm-5.3-flash` **always thinks** — cannot be disabled (error 1210 if attempted); set `thinking: {"level":"low"}` to save tokens
  2. `max_tokens` must be generous — reasoning tokens count against the budget; vision/structured output needs **≥8192**
  3. Structured output via system-prompt constraint + `response_format: json_object`; client ignores `reasoning_content`

## Module Structure

```
TakedownIQ/
├── App/                     # Entry, TabView, routing, AppState
│   ├── TakedownIQApp.swift
│   └── RootTabView.swift
├── Features/
│   ├── Onboarding/          # 3-frame value carousel + 4-question quiz + permission primer
│   ├── Home/                # Streak flame, quota ring, FILM IT button, today's drills, fix rate
│   ├── Film/                # Capture, frame extraction, queue, timeline results, player
│   ├── Plan/                # Daily drills, timer, streak engine
│   ├── Library/             # Technique library (40+ built-in cards, searchable)
│   ├── Weight/              # Safe Cut: weigh-ins, safe curve chart, weekly report
│   ├── Stats/               # Match log, career stats, badges
│   ├── Coach/               # Coach Chat (Apple FM + fallback)
│   └── Paywall/             # StoreKit 2 paywall, transparent pricing, manage/cancel
├── Core/
│   ├── AI/                  # GLMClient, AppleAICoach, ResponseValidator, prompts
│   ├── Video/               # FrameExtractor, compressor, scene-change detection
│   ├── Models/              # SwiftData @Model + Codable structs
│   ├── Sync/                # CloudKit container config
│   └── Support/             # Contact support (backend: https://msg.calcs.top)
└── Proxy/                   # Cloudflare Worker (independent deployment)
    ├── worker.js
    ├── wrangler.toml
    └── package.json
```

---

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features (MVP scope, source guide §4.1)

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | **Onboarding (≤15s)** | 1. First launch → 3-frame value carousel (Film→Fix→Win) → 2. 4 multiple-choice questions (position: Neutral/Top/Bottom/All; level: 1–3 yrs/4+ yrs/Veteran; big-event month slider; training days/week) → 3. One-screen permission primer (camera/photos/notifications, each optional, denial OK) → 4. "Build my plan" generated instantly via Apple FM or template | Quiz answers | Build UserProfile; generate first daily drill plan (Apple FM `@Generable`, fallback: template library) | Personalized plan ready; land on Home | SwiftData `UserProfile` → CloudKit | Onboarding completes in ≤15s of interaction; plan visible within 2s of tapping |
| 2 | **Film Breakdown** (core) | 1. Home → giant FILM IT button → 2. Capture (camera with hip-height/landscape coaching banner) or PhotosPicker or last match → 3. 30s "where am I in frame" chips (close-up/red singlet/blue singlet/solo drill) → 4. Upload with spinning loader + rotating meme copy ("Watching your footwork...", "Counting your escapes...", "Shaking head at the sprawl...") → 5. Timeline results | Video file (≤3 min), optional identity chips | Compress HEVC 720p ≤60MB → extract ≤36 frames (1fps + scene-change densified) → batch 6 frames/request via Worker → GLM-5.3-Flash vision → validator (timestamps must match sent frames ±0.05s; enums legal; confidence clamped 0–1) → 2nd-stage GLM text call aggregates summary + top-3 drills → persistence | Timeline of event cards: 🟢 good / 🔴 mistake / 🟡 chance, each with frame thumbnail + timestamp + ≤8-word title + WHERE/WHY/NEXT prescription + confidence badge + drill link; overall summary card; ADD TO TODAY'S DRILLS sticky button | SwiftData `BreakdownResult` + `EventObservation` (cascade) → CloudKit; thumbnails in local Caches; video local-only, user-deletable | End-to-end ≤40s for 30s clip; confidence<0.6 renders honest "Tough angle" card (dashed border + filming tip), never a fake conclusion; network loss → task persists in queue and retries; killed app → queue resumes; events with out-of-range timestamps are dropped by validator, never shown |
| 3 | **Drill Plan (daily)** | Home → today's drill list → tap checkbox to complete (particle burst) → built-in timer per drill | Onboarding profile + breakdown top-3 prescriptions (auto-insert at top of queue) | Apple FM `@Generable DrillPlan` (3–5 drills, 15–20 min, focus neutral/top/bottom/conditioning, one coaching cue each); fallback: template library; breakdown prescriptions jump the queue | Checkable drill cards with timer; tomorrow's plan preview on Home | SwiftData `DrillPlan`/`DrillItem` → CloudKit | Plan generates in ≤2s (FM) or instantly (template); completing ≥1 drill keeps streak alive; failed drill completion from breakdown inserts at position 1 |
| 4 | **Technique Library** | Library tab → search / filter by position → open card | Search text | Local JSON of 40+ folkstyle technique cards (steps, key points, common mistakes) | Readable cards, offline | Bundled JSON (read-only) | Fully offline; free for ALL users; search matches title + tags |
| 5 | **Match Log** | Stats tab → + button → quick entry (win/loss, tech score, pin, opponent optional) → save | Match result fields | Career aggregation: W-L, pins, tech falls; milestone detection (50-win badge etc.) | Career stats page + badge wall with milestone celebrations | SwiftData `MatchRecord` → CloudKit | Entry ≤10 seconds; badges fire on thresholds; survives reinstall via CloudKit |
| 6 | **Safe Cut (exclusive)** | Onboarding sets target weight class + weigh-in day → daily/weekly morning weigh-in (manual keypad entry or HealthKit read-only) → safe-curve comparison → verdict | Weight entries, hydration self-check questionnaire (on yellow/red), HealthKit body mass (read-only, opt-in) | **Pure rule engine (§8.8) — never LLM for verdicts**: weekly loss ≤1.0% = green (maintain); 1.0–1.5% = yellow (slow down, +200 kcal/day); >1.5%/wk or >3% in 48h = red (STOP: move up a class or push weigh-in date + hydration questionnaire + disclaimer). HARD BLACKLIST both at generation and display: dehydrate, sauna, spitting, laxative, skipping meals, water pills — never output. Green/yellow advice can be polished by Apple FM (wording only; numbers/instructions untouched) | Curve chart (green band / yellow / red), daily verdict card, parent-shareable weekly report card | SwiftData `WeighIn` → CloudKit | Red line always triggers STOP template; blacklist terms never appear in any output (unit test enforced); units follow user setting lb/kg; parent weekly report shares via share sheet |
| 7 | **Coach Chat** | Coach tab → type question ("My bottom game keeps getting broken down") → answer streams | Question + user profile context + recent drill IDs | Apple FM `LanguageModelSession` (iOS 18.1+): ≤120 words, always ends with ONE concrete drill; **hard block weight-cut topics** → fixed redirect text. iOS <18.1 fallback: keyword search over technique library. Free tier: 5 answers/day; Pro: unlimited | Chat bubbles; fallback results presented as technique cards | Conversation history SwiftData → CloudKit | Never crashes without Apple Intelligence; weight-topic refusal string exact; free count enforced locally and honest |
| 8 | **Streak & Motivation** | Automatic from behavior | Drill completions, breakdown completions | StreakEngine: same-day dedupe; gap==1 → +1 else reset to 1; best tracked; monthly "revive card" (1/month, next-day makeup keeps streak); weekly summary notification; milestone pushes | Home flame + count, badge popups, share card (breakdown count + best play) | SwiftData `StreakState` → CloudKit | Revive card works exactly once per calendar month; streak numbers match drill history; local notifications fire when scheduled |
| 9 | **Quota Engine (free tier)** | Automatic | Breakdown runs | Free: 1 breakdown/day; Pro: soft cap 30/day (marketed as Unlimited); counted locally (UserDefaults) + mirrored to CloudKit (anonymous); Worker soft-caps 25/day/device via KV regardless | Home quota ring; paywall entry when exhausted with "come back tomorrow" or upgrade CTA | UserDefaults + CloudKit + Worker KV | Free user can always run exactly 1/day; deleting/reinstalling app still capped by Worker per device fingerprint; quota UI never lies |
| 10 | **Paywall & Pricing Transparency** | Triggered by quota exhaustion / Settings → Upgrade | StoreKit 2 products | PaywallModel: fetch products, purchase, `Transaction.updates` listener, currentEntitlements refresh, Family Sharing; Manage subscriptions deep-link (`AppStore.showManageSubscriptions`) | Paywall: 3-up value grid (Unlimited breakdowns / Safe Cut full engine / Reel export), price table with yearly highlighted "Most wrestlers pick this", auto-renew disclosure, EULA + Privacy links, Restore, Manage in 2 taps | StoreKit 2 (no local entitlement storage) | Sandbox purchase/restore/cancel all pass; season pass (non-renewing) grants Pro 90 days; prices render from StoreKit (never hardcoded); manage-subscriptions reachable from paywall AND Settings in 2 taps |
| 11 | **Settings & Support** | Profile/Settings tab | User preferences | Units (lb/kg), notifications toggles, CloudKit status, Contact Support (preset subject tiles + required fields → https://msg.calcs.top), About, version from `Bundle.main.infoDictionary` (never hardcoded) | Working settings; support messages send successfully | UserDefaults; support via network | Version string matches Xcode MARKETING_VERSION; support works offline-graceful (clear error + retry) |
| 12 | **Share Cards (viral)** | After breakdown / milestone → share | Rendered summary stats | SwiftUI `ImageRenderer` → share card image (meme-aware copy) | System share sheet | none (ephemeral) | Card renders at correct resolution; includes app name + result stats |

### V1.1 Features (post-launch, do NOT build in MVP but keep architecture hooks)
| # | Feature | Note |
|---|---------|------|
| V1.1-a | Coach Mode: 6-digit team code (CloudKit sharing) → assign drill homework → team completion heatmap | Source §4.2; hooks: DrillItem already has `sourceCoach`-ready field not required in MVP |
| V1.1-b | Recruiting Reel: multi-match highlight auto-edit export with watermark (Pro) | Pro feature flag ready |
| V1.1-c | Newbie Path: 7-day beginner path reusing library + daily plan | Content-module reuse |
| V1.1-d | Apple Watch: drill timer + quick score | No MVP dependency |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 2.1 | Film Breakdown | Filming guidance banner | Persistent bottom bar on camera: "Phone low (hip height) · landscape · whole body in frame" | Always visible during capture |
| 2.2 | Film Breakdown | Pre-flight frame probe | Before spending quota: 1-frame probe; if subject occupancy <30% or extracted frames <6 → abort with re-film guidance, no GLM call | Automatic with honest message |
| 2.3 | Film Breakdown | "Unclear" honest card | confidence<0.6 or unclear=true → dashed-border translucent card: "Tough angle — next time film from hip height" + correct-position mini-diagram | Tap → expands tip |
| 2.4 | Film Breakdown | Player frame jump | Tap event card → player seeks to t, auto 0.5× slow-mo, prescription below | Tap card |
| 2.5 | Film Breakdown | Meme loading copy | Rotating lines during upload | Auto-rotate ~2.5s |
| 6.1 | Safe Cut | Sunday Weigh-In reminder | Local notification Sunday 9pm | Opt-in toggle |
| 6.2 | Safe Cut | Parent weekly report | One-tap shareable card with curve snapshot + verdict | Share button |
| 8.1 | Streak | Revive card | Break-fire protection: 1/month, next-day makeup keeps streak | Prompt appears once |
| 10.1 | Paywall | Season Pass psychology | "Buy the season" positioning; 90-day non-renewing; anchored vs annual | Price table row |
| 10.2 | Paywall | Cancel path copy | "Manage in 2 taps" link text, opens system management sheet | Tap link |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Breakdown → Drill Plan | Film Breakdown result | Today's Plan | Top-3 drill prescriptions (drill_id list) | User taps ADD TO TODAY'S DRILLS or auto after result |
| Breakdown → Library | Event card drill_id | Technique Library card | drill_id lookup | Tap drill link on event card |
| Breakdown → Streak | Completed first breakdown of day | StreakEngine | touch(date) | On result acceptance |
| Drill completion → Streak | Drill checkbox | StreakEngine | touch(date) | Any completion |
| Drill completion → Fix rate | "Mark as fixed" on past mistake events | Home fix-rate stat | fixed count / total mistakes | User marks event fixed |
| Weigh-ins → Notifications | Weigh-in day setting | Sunday 9pm reminder | schedule local notification | Onboarding/s settings change |
| Quota → Paywall | QuotaEngine exhausted | Paywall view | present paywall | Tap FILM IT with 0 left |
| Profile → All AI | Onboarding quiz | GLM prompt context + FM instructions | level/position/weeks-to-event/days | Profile change |
| Match Log → Badges | MatchRecord count | Badge wall | thresholds (50 wins) | On save |
| Coach Chat → Library | FM answer drill mention | Library deep link | drill_id | Tap drill chip in answer |

**VERIFICATION CHECK**: Chinese guide §4.1 defines 7 MVP modules (Film Breakdown, Drill Plan, Technique Library, Match Log, Safe Cut, Coach Chat, Streak) — expanded here into 12 primary features (adds Onboarding, Quota, Paywall, Settings/Support, Share Cards which the guide also requires in §5/§6/§9). ✅ Match confirmed.

---

## ⚠️ Data Flow Diagram (MANDATORY — Every Feature's Data Lifecycle)

### Feature: Film Breakdown (primary data flow)
```
User Input: video (capture/PhotosPicker) + identity chips + profile
    │
ViewModel: FilmBreakdownViewModel
    └── validate (≤3min) → compress (HEVC 720p ≤60MB, background Task.detached)
    └── FrameExtractor.extract (≤36 frames, 640px JPEG, t-anchored)
    └── pre-flight probe (subject ≥30%, frames ≥6) else abort honestly
    └── enqueue BreakdownTask (SwiftData persisted; survives kill)
    │
GLMClient (actor) via Cloudflare Worker proxy
    └── POST {userId(device), payload{model:glm-5.3-flash, messages:[vision frames base64], thinking:{level:"low"}, max_tokens:8192, response_format:json_object}}
    └── header X-Device-ID; timeout 90s; heartbeat; cancellable (Task.cancel)
    │
ResponseValidator (never persist half-valid data)
    └── strip choices[0].message.content (ignore reasoning_content) → parse JSON
    └── REJECT events whose t doesn't match a sent frame (±0.05s) — kills hallucination
    └── kind enum whitelist {mistake,good,chance}; confidence clamp [0,1]
    └── fail → auto-retry once → still fail → fallback copy + retry button
Stage 2: single GLM text call aggregates observations → summary + top-3 drills
    │
Persistence: BreakdownResult(@Model) ←cascade→ [EventObservation] → CloudKit private DB
    │
Display: Timeline UI (thumbnail cache local), player seek + 0.5×, prescription cards
    │
Cross-Feature: top drills → Drill Plan queue; completions → StreakEngine; drill_id → Library
```

### Feature: Safe Cut
```
User Input: weight (manual keypad / HealthKit read-only) + hydration questionnaire
    │
ViewModel: SafeCutViewModel → SafeCutEngine.evaluate (PURE RULES, no LLM for verdicts)
    └── weekly rate: <1.0% green · 1.0–1.5% yellow(+200kcal/day) · >1.5%/wk or 3%/48h red(STOP)
    └── blacklist filter (dehydrate/sauna/spitting/laxative/skip meals) at BOTH generation & display
    │
Persistence: WeighIn(@Model) → CloudKit
    │
Display: curve chart (green band/yellow/red) + verdict card + parent weekly report (share sheet)
    │
Cross-Feature: weigh-in day → local notification schedule; red verdict → hydration questionnaire
```

### Feature: Drill Plan
```
User Input: onboarding profile + breakdown prescriptions (queue-jump)
    │
ViewModel: PlanViewModel
    └── iOS 18.1+: AppleAICoach.todayPlan (@Generable DrillPlan) — free, on-device
    └── else/failure: template library (deterministic by level/position/days)
    │
Persistence: DrillItem(@Model, done, order, sourceBreakdownID?) → CloudKit
    │
Display: today's checklist + timer + tomorrow preview
    │
Cross-Feature: completions → StreakEngine.touch; fix-rate aggregation from marked-fixed events
```

### Feature: Coach Chat
```
User Input: question text
    │
ViewModel: CoachChatViewModel
    └── iOS 18.1+: LanguageModelSession(instructions with hard weight-topic block) → reply
    └── iOS <18.1: keyword search over technique JSON → technique cards response
    └── free tier counter: 5/day (local+CloudKit); Pro unlimited
    │
Persistence: ChatMessage(@Model) → CloudKit
    │
Display: chat bubbles; drill chips deep-link to Library
```

### Feature: Quota Engine
```
Trigger: FILM IT tap
    │
QuotaEngine (actor): usedToday() from UserDefaults (day-keyed) + CloudKit mirror
    └── free: 1/day · pro: 30/day soft · Worker KV independent 25/day/device
    └── allowed → run breakdown; denied → paywall or "back tomorrow" card
```

### Feature: Paywall
```
Trigger: quota exhausted / Settings
    │
PaywallModel (StoreKit 2): Product.products → purchase → Transaction.updates listener
    └── currentEntitlements → pro flag (monthly/yearly/season)
    │
Display: value grid + price table + auto-renew text + EULA/Privacy links + Restore + Manage(2 taps)
    │
Cross-Feature: pro flag → QuotaEngine limits, Coach Chat limit, Safe Cut full engine, (V1.1 reel export)
```

**VERIFICATION CHECK**: every primary feature above has a complete input→ViewModel→persistence→display→cross-feature path. ✅

---

## Implementation Flow

1. **W1 Skeleton**: xcodegen project (SwiftUI app, iOS 17.0, bundle com.zzoutuo.TakedownIQ, Team JP4TN5PTS3) → SwiftData models + CloudKit container → Tab framework (Home / Film / Plan / Stats / Profile) → build green on simulator
2. **W1-2 Video pipeline**: PhotosPicker + AVCaptureSession → HEVC compress → FrameExtractor (1fps + scene-change) — verify: 30s video → ≤36 frames <3s on device
3. **W2 AI pipeline**: deploy `tdiq-glm-proxy` Cloudflare Worker (KV rate limit 25/day/device, payload ≤8MB, frames ≤6/request) → GLMClient (actor) → ResponseValidator (timestamp anchoring, enum whitelist, confidence clamp, 1 retry, fallback copy) — verify end-to-end with 3 real test videos
4. **W3 Result UX**: timeline 3-color cards + player frame-jump + 0.5× + drill insert + streak wiring
5. **W3-4 Free tier**: QuotaEngine + Technique Library (40+ cards JSON) + Match Log + badges
6. **W4 Safe Cut**: weigh-in flow + safe curve + rule engine + blacklist + HealthKit read-only
7. **W5 Monetization**: StoreKit 2 products + paywall (transparent pricing, 2-tap manage, restore) + Family Sharing
8. **W5-6 Polish**: Apple FM Coach Chat (+fallback), notifications, deep links, accessibility, privacy labels ("Data Not Collected"), review notes + demo video

**Hard engineering rules (from source guide §5, non-negotiable):**
1. Free quota stored locally (UserDefaults+CloudKit anonymous) — zero backend user accounts
2. All AI async + queue-persisted (survives kill/network loss)
3. Every AI output passes the structured validator before persistence — never show half-valid data
4. All copy in American English; weight units per user setting (lb/kg)
5. Write the degradation path first, the ideal path second (FM unavailable → template; GLM unavailable → queue)

---

## UI/UX Design Specifications ("Mat Room Dark")

| Token | Value | Usage |
|---|---|---|
| Background | `#0B0D0C` | Global dark, gym low-light friendly |
| Accent (Volt) | `#C8FF2E` | CTA, streak flame, good-play highlight |
| Danger | `#FF4D3D` | Mistake cards, red-line warning |
| Chance | `#FFC53D` | Chance cards |
| Success | `#3DDC84` | Completion states, green cards |
| Surface | `#151918`, radius 20pt | Cards |
| Typography | SF Pro Display Heavy ALL-CAPS headlines; SF Pro Text body | American sports-poster feel |
| Graphic motif | Mat-texture noise background, thick diagonal color bands | Differentiation |
| Touch | ≥56pt primary buttons | Sweaty-hand usable |

**Key screens:**
1. **Home**: streak flame + daily quota ring → giant Volt FILM IT button (¼ screen) → today's drills horizontal cards (check = particle burst) → weekly fix-rate big number ("Fixed 7 of 12 mistakes")
2. **Breakdown result**: player on top (tap event → jump + 0.5×) → timeline 3-color card stream (thumb left, title center, confidence badge right) → sticky ADD TO TODAY'S DRILLS
3. **"Unclear" card**: translucent + dashed border: "Tough angle — next time film from hip height" + mini positioning diagram
4. **Weight**: big numeric keypad entry → safe-band curve chart (green in-band, yellow caution, red stop) → parent weekly report share card
5. **Paywall**: 3-up value grid → price table (yearly highlighted "Most wrestlers pick this") → gray footer: prices, trial, **Manage in 2 taps**
6. **Loading/empty states**: spinner + rotating meme copy ("Even the ref needs a break.") — never a blank wait

**Trend alignment**: Cal AI/Opal onboarding pacing + HabitKit grid addiction + 2026 dark-volt aesthetic — but INVERTED onboarding: **≤15 seconds**, trust as the selling point.

**3-second rule**: every screen shows a comprehensible dopamine hit within 3s (big number/progress/flame/badge) — no professional-chart dumps. Prescriptions must always end in a doable action today; "watch your footwork" style fluff is forbidden.

---

## Code Generation Rules

- One feature per module, high cohesion, low coupling; MVVM with @Observable
- No comments in code unless logic is non-obvious; semantic naming
- Apple-native first: SwiftUI, SwiftData, StoreKit 2, CloudKit, AVFoundation, FoundationModels — **zero third-party runtime dependencies** (URLSession suffices)
- Money as `Decimal`; dates via `Calendar.current`; weight via `Measurement`
- Every feature's degradation path exists and is tested
- Version read dynamically from `Bundle.main.infoDictionary`
- Contact Support module integrated with backend `https://msg.calcs.top`

## Build & Deployment Checklist

- [ ] xcodegen project builds green (iPhone + iPad simulators)
- [ ] SwiftData + CloudKit container "iCloud.com.zzoutuo.TakedownIQ" entitlement
- [ ] End-to-end film breakdown passes via deployed `tdiq-glm-proxy`
- [ ] Free tier fully usable offline (template fallbacks)
- [ ] StoreKit 2 sandbox: purchase/restore/cancel/season-pass all pass
- [ ] Safe Cut blacklist unit tests pass
- [ ] Privacy: Data Not Collected labels; video local-only
- [ ] Review notes: free tier needs no key; demo video attached
- [ ] App name "Takedown IQ" availability re-verified in App Store Connect (backup names: Sudden Victory → MatEdge → RideTime)
