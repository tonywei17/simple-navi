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

---

Date: 2025-09-14 (JST)

## Summary
- Major UX pass on address setup and confirmation flows. Simplified interactions, improved small-screen responsiveness, and removed optional features to streamline user flow.

## Details

### Address confirmation view
- File: `SimpleNavi/AddressMapConfirmView.swift`
  - Replaced the top address text with an auto-sizing, non-scrolling editor (`AutoSizingTextView`) so the full address is always visible, even on small screens.
  - Removed the "map adjusted — update address?" prompt and the Yes/No buttons, simplifying the flow. Address text now automatically follows the map center with reverse geocoding.
  - Added friendly reverse-geocode fallback and message: if reverse geocoding fails, show a localized message `reverseGeocodeFailed` and display coordinates as a fallback string.
  - When the incoming address is empty, auto-center to user location (once) and populate address from reverse geocoding.
  - Tuned layout for compact devices (e.g., iPhone 12 mini): adaptive horizontal paddings, dynamic map height (`~40%` of screen height with bounds), and clamped container widths to prevent overflow.
  - Always show the map confirm flow and ensure confirm uses: map center coordinate + current address text.

### Setup views
- File: `SimpleNavi/SetupView.swift`
  - `ModernAddressInputField`:
    - Always show the "Map Confirm" button (even when the text is empty).
    - Address inputs are multi-line on iOS 16+, with a clear (reset) button for each field.
  - Globally removed address suggestions/auto-complete UI and all related logic.

- File: `SimpleNavi/SetupViewSimple.swift`
  - Switched to auto-save model: inputs bind directly to `@AppStorage`. Removed Save/Cancel buttons; only the back button remains.
  - Automatically marks `UDKeys.hasSetupAddresses` true when `address1` becomes non-empty.

### Donation view
- File: `SimpleNavi/DonationView.swift`
  - Removed the unused "custom amount" entry to comply with App Store rules (IAP must be pre-defined SKUs).

### Localization
- File: `SimpleNavi/LocalizationManager.swift`
  - Added localized key `reverseGeocodeFailed` for friendly fallback messaging (en/zh/ja).
  - Previously added Yes/No and map adjusted strings remain for potential future use, but the prompt is currently disabled.

## Notes
- Width overflow on compact devices was addressed by:
  - Adaptive paddings and removing hard widths.
  - Passing an accurate available width to the auto-sizing text view for measurement.
  - Using character-based wrapping for CJK text.

## Next Steps
- Optional: localize the coordinate fallback format (e.g., labels for latitude/longitude in ja/zh/en) and/or switch to DMS format.
- Optional: apply the same auto-save approach to `SetupView.swift` if desired.
