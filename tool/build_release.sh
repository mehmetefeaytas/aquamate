#!/usr/bin/env bash
# AquaMate yayın derlemesi.
#
# Kullanım:
#   ./tool/build_release.sh apk        # imzalı release APK (split-per-abi)
#   ./tool/build_release.sh aab        # Play için AAB (gerekirse)
#   ./tool/build_release.sh ipa        # TestFlight için IPA
#   ./tool/build_release.sh all        # hepsi
#
# Ön koşullar:
#   * android/key.properties + keystore (yoksa debug anahtarıyla imzalanır)
#   * iOS için Apple Developer oturumu ve Xcode imza ayarları
set -euo pipefail

cd "$(dirname "$0")/.."

MODE="${1:-apk}"
DIST="dist"
mkdir -p "$DIST"

step() { printf '\n\033[1;34m▶ %s\033[0m\n' "$1"; }

preflight() {
  step "flutter pub get"
  flutter pub get >/dev/null

  step "flutter analyze"
  flutter analyze

  step "flutter test"
  flutter test

  if [[ ! -f android/key.properties ]]; then
    printf '\033[1;33m! android/key.properties bulunamadı — release APK debug anahtarıyla imzalanacak.\033[0m\n'
    printf '  Üretim için: tool/setup_keystore.sh çalıştır ve key.properties dosyasını doldur.\n'
  fi
}

build_apk() {
  step "Release APK (split-per-abi)"
  flutter build apk --release --split-per-abi \
    --obfuscate --split-debug-info="$DIST/symbols-android"
  rm -f "$DIST"/aquamate-*.apk
  cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
     "$DIST/aquamate-1.0.0-arm64-v8a.apk" 2>/dev/null || true
  cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
     "$DIST/aquamate-1.0.0-armeabi-v7a.apk" 2>/dev/null || true
  cp build/app/outputs/flutter-apk/app-x86_64-release.apk \
     "$DIST/aquamate-1.0.0-x86_64.apk" 2>/dev/null || true
  ls -lh "$DIST"/*.apk
}

build_aab() {
  step "Release AAB"
  flutter build appbundle --release --obfuscate \
    --split-debug-info="$DIST/symbols-android"
}

build_ipa() {
  step "Release IPA (TestFlight)"
  flutter build ipa --release --obfuscate \
    --split-debug-info="$DIST/symbols-ios" \
    --export-method app-store
  ls -lh build/ios/ipa || true
}

case "$MODE" in
  apk)
    preflight
    build_apk
    ;;
  aab)
    preflight
    build_aab
    ;;
  ipa)
    preflight
    build_ipa
    ;;
  all)
    preflight
    build_apk
    build_ipa
    ;;
  *)
    echo "Bilinmeyen mod: $MODE (apk|aab|ipa|all)" >&2
    exit 1
    ;;
esac

step "Bitti. Çıktılar: $DIST ve build/ios/ipa"
