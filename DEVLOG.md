# DEVLOG

Date: 2025-09-13 (JST)

## Summary
- Integrated StoreKit 2 tip-jar (consumable) purchases and switched Product IDs to prefix `com.simplenavi.simplenavi.tip.*`.
- Added IAP localization assets (JSON/CSV) for en-US, ja-JP, zh-Hans.
- Wrote a complete App Store submission checklist tailored to SimpleNavi.
- Configured new iOS 26-style app icon (Default) and prepared a script to generate the complete icon set.

## Details

### StoreKit 2 Integration
- File: `SimpleNavi/DonationView.swift`
  - Implemented `IAPManager` to load products, purchase, and listen for transactions using StoreKit 2.
  - Product IDs:
    - `com.simplenavi.simplenavi.tip.small`
    - `com.simplenavi.simplenavi.tip.medium`
    - `com.simplenavi.simplenavi.tip.large`
  - UI now shows `product.displayPrice` and displays a Thank-You alert only on verified success.

### IAP Localization Assets
- Files:
  - `StoreKit/IAP_Localization.json`
  - `StoreKit/IAP_Localization.csv`
- Locales: en-US, ja-JP, zh-Hans
- Pricing tiers (suggested): small → Tier 2, medium → Tier 5, large → Tier 10

### App Store Submission Checklist
- File: `AppStore_Submission_Checklist.md`
- Covers: agreements & banking, privacy, assets, IAP config, TestFlight, submission questionnaire, and common rejection pitfalls.

### App Icon (iOS 26 style)
- Asset: `SimpleNavi/Assets.xcassets/AppIcon.appiconset`
- Default marketing icon: `simple-navi-iOS-Default-1024x1024@1x.png` (also copied as `AppIcon-1024.png`).
- Updated `Contents.json` to map all required slots to specific filenames. A generator script is provided to produce exact-size PNGs.

### Scripts
- File: `scripts/generate_app_icons.sh`
- Usage:
  ```bash
  chmod +x scripts/generate_app_icons.sh
  bash scripts/generate_app_icons.sh "simple-navi Exports/simple-navi-iOS-Default-1024x1024@1x.png"
  ```
- Output: writes all required icon sizes into `AppIcon.appiconset/` with names matching `Contents.json`.

## Next Steps
- Create the three Consumable IAPs in App Store Connect and link them to the next app submission.
- Run the icon generation script to finalize all sizes, then re-build.
- Prepare screenshots (6.7" & 5.5") and submit app + IAP for review.
