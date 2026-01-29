#!/bin/bash

# Configuration
APP_NAME="ASITOP"
BUNDLE_ID="com.barriesanders.asitop-native"
SRC_DIR="./Sources/asitop_native"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "🎨 Creating icon asset..."
# Create iconset
mkdir -p "$BUILD_DIR/asitop.iconset"
sips -s format png -z 128 128 Resources/icon.png --out "$BUILD_DIR/asitop.iconset/icon_128x128.png"
sips -s format png -z 256 256 Resources/icon.png --out "$BUILD_DIR/asitop.iconset/icon_128x128@2x.png"
sips -s format png -z 256 256 Resources/icon.png --out "$BUILD_DIR/asitop.iconset/icon_256x256.png"
sips -s format png -z 512 512 Resources/icon.png --out "$BUILD_DIR/asitop.iconset/icon_256x256@2x.png"
sips -s format png -z 512 512 Resources/icon.png --out "$BUILD_DIR/asitop.iconset/icon_512x512.png"
sips -s format png -z 1024 1024 Resources/icon.png --out "$BUILD_DIR/asitop.iconset/icon_512x512@2x.png"
iconutil -c icns "$BUILD_DIR/asitop.iconset" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "🔨 Compiling Swift sources..."
# Compile all swift files in the directory
swiftc -O \
    -parse-as-library \
    -target arm64-apple-macosx13.0 \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "$SRC_DIR"/*.swift

# Create Info.plist
cat <<EOF > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ App bundle created at $APP_BUNDLE"

# Final step: move to /Applications (Optional, but good for user)
# We'll just point them to the build folder for now to avoid sudo issues during build
echo "🚀 To run: open $APP_BUNDLE"
