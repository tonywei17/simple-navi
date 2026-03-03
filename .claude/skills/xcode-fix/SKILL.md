---
name: xcode-fix
description: Diagnose and fix Xcode build errors for SimpleNavi project from xcodebuild output
disable-model-invocation: true
argument-hint: "[paste error or leave blank to build first]"
allowed-tools: Bash(xcodebuild *), Read, Edit, Glob, Grep
---

# Fix Xcode Build Errors — SimpleNavi

Diagnose and fix compilation errors in the SimpleNavi iOS project.

## Steps

1. **If no error provided in $ARGUMENTS**, run a build first to capture errors:

```bash
xcodebuild \
  -project SimpleNavi.xcodeproj \
  -scheme SimpleNavi \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -quiet \
  build 2>&1 | tail -100
```

2. **Parse each error** — extract:
   - File path and line number
   - Error type (type mismatch, missing import, undeclared identifier, etc.)
   - The relevant code context

3. **Read the failing file(s)** to understand the full context around each error.

4. **Apply fixes** following these common patterns:

| Error Pattern | Common Fix |
|--------------|-----------|
| `Cannot find 'X' in scope` | Add missing import or check spelling |
| `Type 'X' has no member 'Y'` | Check API changes between iOS 18/26 |
| `Cannot convert value of type` | Add explicit type conversion or fix the type |
| `'X' is only available in iOS 26 or newer` | Add `if #available(iOS 26, *)` check |
| `'X' is deprecated` | Replace with the suggested iOS 26 alternative |
| `Ambiguous use of 'X'` | Add explicit type annotation to disambiguate |
| `Missing return` | Add return statement or fix control flow |

5. **Also build the widget extension** if the error might affect it:

```bash
xcodebuild \
  -project SimpleNavi.xcodeproj \
  -scheme SimpleNaviWidgetsExtension \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -quiet \
  build 2>&1 | tail -50
```

6. **Rebuild** after applying fixes to verify they work.

7. **Report** what was fixed and if any issues remain.

## Important

- Never suppress warnings with `@available` unless the deprecated API has no replacement for iOS 18
- When fixing type errors, prefer changing the code to match expected types rather than force-casting
- If a fix requires adding a new dependency, ask the user first
- Check both main target and widget extension target
