---
name: ios-compat
description: iOS 18 and iOS 26 compatibility guidelines. Use when implementing features that need to work across both iOS versions, checking API availability, or handling deprecated APIs.
user-invocable: false
---

# iOS 18 / iOS 26 Compatibility Guide

## Deployment Target

SimpleNavi targets **iOS 18.0** minimum and is forward-compatible with **iOS 26**.

## Availability Check Patterns

### View-level branching

```swift
struct MyView: View {
    var body: some View {
        if #available(iOS 26, *) {
            iOS26Content()
        } else {
            iOS18Content()
        }
    }
}
```

### Modifier-level branching

```swift
extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular)
        } else {
            self.background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
```

### Whole-type availability

```swift
@available(iOS 26, *)
struct LiquidGlassCompass: View {
    var body: some View { /* iOS 26 only */ }
}
```

## Key API Differences: iOS 18 vs iOS 26

### Navigation

| Feature | iOS 18 | iOS 26 |
|---------|--------|--------|
| Navigation | `NavigationStack` | `NavigationStack` (glass bars) |
| Tab Bar | `TabView` | `TabView` (glass treatment) |
| Sheets | `.sheet()` | `.sheet()` (glass background) |

### Visual Effects

| Feature | iOS 18 | iOS 26 |
|---------|--------|--------|
| Blur | `.ultraThinMaterial` | `.glassEffect(.regular)` |
| Vibrancy | `VibrancyEffect` | Built into glass |
| Depth | Manual shadows | System-managed depth |

### CoreLocation (relevant to SimpleNavi)

| Feature | iOS 18 | iOS 26 |
|---------|--------|--------|
| Location auth | `requestWhenInUseAuthorization()` | Same, enhanced privacy UI |
| Heading | `CLLocationManager` | Same |
| Geocoding | `CLGeocoder` | Same, improved accuracy |

### WidgetKit

| Feature | iOS 18 | iOS 26 |
|---------|--------|--------|
| Widget background | Custom backgrounds | Auto glass treatment |
| Interactive widgets | `AppIntent` buttons | Same, enhanced |
| Live Activities | `ActivityKit` | Same, glass Dynamic Island |

### ActivityKit / Live Activities

| Feature | iOS 18 | iOS 26 |
|---------|--------|--------|
| Dynamic Island | Standard layout | Liquid Glass layout |
| Lock Screen | Standard widget | Glass widget |

## SwiftUI Deprecations in iOS 26

Check for these deprecated APIs and provide alternatives:

```swift
// DEPRECATED in iOS 26:
.foregroundColor(.blue)        // → .foregroundStyle(.blue)
.background(Color.red)         // → .background(.red)
.cornerRadius(10)              // → .clipShape(RoundedRectangle(cornerRadius: 10))
.overlay(RoundedRectangle...)  // → .overlay { RoundedRectangle... }

// Already migrated in iOS 18:
onChange(of:perform:)           // → onChange(of:) { oldValue, newValue in }
```

## Testing Strategy

1. **Always test on both iOS 18 and iOS 26 simulators**
2. Use `#available` checks — never assume runtime version
3. Build with Xcode 26 SDK but ensure iOS 18 compatibility
4. Test widget rendering on both versions
5. Verify Live Activities on both versions (when enabled)

## Common Pitfalls

- Using iOS 26-only APIs without `#available` → crash on iOS 18
- Forgetting to test fallback paths → broken UI on older devices
- Removing iOS 18 materials when adding glass → regression
- Not testing widget on iOS 18 after adding glass effects
