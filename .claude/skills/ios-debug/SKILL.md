---
name: ios-debug
description: Debug iOS issues in SimpleNavi using Xcode tools, simulators, and instruments. Use when diagnosing crashes, memory leaks, performance issues, location simulation, or runtime errors.
disable-model-invocation: true
argument-hint: "[crash-log or issue description]"
allowed-tools: Bash(xcodebuild *), Bash(xcrun *), Bash(simctl *), Bash(log *), Bash(instruments *), Bash(leaks *), Bash(heap *), Read, Grep, Glob
---

# iOS Debugging — SimpleNavi

Debug runtime issues, crashes, and performance problems in SimpleNavi.

## Step 1: Identify the Problem Type

Based on `$ARGUMENTS`, determine the issue category:

### A. Crash / Runtime Error
1. Parse the crash log for the crashing thread and stack trace
2. Look for common patterns:
   - `EXC_BAD_ACCESS` → memory corruption, dangling pointer
   - `EXC_BREAKPOINT` → force unwrap nil, failed assertion
   - `SIGABRT` → uncaught exception, constraint failure
3. Find the relevant source file and line
4. Read surrounding code for context

### B. Memory Leak
1. Build for profiling:
```bash
xcodebuild \
  -project SimpleNavi.xcodeproj \
  -scheme SimpleNavi \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug \
  build 2>&1
```

2. Check for common leak patterns in code:
   - Strong reference cycles in closures (missing `[weak self]`)
   - `@State` used for ViewModels instead of `@StateObject`
   - Timer not invalidated
   - NotificationCenter observers not removed
   - Delegate properties not marked `weak`

3. Search for patterns:
```
Grep for: self\. in closures without [weak self]
Grep for: @State private var.*ViewModel
Grep for: Timer.scheduledTimer without invalidate
```

### C. Location / Compass Issues
1. Check `LocationManager.swift` for:
   - Authorization status handling
   - Heading filter configuration
   - Accuracy settings
2. Verify angle calculations in `CompassViewModel.swift`
3. Test with simulated locations:
```bash
# Set simulator location
xcrun simctl location booted set 35.6762 139.6503  # Tokyo
```

### D. Widget Issues
1. Check `SharedDataStore.swift` for App Group data flow
2. Verify widget timeline provider logic
3. Check for widget update throttling issues
4. Build and test widget:
```bash
xcodebuild \
  -project SimpleNavi.xcodeproj \
  -scheme SimpleNaviWidgetsExtension \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build 2>&1
```

### E. UI / SwiftUI Issues
1. Check for excessive view re-renders:
   - Look for `@Published` properties that change too frequently
   - Check if `Equatable` conformance is missing on state types
2. Check for animation issues:
   - Missing `withAnimation` blocks
   - Animation conflicts between multiple state changes

## Step 2: Simulator Commands

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
xcrun simctl boot "iPhone 16 Pro"

# Install app on simulator
xcrun simctl install booted path/to/SimpleNavi.app

# Open URL in simulator
xcrun simctl openurl booted "simplenavi://destination?lat=35.6762&lon=139.6503"

# Simulate location
xcrun simctl location booted set 35.1815 136.9066  # Nagoya

# Get app container path
xcrun simctl get_app_container booted com.simplenavi.simplenavi data

# Clear app data
xcrun simctl privacy booted reset all com.simplenavi.simplenavi

# Capture screenshot
xcrun simctl io booted screenshot ~/Desktop/debug_screenshot.png

# Stream device logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.simplenavi.simplenavi"' --level debug
```

## Step 3: Console Log Analysis

```bash
# Filter logs for SimpleNavi
log show --predicate 'processImagePath CONTAINS "SimpleNavi"' --last 5m

# Filter for specific subsystem
log show --predicate 'subsystem == "com.simplenavi.simplenavi"' --last 5m --style compact
```

## Step 4: Report

Provide:
1. Root cause identified
2. Affected file(s) and line number(s)
3. Fix applied or recommended
4. Steps to verify the fix
