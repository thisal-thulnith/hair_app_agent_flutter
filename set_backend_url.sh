#!/bin/bash

# Quick script to update backend URL for Android APK
# Usage: ./set_backend_url.sh https://your-ngrok-url.ngrok.io

if [ -z "$1" ]; then
    echo "❌ Error: No URL provided"
    echo ""
    echo "Usage: ./set_backend_url.sh <backend-url>"
    echo ""
    echo "Examples:"
    echo "  ./set_backend_url.sh https://abc123.ngrok.io"
    echo "  ./set_backend_url.sh https://api.yourapp.com"
    echo "  ./set_backend_url.sh null  # Reset to local backend"
    echo ""
    exit 1
fi

BACKEND_URL=$1
ENV_FILE="lib/config/environment.dart"

# Backup original file
cp "$ENV_FILE" "$ENV_FILE.backup"

if [ "$BACKEND_URL" = "null" ]; then
    # Reset to null (local backend)
    sed -i '' 's|static const String? remoteBackendUrl = .*|static const String? remoteBackendUrl = null; // SET YOUR NGROK URL HERE|' "$ENV_FILE"
    echo "✅ Backend URL reset to local development"
else
    # Set to provided URL
    sed -i '' "s|static const String? remoteBackendUrl = .*|static const String? remoteBackendUrl = '$BACKEND_URL';|" "$ENV_FILE"
    echo "✅ Backend URL set to: $BACKEND_URL"
fi

echo ""
echo "📝 Updated file: $ENV_FILE"
echo "💾 Backup saved: $ENV_FILE.backup"
echo ""
echo "Next steps:"
echo "  1. flutter clean"
echo "  2. flutter pub get"
echo "  3. flutter build apk --release"
echo "  4. flutter install"
echo ""
echo "Or run: ./build_apk.sh"
