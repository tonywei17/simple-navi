---
name: swift-conventions
description: Swift and iOS development conventions for SimpleNavi. Use when writing, reviewing, or refactoring Swift code, creating new SwiftUI views, or working with iOS frameworks like CoreLocation, MapKit, WidgetKit, or ActivityKit.
user-invocable: false
---

# Swift & iOS Conventions — SimpleNavi

## Project Overview

SimpleNavi is a compass-based navigation app with widget support. It targets **iOS 18.0+** and is forward-compatible with **iOS 26** (Liquid Glass).

- **Bundle ID**: `com.simplenavi.simplenavi`
- **Xcode Project**: `SimpleNavi.xcodeproj`
- **Scheme**: `SimpleNavi`
- **No external dependencies** — pure Swift + native frameworks

## Architecture: MVVM

- **View**: SwiftUI views — layout and presentation only, no business logic
- **ViewModel**: `@MainActor @Observable final class XxxViewModel` — owns state and logic
- **Model**: Plain `struct` types conforming to `Codable` where applicable
- **Service/Manager**: Singleton pattern with `.shared` for system-level concerns

```swift
@MainActor
@Observable
final class CompassViewModel {
    private(set) var displayHeading: Double = 0
    private let locationManager = LocationManager.shared
}
```

## SwiftUI Patterns

- Use `@Observable` (iOS 17+) instead of `ObservableObject` for new ViewModels
- Use `@State` for view-local state, `@Environment` for app-wide dependencies
- Extract sub-views as `private var` computed properties when `body` exceeds ~40 lines
- Use `task { }` modifier for async work on appear
- Prefer `.sheet(item:)` over `.sheet(isPresented:)` when passing data
- Always handle loading / error / empty states in views

## iOS Version Compatibility

This app must work on **iOS 18** and be forward-compatible with **iOS 26**.

```swift
// Use availability checks for iOS 26+ features
if #available(iOS 26, *) {
    // Liquid Glass, new APIs
} else {
    // iOS 18 fallback
}
```

- Use `@available(iOS 26, *)` annotations on iOS 26-only views/extensions
- Never use `#unavailable` for feature gates — always use positive checks
- Test on both iOS 18 simulator and iOS 26 simulator

## Key Frameworks

| Framework | Usage |
|-----------|-------|
| CoreLocation | Heading, user location |
| MapKit | Address confirmation map |
| WidgetKit | Home screen widgets |
| ActivityKit | Live Activities / Dynamic Island |
| CryptoKit | AES-256 GCM encryption |
| StoreKit 2 | In-app donations |

## Localization

- Three languages: English, 简体中文, 日本語
- Use `LocalizationManager.shared` for all user-facing strings
- Add new keys to the `LocalizedStringKey` enum

## Security

- Store sensitive data (addresses) via `SecureStorage` (AES-256 GCM + Keychain)
- NEVER store plain coordinates or addresses in UserDefaults
- Use App Group (`group.com.simplenavi`) for widget data sharing only

## File Naming

- One primary type per file, file name matches type: `CompassViewModel.swift`
- Views: `XxxView.swift`
- ViewModels: `XxxViewModel.swift`
- Managers/Services: `XxxManager.swift`, `XxxService.swift`

## Error Handling

- All custom error types must conform to `LocalizedError`
- Never silently catch errors — always provide user feedback or logging
- Use `Result` types for operations that can fail
- Add timeouts to all network/geocoding operations
