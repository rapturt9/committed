#!/bin/bash
set -e

APP_NAME="Committed"
BUILD_DIR=".build/arm64-apple-macosx/debug"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."
swift build

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "Committed/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy .env to Resources if it exists
if [ -f ".env" ]; then
    cp ".env" "$APP_BUNDLE/Contents/Resources/.env"
fi

# Copy app icon
if [ -f "Committed/Resources/AppIcon.icns" ]; then
    cp "Committed/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Sign the app (ad-hoc)
codesign --force --sign - "$APP_BUNDLE"

echo ""
echo "Installing to /Applications..."
launchctl unload ~/Library/LaunchAgents/com.committed.app.plist 2>/dev/null || true
pkill -9 -f "Committed.app/Contents/MacOS" 2>/dev/null || true
sleep 2
rm -rf /Applications/Committed.app
cp -r "$APP_BUNDLE" /Applications/Committed.app
launchctl load ~/Library/LaunchAgents/com.committed.app.plist 2>/dev/null || true

echo "Build complete. App restarted via launchd."
