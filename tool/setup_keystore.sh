#!/usr/bin/env bash
# Release keystore üretir ve android/key.properties dosyasını yazar.
#
# Keystore repo dışında tutulur: ~/.aquamate_keys/aquamate-upload.jks
# Parolayı kendin belirle; KAYBETME, aksi halde Play/APK güncellemesi yapamazsın.
set -euo pipefail

cd "$(dirname "$0")/.."

KEY_DIR="$HOME/.aquamate_keys"
KEY_STORE="$KEY_DIR/aquamate-upload.jks"
ALIAS="aquamate"

mkdir -p "$KEY_DIR"

if [[ -f "$KEY_STORE" ]]; then
  echo "Keystore zaten var: $KEY_STORE"
else
  read -r -s -p "Keystore parolası (en az 6 karakter): " STORE_PASS; echo
  read -r -s -p "Parolayı tekrar gir: " STORE_PASS_2; echo
  if [[ "$STORE_PASS" != "$STORE_PASS_2" ]]; then
    echo "Parolalar eşleşmiyor." >&2
    exit 1
  fi

  keytool -genkeypair -v \
    -keystore "$KEY_STORE" \
    -storetype JKS \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$ALIAS" \
    -storepass "$STORE_PASS" -keypass "$STORE_PASS" \
    -dname "CN=AquaMate, OU=Mobile, O=AquaMate, L=Istanbul, C=TR"
fi

read -r -s -p "Keystore parolası (key.properties için): " STORE_PASS; echo

cat > android/key.properties <<EOF
storePassword=$STORE_PASS
keyPassword=$STORE_PASS
keyAlias=$ALIAS
storeFile=$KEY_STORE
EOF

echo "Yazıldı: android/key.properties (git tarafından yok sayılır)"
echo "Keystore: $KEY_STORE"
