#!/bin/bash
set -e

echo "🚀 Aether .DMG Dağıtım Paketi Hazırlanıyor..."

# 1. Önce en güncel .app paketini derle ve imzala
./bundle_app.sh

APP_NAME="Aether"
APP_BUNDLE="${APP_NAME}.app"
DMG_TEMP_DIR="./dmg_staging"
DMG_OUTPUT="${APP_NAME}.dmg"

# 2. Hazırlık dizinini temizle ve oluştur
rm -rf "$DMG_TEMP_DIR" "$DMG_OUTPUT"
mkdir -p "$DMG_TEMP_DIR"

# 3. .app paketini kopyala ve /Applications kısayolunu ekle
echo "📦 .app paketi ve /Applications kısayolu hazırlanıyor..."
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# 4. DMG Oluştur
echo "💿 Apple Disk Image (.dmg) sıkıştırılarak oluşturuluyor..."
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "$DMG_TEMP_DIR" \
               -ov -format UDZO \
               "$DMG_OUTPUT"

# 5. Temizlik
rm -rf "$DMG_TEMP_DIR"

# 6. DMG dosyasını da Apple Geliştirici Sertifikası ile imzala
if security find-identity -v -p codesigning | grep -q "Apple Development"; then
    DEV_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development" | head -n 1 | awk -F'"' '{print $2}')
    echo "🔏 .dmg dosyası imzalanıyor: $DEV_IDENTITY..."
    codesign --force --sign "$DEV_IDENTITY" "$DMG_OUTPUT"
fi

echo "=================================================="
echo "🎉 TEBRİKLER! ${DMG_OUTPUT} BAŞARIYLA OLUŞTURULDU!"
echo "📁 Konum: $(pwd)/${DMG_OUTPUT}"
echo "📊 Boyut: $(du -sh ${DMG_OUTPUT} | cut -f1)"
echo "🌐 Bu dosyayı doğrudan GitHub Releases / Tags sayfasına yükleyebilirsiniz."
echo "=================================================="
