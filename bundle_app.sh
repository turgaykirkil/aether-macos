#!/bin/bash
set -e

echo "🔨 1. Aether Release derlemesi yapılıyor..."
swift build -c release

APP_NAME="Aether"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 2. .app paketi oluşturuluyor ($BUNDLE_DIR)..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Binary kopyala
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# App Icon kopyala
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Info.plist oluştur
cat <<EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>app.aether.optimizer</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Aether</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Aether, silme işlemlerini ve Finder ile entegrasyonu güvenle yürütmek için Apple Events izinlerine ihtiyaç duyar.</string>
</dict>
</plist>
EOF

# Karantina özniteliklerini temizle
xattr -cr "$BUNDLE_DIR"

# Apple Geliştirici Sertifikası ile Kod İmzalama (Codesigning)
DEV_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" | head -n 1 | awk -F'"' '{print $2}')

if [ -n "$DEV_IDENTITY" ]; then
    echo "🔏 3. Apple Geliştirici Sertifikası ile İmzalanıyor: $DEV_IDENTITY..."
    codesign --force --deep --sign "$DEV_IDENTITY" --entitlements MacClean.entitlements --options runtime "$BUNDLE_DIR"
    echo "✅ Uygulama resmi Apple Geliştirici Sertifikanız ile başarıyla İMZALANDI ve DOĞRULANDI!"
else
    echo "⚠️ Apple Development sertifikası bulunamadı, Ad-Hoc imzalama yapılıyor..."
    codesign --force --deep --sign - --entitlements MacClean.entitlements "$BUNDLE_DIR"
fi

echo "🔍 4. İmza doğrulaması:"
codesign -vvv --deep --strict "$BUNDLE_DIR"

echo "🎉 $APP_NAME.app tamamen hazır, logolu ve doğrulanmış bir macOS uygulamasıdır!"
