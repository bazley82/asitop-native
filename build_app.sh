#!/bin/bash

# Configuration
APP_NAME="ASITOP"
BUNDLE_ID="com.bazley82.asitop-native"
SRC_DIR="./Sources/asitop_native"
BUILD_DIR="./build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/PlugIns"

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

echo "🔨 Compiling main app..."
swiftc -O \
    -parse-as-library \
    -target arm64-apple-macosx26.0 \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    "$SRC_DIR"/asitop_nativeApp.swift \
    "$SRC_DIR"/DashboardView.swift \
    "$SRC_DIR"/DataCollector.swift \
    "$SRC_DIR"/MetricsModel.swift \
    "$SRC_DIR"/SettingsView.swift

echo "🔨 Compiling Control Center extension..."
EXT_NAME="ControlWidget"
EXT_BUNDLE="$APP_BUNDLE/Contents/PlugIns/$EXT_NAME.appex"
mkdir -p "$EXT_BUNDLE/Contents/MacOS"

swiftc -O \
    -parse-as-library \
    -target arm64-apple-macosx26.0 \
    -o "$EXT_BUNDLE/Contents/MacOS/$EXT_NAME" \
    -framework WidgetKit -framework AppIntents -framework SwiftUI \
    "$SRC_DIR"/ControlWidget.swift

cp Control-Info.plist "$EXT_BUNDLE/Contents/Info.plist"

# Create Info.plist for main app FIRST
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
    <string>1.2.2</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.3</string>
</dict>
</plist>
EOF

echo "🔐 Codesigning extension and app..."
codesign --force --entitlements Entitlements.plist --sign - "$EXT_BUNDLE"
codesign --force --entitlements Entitlements.plist --sign - "$APP_BUNDLE"

echo "✅ App bundle created at $APP_BUNDLE"

# Deploy to /Applications (required for reliable extension discovery)
echo "📂 Deploying to /Applications..."
rm -rf /Applications/ASITOP.app
cp -r "$APP_BUNDLE" /Applications/ASITOP.app

# Register the plugin with the system
echo "🔗 Registering with system services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/ASITOP.app
pluginkit -a /Applications/ASITOP.app/Contents/PlugIns/ControlWidget.appex

echo "🚀 Done! Please open ASITOP from your Applications folder, then check Control Center."
