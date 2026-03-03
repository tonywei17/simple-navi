---
name: swift-review
description: Review Swift/iOS code in SimpleNavi for bugs, security issues, performance problems, and best practices violations
disable-model-invocation: true
argument-hint: "[file-or-directory]"
context: fork
agent: general-purpose
---

# Swift Code Review — SimpleNavi

Review the Swift/iOS code at `$ARGUMENTS` (or the entire `SimpleNavi/` directory if no argument given) for the following categories:

## 1. Logic Bugs
- Unreachable code (e.g., code after infinite `for await` loops)
- Race conditions in async/concurrent code
- Missing `@MainActor` on UI-mutating code
- Incorrect `Task` lifecycle (detached tasks not cancelled)
- Force unwraps that could crash
- Angle wrapping / bearing calculation errors
- Index out of bounds (0-based vs 1-based confusion)

## 2. Security Issues
- API keys or secrets in client-side code
- Sensitive data (addresses, coordinates) stored in UserDefaults instead of SecureStorage
- Missing input validation on geocoding responses
- Keychain accessibility level too permissive

## 3. Performance Issues
- Excessive view re-renders from state changes
- Missing coalescing/throttling on high-frequency updates (heading, location)
- Heavy computation in View `body` or `init`
- Widget update frequency too high (throttle to >= 2s intervals)
- Unnecessary geocoding API calls

## 4. SwiftUI Anti-patterns
- `@State` used for ViewModel instead of proper ownership pattern
- Business logic in View body
- Heavy computation in View init
- Deprecated API usage (check iOS 18/26 deprecations)
- Memory leaks from strong reference cycles in closures
- Missing `@MainActor` on Observable classes

## 5. Concurrency Issues
- `DispatchQueue.main.sync` from background thread (deadlock risk)
- Actor isolation violations
- Data races on shared mutable state
- Missing cancellation handling in async tasks

## 6. iOS 18/26 Compatibility
- Features used without `#available` checks
- Deprecated APIs that have iOS 26 replacements
- Liquid Glass readiness of custom UI components

## Output Format

For each issue found, report:
```
[SEVERITY] file.swift:LINE - Description
  Suggestion: How to fix it
```

Severity levels: CRITICAL (crash/security), WARNING (bug/anti-pattern), INFO (improvement)

Summarize findings at the end with counts per severity.
