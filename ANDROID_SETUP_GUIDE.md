# Android APK Setup & Validation Guide

## ✅ Configuration Status

### **1. Permissions - CONFIGURED ✓**
All required Android permissions are now properly configured:

- ✅ `INTERNET` - For API calls and Firebase
- ✅ `CAMERA` - For taking photos
- ✅ `READ_MEDIA_IMAGES` - For image picker (Android 13+)
- ✅ `READ_EXTERNAL_STORAGE` - For image picker (Android 12 and below)
- ✅ `WRITE_EXTERNAL_STORAGE` - For older Android versions

**Location:** `android/app/src/main/AndroidManifest.xml`

### **2. Network Security - CONFIGURED ✓**
HTTP traffic is allowed for development backend:

- ✅ `localhost` - For emulator
- ✅ `10.0.2.2` - For emulator to access host machine
- ✅ `192.168.x.x` - For physical devices on local network

**Location:** `android/app/src/main/res/xml/network_security_config.xml`

### **3. Firebase - CONFIGURED ✓**
Firebase is properly set up for Android:

- ✅ `google-services.json` present
- ✅ Google Services plugin configured
- ✅ Package name: `com.beautyai.app`
- ✅ Project: `salonbuff-435b2`

**Location:** `android/app/google-services.json`

### **4. Build Configuration - CONFIGURED ✓**
- ✅ Min SDK: Uses Flutter default (typically API 21)
- ✅ Target SDK: Uses Flutter default
- ✅ Java 17 compatibility
- ✅ Kotlin support

**Location:** `android/app/build.gradle.kts`

---

## 📱 Building APK

### **Debug APK (For Testing)**
```bash
cd /Users/thisalthulnith/.gemini/antigravity/scratch/salon-buff/flutter_app

# Build debug APK
flutter build apk --debug

# APK location:
# build/app/outputs/flutter-apk/app-debug.apk
```

### **Release APK (For Distribution)**
```bash
# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### **Split APKs by Architecture (Smaller Size)**
```bash
# Build separate APKs for different CPU architectures
flutter build apk --split-per-abi

# This creates 3 APKs:
# - app-armeabi-v7a-release.apk (32-bit ARM)
# - app-arm64-v8a-release.apk (64-bit ARM) - Most common
# - app-x86_64-release.apk (64-bit x86)
```

---

## 🔧 Testing on Physical Android Device

### **Step 1: Find Your Computer's Local IP**

**On macOS/Linux:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**On Windows:**
```cmd
ipconfig
```

Look for your local IP address (usually starts with `192.168.x.x` or `10.x.x.x`)

### **Step 2: Update Environment Configuration**

Edit: `lib/config/environment.dart`

```dart
// Set your computer's local IP here
static const String? localNetworkIP = '192.168.1.100'; // Replace with your IP
```

### **Step 3: Ensure Backend is Accessible**

Make sure your backend server is running and listening on `0.0.0.0` (not just `localhost`):

```bash
cd /Users/thisalthulnith/beuty/beauty_ai

# Check if backend is running on all interfaces
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### **Step 4: Install and Test**

```bash
# Connect device via USB with USB debugging enabled
flutter devices

# Install on device
flutter install

# Or run directly
flutter run --release
```

---

## ✅ Validation Checklist

### **Before Building APK:**

- [ ] Backend server is running and accessible
- [ ] Firebase project is configured correctly
- [ ] Google Sign-In is enabled in Firebase Console
- [ ] Email/Password auth is enabled in Firebase Console

### **Testing Login Functionality:**

- [ ] Email/Password login works
- [ ] Google Sign-In works
- [ ] User can register new account
- [ ] Remember me / auto-login works
- [ ] Logout works correctly

### **Testing Chat Functionality:**

- [ ] Can send text messages
- [ ] Can upload images from gallery
- [ ] Can take photos with camera
- [ ] Images display correctly in chat
- [ ] AI responses appear correctly
- [ ] Typing animation works
- [ ] "Agent thinking" animation shows
- [ ] Stop button works during generation
- [ ] Messages are saved to Firebase
- [ ] Chat history loads correctly

### **Testing UI/UX:**

- [ ] Sidebar opens/closes correctly
- [ ] New chat button works
- [ ] Conversation switching works
- [ ] All text is readable (not too small/large)
- [ ] No UI overflow errors
- [ ] App works in portrait mode
- [ ] App works in landscape mode
- [ ] Keyboard doesn't cover input field

### **Testing Permissions:**

- [ ] Camera permission is requested when needed
- [ ] Gallery permission is requested when needed
- [ ] Internet connection works
- [ ] App handles permission denial gracefully

---

## 🐛 Common Issues & Solutions

### **Issue: "Failed to load image"**
**Solution:** Images are now stored as base64 in Firebase, so they should work offline. If URLs fail, base64 fallback will be used automatically.

### **Issue: "Cannot connect to backend"**
**Solutions:**
1. Check if backend is running on `0.0.0.0:8000`
2. Verify your local IP is correct in `environment.dart`
3. Make sure phone and computer are on the same WiFi network
4. Check firewall isn't blocking port 8000

### **Issue: "Google Sign-In not working"**
**Solutions:**
1. Verify SHA-1 certificate fingerprint is added to Firebase Console
2. Get debug SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
3. Add the SHA-1 to Firebase Console → Project Settings → Your Android App

### **Issue: "Permission denied for camera/gallery"**
**Solutions:**
1. Go to Android Settings → Apps → Salon Buff → Permissions
2. Manually grant Camera and Files/Media permissions
3. Restart the app

### **Issue: APK install fails**
**Solutions:**
1. Uninstall any previous versions first
2. Enable "Install from Unknown Sources" in Android settings
3. Check if storage space is available
4. Try building with `--no-shrink` flag

---

## 📋 Important Notes

### **For Physical Device Testing:**

1. **Local IP Configuration:**
   - You MUST set `localNetworkIP` in `environment.dart` for physical devices
   - Use your computer's local network IP (192.168.x.x)

2. **Network Requirements:**
   - Both device and computer must be on the same WiFi network
   - Router must allow device-to-device communication (some public WiFi blocks this)

3. **Backend Server:**
   - Must run on `0.0.0.0` (not `localhost`)
   - Port 8000 must be accessible from the network
   - Firewall must allow incoming connections

### **For Release APK:**

1. **App Signing:**
   - Currently using debug signing (suitable for testing)
   - For production, create a keystore and configure proper signing
   - See: https://docs.flutter.dev/deployment/android#signing-the-app

2. **ProGuard/R8:**
   - Code obfuscation is enabled by default in release builds
   - If you encounter issues, add ProGuard rules

3. **Google Sign-In:**
   - Release builds need a different SHA-1 certificate
   - Add both debug and release SHA-1 to Firebase Console

---

## 🚀 Quick Start Commands

```bash
# Navigate to project
cd /Users/thisalthulnith/.gemini/antigravity/scratch/salon-buff/flutter_app

# Clean and get dependencies
flutter clean
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK (smaller, faster)
flutter build apk --release

# Build split APKs (even smaller)
flutter build apk --split-per-abi

# Install on connected device
flutter install

# Run on connected device
flutter run --release
```

---

## 📱 APK Distribution

After building the release APK, you can share it by:

1. **Direct Transfer:**
   - Copy `app-release.apk` to phone via USB
   - Open file on phone to install

2. **Google Drive/Dropbox:**
   - Upload APK to cloud storage
   - Share download link

3. **Testing Platforms:**
   - Firebase App Distribution
   - TestFlight (for iOS)

---

## 🔍 Testing Backend Connection

Test if backend is accessible from your phone:

1. Find your computer's IP (e.g., `192.168.1.100`)
2. Open phone browser
3. Navigate to: `http://192.168.1.100:8000/health`
4. Should see: `{"status":"ok"}`

If this doesn't work, check:
- Backend is running on `0.0.0.0:8000`
- Firewall allows port 8000
- Both devices on same network

---

## ✅ Final Validation

Before distributing the APK:

1. ✅ Test login with multiple accounts
2. ✅ Test all features (chat, images, AI responses)
3. ✅ Test on different Android versions if possible
4. ✅ Check app doesn't crash on various actions
5. ✅ Verify images load correctly
6. ✅ Test offline behavior (should show cached data)
7. ✅ Test with poor network connection
8. ✅ Verify logout and re-login works

**The app is now fully configured and ready for Android deployment! 🎉**
