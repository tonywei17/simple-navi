---
name: liquid-glass
description: iOS 26 Liquid Glass design system guidelines. Use when creating or updating UI components to support Liquid Glass effects, or when the user mentions Liquid Glass, glassEffect, iOS 26 design, or translucent UI.
user-invocable: false
---

# iOS 26 Liquid Glass Design System

## Overview

Liquid Glass is Apple's new design language introduced in iOS 26 (WWDC 2025). It features translucent, depth-aware surfaces that respond to the content behind them. SimpleNavi must support both iOS 18 (traditional) and iOS 26 (Liquid Glass) styles.

## Core Principles

1. **Content First**: Glass surfaces should enhance, not obscure content
2. **Depth and Hierarchy**: Use glass layers to establish visual hierarchy
3. **Contextual Adaptation**: Glass automatically adapts to underlying content
4. **Minimal Decoration**: Let the material do the work — reduce borders, shadows, and backgrounds

## SwiftUI Liquid Glass API

### Glass Effect Modifier

```swift
// Basic glass effect (iOS 26+)
if #available(iOS 26, *) {
    myView
        .glassEffect(.regular)
}

// Glass effect variants
.glassEffect(.regular)          // Standard translucent glass
.glassEffect(.regular.tint(.blue)) // Tinted glass
.glassEffect(.regular.interactive) // Responds to touch
```

### Navigation Bar Glass

```swift
NavigationStack {
    ContentView()
        .navigationTitle("SimpleNavi")
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
}
// iOS 26 automatically applies glass to navigation bars
```

### Tab Bar Glass

```swift
TabView {
    // tabs
}
// iOS 26 automatically applies glass to tab bars
```

### Custom Glass Containers

```swift
@available(iOS 26, *)
struct GlassCard: View {
    var body: some View {
        VStack {
            // content
        }
        .padding()
        .glassEffect(.regular)
    }
}
```

## Backward Compatibility Pattern

Always provide fallback for iOS 18:

```swift
struct AdaptiveCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 26, *) {
            content
                .padding()
                .glassEffect(.regular)
        } else {
            content
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
```

## SimpleNavi Specific Guidelines

### Compass View
- Use glass effect for the compass background on iOS 26
- Fallback to `.ultraThinMaterial` on iOS 18
- Ensure compass arrow remains clearly visible against glass

### Setup View
- Convert card backgrounds to glass surfaces on iOS 26
- Maintain readability of form fields over glass
- Use `.regular` tint for interactive elements

### Donation View
- Glass cards for donation tier options
- Subtle tinting to differentiate tiers

### Widget
- Widgets automatically get glass treatment on iOS 26
- Ensure widget content has sufficient contrast

## Color and Contrast Rules

1. **Text over glass**: Use `.primary` and `.secondary` — they auto-adapt
2. **Icons over glass**: Use SF Symbols with `.rendering(.hierarchical)`
3. **Never use opaque backgrounds** on elements placed over glass
4. **Avoid hard shadows** — glass surfaces use system-provided depth

## Migration Checklist

When updating a view for Liquid Glass:

- [ ] Add `#available(iOS 26, *)` check
- [ ] Replace `.background(.ultraThinMaterial)` with `.glassEffect(.regular)`
- [ ] Remove manual `cornerRadius` (glass handles its own shape)
- [ ] Remove manual shadows (glass provides depth)
- [ ] Test text contrast on both light and dark backgrounds
- [ ] Test on iOS 18 simulator to verify fallback
- [ ] Verify Dynamic Type accessibility at all sizes

## Anti-patterns

- **Don't** stack multiple glass layers (causes visual muddle)
- **Don't** apply glass to small elements like buttons (use tinted glass sparingly)
- **Don't** combine glass with heavy gradients or patterns
- **Don't** use glass on elements that need solid backgrounds for readability
- **Don't** add borders or strokes to glass surfaces
