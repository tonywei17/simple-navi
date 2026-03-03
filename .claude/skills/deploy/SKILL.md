---
name: deploy
description: Archive and prepare SimpleNavi for App Store or TestFlight deployment. Use when the user wants to archive, export, upload to App Store Connect, or manage provisioning.
disable-model-invocation: true
argument-hint: "[testflight | appstore]"
allowed-tools: Bash(xcodebuild *), Bash(xcrun *), Bash(altool *), Read, Edit
---

# Deploy SimpleNavi

Archive and deploy SimpleNavi to TestFlight or App Store.

## Prerequisites Check

1. Verify signing identity:
```bash
security find-identity -v -p codesigning
```

2. Check current version:
```bash
grep -A1 'MARKETING_VERSION' SimpleNavi.xcodeproj/project.pbxproj | head -4
grep -A1 'CURRENT_PROJECT_VERSION' SimpleNavi.xcodeproj/project.pbxproj | head -4
```

## Step 1: Bump Version (if needed)

Ask the user if they want to bump the version before deploying.

Current: `MARKETING_VERSION = 1.3.0`, `CURRENT_PROJECT_VERSION = 11`

## Step 2: Archive

```bash
xcodebuild \
  -project SimpleNavi.xcodeproj \
  -scheme SimpleNavi \
  -sdk iphoneos \
  -configuration Release \
  -archivePath build/SimpleNavi.xcarchive \
  archive 2>&1
```

## Step 3: Export

### For TestFlight (`$ARGUMENTS` contains "testflight" or default):

Create export options plist:
```bash
cat > build/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>K2ZG73WM9X</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
EOF
```

```bash
xcodebuild -exportArchive \
  -archivePath build/SimpleNavi.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/export \
  2>&1
```

### For App Store (`$ARGUMENTS` contains "appstore"):

Same as TestFlight export but remind the user to:
1. Set release notes in App Store Connect
2. Submit for review after upload
3. Check screenshot requirements

## Step 4: Upload to App Store Connect

```bash
xcrun altool --upload-app \
  -f build/export/SimpleNavi.ipa \
  -t ios \
  --apiKey <API_KEY> \
  --apiIssuer <ISSUER_ID> \
  2>&1
```

Note: Ask the user for API Key and Issuer ID if not already configured.

Alternative using `xcrun notarytool` or Xcode Organizer may be preferred.

## Step 5: Post-Deploy

1. Verify upload in App Store Connect
2. Tag the release in git:
```bash
git tag -a v1.3.0 -m "Release 1.3.0"
```

3. Report deployment status

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Code signing error | Check provisioning profile in Xcode, run `security find-identity` |
| Bitcode error | Set `ENABLE_BITCODE = NO` in build settings |
| Missing entitlements | Check `.entitlements` file matches App ID capabilities |
| Upload timeout | Retry, check network connection |
| Version conflict | Bump `CURRENT_PROJECT_VERSION` (build number) |
