#!/bin/bash

# Script to get SHA256 fingerprint for Android App Links
# Usage: ./get_sha256_fingerprint.sh [keystore_path] [alias] [password]

if [ -z "$1" ]; then
    # Default to debug keystore
    KEYSTORE="$HOME/.android/debug.keystore"
    ALIAS="androiddebugkey"
    PASSWORD="android"
    echo "Using debug keystore..."
else
    KEYSTORE="$1"
    ALIAS="${2:-your-alias}"
    PASSWORD="${3:-your-password}"
fi

if [ ! -f "$KEYSTORE" ]; then
    echo "Error: Keystore file not found at $KEYSTORE"
    exit 1
fi

echo "Extracting SHA256 fingerprint from: $KEYSTORE"
echo "Alias: $ALIAS"
echo ""

keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$PASSWORD" | grep -A 1 "SHA256:" | head -2

echo ""
echo "Copy the SHA256 fingerprint (without colons) to assetlinks.json"

