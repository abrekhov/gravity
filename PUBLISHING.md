# Publishing Plan: iOS App Store + macOS + Monetisation

## Context
Flutter/Flame game (30 levels, deployed to GitHub Pages). Goal: publish on the iOS App Store
and macOS, with ads for free users and levels 11–30 locked behind a one-time IAP.
Developer is based in the Netherlands (KVK jurisdiction).

---

## Part 1 — Business & Legal Setup (do once, in order)

### 1.1 KVK Registration (Netherlands)
- Register as **eenmanszaak** (sole trader) at kvk.nl — €75 one-time fee.
- You get a KVK number and an automatic BTW (VAT) number from Belastingdienst.
- Required before applying for Apple Developer account as a company.
- **Alternative:** publish as a private individual — Apple allows this, no KVK needed,
  but your full name appears on the App Store instead of a company name.

### 1.2 Apple Developer Program
- Enroll at developer.apple.com/programs/enroll — **$99 USD/year**.
- Individual enrollment: just an Apple ID + credit card.
- Organisation enrollment: requires D-U-N-S number (free, request via Apple; ~5 days).
- After enrollment you get access to App Store Connect and Xcode signing.

### 1.3 Tax & Banking
- BTW: digital goods sold to EU consumers → use OSS (One Stop Shop) via Belastingdienst.
  Apple collects and remits VAT on your behalf — no action needed on your side.
- Income tax: IAP revenue comes via Apple (monthly bank transfer). Report as business income.
- Open a **business bank account** (e.g. Bunq, ING Zakelijk) — Apple pays to bank, not PayPal.

### 1.4 Privacy Policy
- Required by Apple (even for games with no user data collected).
- Create a simple page (GitHub Pages or Notion) stating: no personal data collected,
  ads served by Google (AdMob), IAP handled by Apple.
- Free generator: app-privacy-policy-generator.firebaseapp.com

---

## Part 2 — Technical: Add macOS Platform

The `app/` folder has no `macos/` directory yet.

```bash
cd app
flutter create --platforms=macos .
```

This generates `app/macos/` with an Xcode project. Flutter/Flame works on macOS
out of the box — no game code changes needed.

**macOS App Store distribution** requires:
- Enabling Mac App Store capability in Xcode (target → Signing & Capabilities).
- A separate macOS provisioning profile in your Apple Developer account.
- Building with `flutter build macos --release`.

---

## Part 3 — Technical: Monetisation Implementation

### 3.1 Freemium split
- **Free:** levels 1–10 (play forever, ads shown between levels/shots)
- **Premium (one-time purchase):** unlocks levels 11–30 + removes ads
- IAP product ID: `com.gravity.gravityGame.unlockPremium`

### 3.2 New dependencies (`app/pubspec.yaml`)
```yaml
dependencies:
  google_mobile_ads: ^5.1.0      # AdMob interstitial ads
  in_app_purchase: ^3.2.0        # Apple/Google IAP
```

### 3.3 New file: `app/lib/services/purchase_service.dart`
Singleton wrapping `in_app_purchase`:
- `isPremium` bool (persisted via SharedPreferences key `gravity_premium`)
- `buyPremium()` — initiates purchase flow
- `restorePurchases()` — **required** by Apple review guidelines
- Listens to purchase stream, updates `isPremium`, saves to prefs

### 3.4 Ads — `app/lib/services/ad_service.dart`
- Uses `InterstitialAd` from `google_mobile_ads`
- Show ad after every 3 failed shots and after completing a free level
- Skip entirely when `isPremium == true`
- AdMob App IDs must be added to:
  - `ios/Runner/Info.plist` → `GADApplicationIdentifier`
  - `android/app/src/main/AndroidManifest.xml` → `<meta-data>`

### 3.5 Level locking changes

**`app/lib/overlays/level_select.dart`** — extend existing lock logic:
```
isPremiumLocked  = level.id > 10 && !purchaseService.isPremium
isProgressLocked = level.id > game.unlockedLevelId
```
- Progress-locked → grey 🔒 (same as today)
- Premium-locked  → gold 👑 with "PREMIUM" label
- Tapping a premium-locked card → show purchase dialog

**`app/lib/game/gravity_game.dart`** — guard in `startLevel()`:
```dart
if (levelId > 10 && !PurchaseService.instance.isPremium) {
  // show PremiumOverlay instead of starting level
  return;
}
```

### 3.6 New overlay: `app/lib/overlays/premium_overlay.dart`
- "Unlock all 30 levels + remove ads" with price pulled from StoreKit
- "Buy" button → `PurchaseService.buyPremium()`
- "Restore purchases" link (required by Apple)

---

## Part 4 — iOS App Store Submission

### 4.1 App Store Connect setup
1. Create new App → bundle ID `com.gravity.gravityGame`
2. Set app name, subtitle, description (EN + NL)
3. Upload screenshots: iPhone 6.7", iPhone 5.5", iPad 12.9" (use Simulator)
4. Age rating: 4+ (no objectionable content)
5. Privacy policy URL (from step 1.4)
6. Pricing: Free (with IAP)
7. Add IAP product: `unlockPremium`, type: Non-Consumable, price tier ~€2.99

### 4.2 Build & upload
```bash
flutter build ipa --release
# Then upload via Xcode Organizer or xcrun altool
```

### 4.3 App Review notes to include
- "IAP unlocks levels 11–30. Restore purchases button is on level select screen."
- "Ads shown only to free users via Google AdMob."
- Use TestFlight for internal testing before submitting for review.

---

## Part 5 — macOS Distribution

| Option | Pros | Cons |
|--------|------|------|
| **Mac App Store** | Discoverable, trusted | Sandboxing required, separate app record |
| **Direct .dmg download** (notarised) | Simple, no sandbox | Less discoverable |

**Recommendation:** start with a notarised `.dmg` hosted on GitHub Releases.
Add Mac App Store later once iOS is live and stable.

Notarisation requires an Apple Developer ID certificate (included in the $99/year membership).

---

## Summary Checklist

| Step | Who | Cost | Est. time |
|------|-----|------|-----------|
| KVK registration (optional for individual) | You | €75 | 1 day |
| Apple Developer Program enrollment | You | $99/yr | 1–2 days |
| D-U-N-S number (if org enrollment) | You | Free | ~5 days |
| Privacy policy page | You | Free | 1 hour |
| AdMob account + register app | You | Free | 1 hour |
| Add macOS platform (`flutter create`) | Code | — | 30 min |
| Implement IAP + ads + level locking | Code | — | 2–3 days |
| App screenshots + metadata | You | Free | 2–3 hours |
| TestFlight internal beta | You | Free | 1 day |
| App Store review | Apple | Free | 1–7 days |

---

## Files to Create / Modify

| File | Change |
|------|--------|
| `app/pubspec.yaml` | Add `google_mobile_ads`, `in_app_purchase` |
| `app/lib/game/gravity_game.dart` | Premium gate in `startLevel()` |
| `app/lib/overlays/level_select.dart` | Premium lock visual + tap handler |
| `app/ios/Runner/Info.plist` | AdMob App ID |
| `app/lib/services/purchase_service.dart` | **New** — IAP singleton |
| `app/lib/services/ad_service.dart` | **New** — AdMob interstitial wrapper |
| `app/lib/overlays/premium_overlay.dart` | **New** — purchase dialog |
