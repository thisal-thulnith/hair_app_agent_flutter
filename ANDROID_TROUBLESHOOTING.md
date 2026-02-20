# 🔧 Android APK Troubleshooting Guide

## 🚨 Common Issues & Solutions

### **Issue 1: Cannot Login on Android**

#### **Symptom:**
- Login button doesn't work
- "Network error" message
- Login screen freezes
- No response after entering credentials

#### **Solutions:**

**A. Check Backend URL Configuration**

1. **Verify backend URL is set:**
   ```bash
   # Open environment.dart
   cat lib/config/environment.dart | grep remoteBackendUrl
   ```

   Should show:
   ```dart
   static const String? remoteBackendUrl = 'https://your-ngrok-url.ngrok.io';
   ```

   ❌ **NOT:**
   ```dart
   static const String? remoteBackendUrl = null;
   ```

2. **Quick fix with script:**
   ```bash
   ./set_backend_url.sh https://your-ngrok-url.ngrok.io
   ./build_apk.sh
   ```

**B. Test Backend Connection**

1. **Open phone browser**
2. **Navigate to:** `https://your-ngrok-url.ngrok.io/health`
3. **Should see:** `{"status":"ok"}`

   ✅ If you see this → Backend is accessible
   ❌ If not → Backend issue (see below)

**C. Backend Not Accessible**

If browser can't reach backend:

1. **Check ngrok is running:**
   ```bash
   # Should show active tunnel
   curl http://127.0.0.1:4040/api/tunnels
   ```

2. **Restart ngrok:**
   ```bash
   ngrok http 8000
   ```

3. **Update URL and rebuild:**
   ```bash
   ./set_backend_url.sh https://NEW-URL.ngrok.io
   ./build_apk.sh
   ```

**D. Firebase Auth Issue**

1. **Check Firebase Console:**
   - Go to: https://console.firebase.google.com
   - Select your project: `salonbuff-435b2`
   - Authentication → Sign-in method
   - Verify Email/Password is **Enabled**

2. **Check google-services.json:**
   ```bash
   # Should match your Firebase project
   cat android/app/google-services.json | grep project_id
   ```

**E. Network Security Issue**

If backend is accessible in browser but not in app:

1. **Check network_security_config.xml has HTTPS support**
2. **Rebuild APK after any changes**

---

### **Issue 2: Image Errors (Error 6 or Failed to Load)**

#### **Symptom:**
- Images show "Failed to load image"
- Image upload fails
- "Error 6" or similar error codes

#### **Solutions:**

**A. Images Should Use Base64**

✅ **Good news:** App is configured to use base64 for images (works offline)

If images still fail:

1. **Check image size:**
   - Max size: 800 KB
   - Larger images won't be saved as base64

2. **Try smaller image:**
   - Take photo with lower resolution
   - Or compress image before uploading

**B. Firebase Storage Issue**

If base64 fails, app tries Firebase Storage. Check:

1. **Firebase Storage is enabled:**
   - Firebase Console → Storage
   - Should see storage bucket

2. **Storage rules allow writes:**
   ```javascript
   // Should allow authenticated writes
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

**C. Permissions Issue**

1. **Check app has permissions:**
   - Android Settings → Apps → Salon Buff → Permissions
   - Camera: Allowed
   - Files and media: Allowed

2. **Grant permissions manually if denied**

3. **Reinstall app:**
   ```bash
   # Uninstall first
   adb uninstall com.beautyai.app
   # Then install fresh
   flutter install
   ```

---

### **Issue 3: "Network Error" or "Cannot Connect"**

#### **Quick Checks:**

1. **Phone has internet connection**
   - Try opening any website in browser
   - Check WiFi/data is enabled

2. **Backend URL is correct**
   ```bash
   cat lib/config/environment.dart | grep remoteBackendUrl
   ```

3. **Ngrok tunnel is active**
   ```bash
   # Check ngrok status
   curl http://127.0.0.1:4040/api/tunnels
   ```

4. **Backend server is running**
   ```bash
   # Check backend is running
   curl https://your-ngrok-url.ngrok.io/health
   ```

---

### **Issue 4: App Crashes on Startup**

#### **Solutions:**

1. **Check logs:**
   ```bash
   # Connect device and check logs
   adb logcat | grep flutter
   ```

2. **Clear app data:**
   - Android Settings → Apps → Salon Buff → Storage
   - Clear Storage
   - Clear Cache

3. **Reinstall:**
   ```bash
   adb uninstall com.beautyai.app
   flutter install
   ```

---

### **Issue 5: Google Sign-In Doesn't Work**

#### **Solutions:**

**A. SHA-1 Certificate**

Android requires SHA-1 for Google Sign-In:

1. **Get SHA-1 fingerprint:**
   ```bash
   cd android
   ./gradlew signingReport
   ```

2. **Copy the SHA-1** from debug keystore

3. **Add to Firebase Console:**
   - Firebase Console → Project Settings
   - Your apps → Android app
   - Add fingerprint → Paste SHA-1
   - Save

4. **Download new google-services.json:**
   - Download from Firebase Console
   - Replace `android/app/google-services.json`

5. **Rebuild APK:**
   ```bash
   ./build_apk.sh
   ```

**B. Use Email/Password Instead**

If Google Sign-In is too complex, use email/password:
- Simpler setup
- Works immediately
- No SHA-1 required

---

## 🛠️ Debug Tools

### **View Backend URL in App**

Add this to check which URL app is using:

```dart
// Temporary debug code
print('Backend URL: ${Environment.aiBackendUrl}');
```

### **Test API from Command Line**

```bash
# Test backend health
curl https://your-ngrok-url.ngrok.io/health

# Test chat endpoint (requires auth)
curl -X POST https://your-ngrok-url.ngrok.io/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test","session_id":"test123"}'
```

### **View App Logs**

```bash
# Real-time logs
adb logcat | grep -E "flutter|FirebaseAuth|Dio"

# Clear and view fresh logs
adb logcat -c && adb logcat | grep flutter
```

---

## ✅ Pre-Flight Checklist

Before building APK:

- [ ] ngrok is running
- [ ] Backend server is running
- [ ] Backend URL is set in `environment.dart`
- [ ] Backend health endpoint responds
- [ ] Firebase Email/Password auth is enabled
- [ ] google-services.json is present
- [ ] Network security config allows HTTPS

---

## 🚀 Quick Commands

### **Set Backend URL:**
```bash
./set_backend_url.sh https://your-ngrok-url.ngrok.io
```

### **Build APK:**
```bash
./build_apk.sh
```

### **Full Rebuild:**
```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

### **Uninstall and Reinstall:**
```bash
adb uninstall com.beautyai.app
flutter install
```

### **Check Ngrok Status:**
```bash
curl http://127.0.0.1:4040/api/tunnels | jq
```

---

## 📞 Getting Help

If issues persist:

1. **Collect information:**
   - What error message shows?
   - Can browser access backend?
   - What does `adb logcat` show?
   - Did you rebuild APK after changes?

2. **Check these files:**
   - `lib/config/environment.dart` (backend URL)
   - `android/app/google-services.json` (Firebase config)
   - `android/app/src/main/AndroidManifest.xml` (permissions)

3. **Try clean rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

---

## 🔥 Nuclear Option (Last Resort)

If nothing works:

```bash
# 1. Completely clean project
flutter clean
rm -rf build/
rm -rf .dart_tool/

# 2. Verify backend URL
./set_backend_url.sh https://your-current-ngrok-url.ngrok.io

# 3. Get fresh dependencies
flutter pub get

# 4. Uninstall old app
adb uninstall com.beautyai.app

# 5. Build and install fresh
flutter build apk --release
flutter install

# 6. Check logs
adb logcat -c
adb logcat | grep flutter
```

---

**Most issues are solved by:**
1. ✅ Setting correct backend URL
2. ✅ Rebuilding APK
3. ✅ Reinstalling app
