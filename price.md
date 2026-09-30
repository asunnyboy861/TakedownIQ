# Pricing Configuration

## Monetization Model: Subscription (IAP) + Non-Renewing Season Pass

Free tier is genuinely useful (a real daily habit loop, not a crippled demo); Pro unlocks unlimited cloud film breakdowns, the full Safe Cut engine and export tools. Pricing is transparent by design: public price table on the paywall, "Manage in 2 taps" cancel path, restore purchases — explicitly countering the category's #1 complaint (deceptive subscriptions). No lifetime buyout: cloud video analysis has per-use GLM token costs, so buyouts would be loss-making.

## Subscription Group
- **Group Name**: Takedown IQ Pro
- **Reference Name**: Takedown IQ Pro
- **Products in group**: Pro Monthly, Pro Annual (auto-renewable only)

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: Takedown IQ Pro Monthly
- **Product ID**: `com.takedowniq.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $8.99 USD per month
- **Display Name**: `Takedown IQ Pro Monthly` (23 chars, ≤35 ✅)
- **Description**: `Unlimited breakdowns and full coach tools` (41 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Takedown IQ Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription
- **Reference Name**: Takedown IQ Pro Annual
- **Product ID**: `com.takedowniq.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $49.99 USD per year (44% savings vs monthly; ≈$4.17/mo)
- **Display Name**: `Takedown IQ Pro Annual` (22 chars, ≤35 ✅)
- **Description**: `Unlimited breakdowns and coach tools, 7-day trial` (49 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Takedown IQ Pro (same group as monthly)
- **Free Trial**: 7 days (attached to this tier only)
- **Family Sharing**: ✅ Enabled
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Season Pass (Non-Renewing Subscription, 90 days)
- **Reference Name**: Takedown IQ Season Pass
- **Product ID**: `com.takedowniq.season.pass`
- **Type**: Non-renewing subscription (one-time charge, grants all Pro features for 90 days, does not auto-renew)
- **Price**: $19.99 USD (one-time)
- **Display Name**: `Takedown IQ Season Pass` (23 chars, ≤35 ✅)
- **Description**: `All Pro features for one 90-day wrestling season` (48 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Differentiation Note**: Season Pass covers exactly the same Pro feature set as the subscriptions but for a fixed 90-day window (aligned with the US wrestling season, Nov–Feb) with no renewal — pick it to "buy the season"; pick Annual for the lowest effective monthly price; pick Monthly for shortest commitment. It does NOT unlock anything beyond Pro.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 1 complete AI film breakdown per day (timestamps, frame thumbnails, confidence, prescriptions)
  - Full technique library (40+ folkstyle cards, offline)
  - Daily drill plan (Apple FM on-device or template fallback)
  - Match log with career stats and milestone badges
  - Weigh-in logging + safe curve chart (Safe Cut core)
  - Coach Chat 5 answers/day (Apple FM on-device)
  - Streak tracking with monthly revive card
- **Conversion hooks**:
  - Quota ring shows "1 free breakdown left today" — upgrade CTA at exhaustion
  - Yearly tier highlighted on paywall: "Most wrestlers pick this" (7-day free trial)
  - Safe Cut weekly report sharing (parents see value; full engine is Pro)
  - Honest-feedback screenshots are inherently shareable — each result card ends with a value-forward CTA

## Pro Features Unlocked (All Paid Tiers)

⚠️ Cross-referenced with `capabilities.md` — every row is implemented in MVP code. V1.1 features (Reel export, Coach Mode) are flagged as such and excluded from the paywall until shipped.

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| AI film breakdowns | 1/day | Unlimited (soft cap 30/day) |
| Coach Chat | 5 answers/day | Unlimited |
| Safe Cut full engine (auto-adjust plans, parent weekly reports) | Core curve only | ✅ Full engine + shareable reports |
| Identity chips & advanced breakdown context | ❌ | ✅ |
| Recruiting Reel export (V1.1) | ❌ | ✅ (when shipped) |
| CloudKit sync | ✅ | ✅ (both tiers — never paywall data integrity) |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid annual subscription)
- **Available for**: Pro Annual only (never monthly, never Season Pass)

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions: "Manage in 2 taps")
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page (2-tap manage path)
- [x] Pricing clearly stated in PaywallView (full price table, no dynamic pricing)
- [x] Free trial terms included (7-day, annual tier, auto-renewal disclosure)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (no competitor price comparisons anywhere)
- [x] Season Pass disclosed as non-renewing 90-day one-time charge
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
