#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "Building STAHP IT!..."
swift build -c release

APP_DIR="$DIR/build/STAHP IT!.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Ensure AppIcon.icns exists
if [ ! -f "$DIR/AppIcon.icns" ]; then
    echo "Warning: AppIcon.icns not found at $DIR/AppIcon.icns"
fi

# Copy icon to Resources
cp "$DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Copy binary
cp "$DIR/.build/release/StahpIt" "$MACOS_DIR/StahpIt"
chmod +x "$MACOS_DIR/StahpIt"

# Create Info.plist
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>StahpIt</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.stahpit.macos</string>
    <key>CFBundleName</key>
    <string>STAHP IT!</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF

echo "STAHP IT! bundle created at: $APP_DIR"
xattr -cr "$APP_DIR"
codesign --force --deep --sign - "$APP_DIR"

echo "Launching STAHP IT!..."
killall StahpIt 2>/dev/null || true
nohup "$MACOS_DIR/StahpIt" > /dev/null 2>&1 &
disown
echo "STAHP IT! launched successfully."
