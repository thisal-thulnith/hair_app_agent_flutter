#!/bin/bash

echo "🏗️  Building Buff Salon APK..."
echo ""

# Check if Android SDK is installed
if [ -z "$ANDROID_HOME" ]; then
    echo "❌ Android SDK not found!"
    echo ""
    echo "Please install Android Studio from:"
    echo "https://developer.android.com/studio"
    echo ""
    echo "Then add to your ~/.zshrc or ~/.bash_profile:"
    echo "export ANDROID_HOME=\$HOME/Library/Android/sdk"
    echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
    echo ""
    exit 1
fi

echo "✅ Android SDK found"
echo ""

# Clean and build
echo "🧹 Cleaning..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🚀 Building APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    echo "📱 APK: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
else
    echo "❌ Build failed! Check errors above."
fi
