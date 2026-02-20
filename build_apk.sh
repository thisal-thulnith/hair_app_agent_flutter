#!/bin/bash

# Quick script to build and install Android APK
# Usage: ./build_apk.sh [debug|release]

BUILD_MODE=${1:-release}

echo "🚀 Building Android APK ($BUILD_MODE mode)..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building APK..."
if [ "$BUILD_MODE" = "debug" ]; then
    flutter build apk --debug
else
    flutter build apk --release
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📱 APK location:"
    if [ "$BUILD_MODE" = "debug" ]; then
        echo "   build/app/outputs/flutter-apk/app-debug.apk"
    else
        echo "   build/app/outputs/flutter-apk/app-release.apk"
    fi
    echo ""

    # Ask to install
    read -p "📲 Install on connected device? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📲 Installing..."
        flutter install
        echo ""
        echo "✅ Installation complete!"
    fi
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
