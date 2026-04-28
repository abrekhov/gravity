# Gravity Game — Dev Guide

Flutter/Flame iOS puzzle game. Bundle ID: `com.gravity.gravityGame`. Indie, no PRs needed.

## Branch Strategy

**Push directly to `main`.** No feature branches. Every push to main auto-deploys to TestFlight.

## Deployment

| What | How |
|------|-----|
| TestFlight | Auto on push to `main` — build number = `github.run_number` |
| GitHub Pages (web demo) | Auto on push to `main` |
| App Store metadata | `gh workflow run appstore-metadata.yml` |
| Review notes | `gh workflow run set-review-notes.yml` |
| App Store status | `gh workflow run check-status.yml` |
| IAP setup | `gh workflow run setup-iap.yml` |
| Submit for review | `gh workflow run submit-for-review.yml` |

## Key Files

```
app/
  lib/
    game/gravity_game.dart     # Flame engine, level loading, input, navigation
    game/level_data.dart       # 31 level definitions (const)
    game/physics.dart          # Gravity simulation, trajectory preview
    overlays/                  # All screens: main_menu, level_select, hud, win, fail, premium
    services/ad_service.dart   # AdMob — requests ATT, then loads/shows interstitial
    services/purchase_service.dart  # StoreKit IAP — premium unlock
  pubspec.yaml                 # version: 1.0.0+1 (keep pinned)
  ios/Runner/Info.plist        # GADApplicationIdentifier, NSUserTrackingUsageDescription
fastlane/Fastfile              # All automation lanes
```

## Version & Release Flow

- Version in `pubspec.yaml` — bump patch (`1.0.0` → `1.0.1`) for each App Store release.
- Build number is set automatically by CI (`github.run_number`). Never set it manually.
- **Release flow**: bump version → push to `main` → CI builds TestFlight → wait for processing → `gh workflow run submit-for-review.yml`
- Once a version is released on the App Store, you must increment the version string to submit again.

## Fastlane Lanes

| Lane | Purpose |
|------|---------|
| `beta` | Build + sign + upload to TestFlight (used by CI) |
| `submit_metadata` | Push name, description, keywords, category to ASC |
| `set_review_notes` | Fill App Review Information (contact, notes, external services) |
| `submit_for_review` | Create ASC version, attach latest build, submit for review |
| `check_status` | Print current App Store version state |
| `setup_iap` | Create/update the premium IAP product in ASC |

## App Architecture

- **Navigation**: Flame overlay system — `game.overlays.add/remove('ScreenName')`. No router.
- **Screens**: `MainMenu` → `LevelSelect` → game with `HUD` → `WinOverlay` / `FailOverlay`
- **Levels 1–10**: free. **Levels 11–31**: require premium IAP (`com.gravity.gravityGame.premium`, $2.99).
- **Ads**: interstitial shown every 3rd win and every fail retry (skipped for premium users).
- **ATT**: requested at app start before AdMob initialises — required for ads to render on iOS 14+.

## AdMob

- Debug builds use Google's test ad unit ID automatically (`kDebugMode`).
- Production uses `ca-app-pub-7949208513831938/5216083131`.
- Black screen / no close button = ATT not requested. Already fixed.

## App Store Connect Secrets (GitHub)

`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_API_KEY`, `MATCH_PASSWORD`, `MATCH_GIT_URL`, `MATCH_GIT_USER`, `MATCH_GIT_TOKEN`

Certificates stored in `abrekhov/gravity-certificates` (encrypted with `MATCH_PASSWORD`).

## gh CLI

```bash
export GH_TOKEN="<your-token>"  # generate at github.com/settings/tokens — stored in ~/.bashrc
gh workflow run testflight.yml --repo abrekhov/gravity
gh run list --repo abrekhov/gravity --limit 5
```
