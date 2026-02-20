# 🔧 APK Crash Fix - App Won't Open

## ✅ I've Already Fixed The Main Issues!

### What I Fixed:

1. ✅ **Disabled code minification** (main cause of crashes)
2. ✅ **Added ProGuard rules** for Firebase/Google Sign-In
3. ✅ **Configured multiDex** for large app support
4. ✅ **Set proper minSdk to 24**
5. ✅ **Added error handling** in Firebase initialization

---

## 🚀 Rebuild APK (Required!)

After my fixes, you **MUST rebuild** the APK:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🐛 If Still Crashes After Rebuild

### Check 1: View Crash Logs

Connect your phone via USB and run:

```bash
# Clear old logs
adb logcat -c

# Install and run app
adb install build/app/outputs/flutter-apk/app-release.apk

# View crash logs
adb logcat | grep -i "flutter\|firebase\|crash\|error"
```

Look for error messages like:
- `FirebaseApp not initialized`
- `google-services.json missing`
- `SHA-1 certificate`
- `Package name mismatch`

---

### Fix 2: Ensure google-services.json Exists

**Check:**
```bash
ls -la android/app/google-services.json
```

**If missing:**
1. Go to Firebase Console
2. Project Settings → Your apps
3. Download `google-services.json`
4. Place at: `android/app/google-services.json`
5. Rebuild APK

---

### Fix 3: Verify Package Name Matches

**Check your google-services.json:**
```bash
cat android/app/google-services.json | grep package_name
```

Should show: `"package_name": "com.beautyai.app"`

**If different:**
- Either update `google-services.json` in Firebase Console
- Or change `applicationId` in `android/app/build.gradle.kts` to match

---

### Fix 4: Add SHA-1 to Firebase (For Google Sign-In)

**Get SHA-1:**
```bash
cd android
./gradlew signingReport
```

**Copy the SHA-1** (looks like: `A1:B2:C3:D4:...`)

**Add to Firebase:**
1. Firebase Console → Project Settings
2. Your apps → Android app
3. Add fingerprint → Paste SHA-1
4. Save
5. Download new `google-services.json`
6. Replace old one
7. Rebuild APK

---

### Fix 5: Build Debug APK for Better Error Messages

```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
adb logcat | grep -i flutter
```

Debug builds show better error messages!

---

### Fix 6: Test on Different Device

Some issues are device-specific:
- Try on emulator
- Try on different physical device
- Check Android version (needs Android 7.0+)

---

### Fix 7: Check Internet Permission

**Verify in `android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Should be there (I already added it).

---

### Fix 8: Firebase Rules

Make sure Firestore rules allow authenticated users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📱 Build Variants to Try

### 1. No-Minify Release (Recommended - Already Set)
```bash
flutter build apk --release
```
✅ Should work now with my fixes!

### 2. Debug Build (Best for testing)
```bash
flutter build apk --debug
```
✅ Larger file, but shows errors clearly

### 3. Profile Build
```bash
flutter build apk --profile
```
✅ Good middle ground

---

## 🎯 Common Crash Causes & Solutions

| Crash Type | Error in Logs | Solution |
|------------|---------------|----------|
| **Immediate crash** | `FirebaseApp not initialized` | Add google-services.json |
| **Crash on login** | `SHA-1` or `API key` | Add SHA-1 to Firebase |
| **Black screen** | `R8/ProGuard` | Disable minify (already done) |
| **Network error** | `Connection refused` | Check backend URL |
| **White screen** | `Missing dependencies` | Run flutter clean |

---

## ✅ Verification Checklist

Before installing APK, verify:

- [ ] `google-services.json` exists in `android/app/`
- [ ] SHA-1 added to Firebase Console
- [ ] Package name is `com.beautyai.app`
- [ ] Rebuilt APK after my fixes
- [ ] Using Android 7.0+ device
- [ ] Internet permission in manifest
- [ ] Firebase services enabled in console

---

## 🔍 Get Detailed Crash Info

### Method 1: ADB Logcat
```bash
adb logcat *:E | grep -i "flutter\|firebase"
```

### Method 2: Check Device Logs
Settings → Developer Options → Bug Report

### Method 3: Firebase Crashlytics (Optional)
Add to detect crashes automatically in production.

---

## 🎯 Quick Fix Commands

```bash
# Complete rebuild process
flutter clean
rm -rf build/
flutter pub get
flutter build apk --release

# Install and test
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep -i flutter
```

---

## 💡 Pro Tips

1. **Always test debug build first** - Better error messages
2. **Check logcat immediately** - Crash info is there
3. **Keep minification disabled** - Until app is stable
4. **Use debug signing** - For testing, not production
5. **Test Google Sign-In separately** - Enable test mode in Firebase

---

## 📞 Still Not Working?

Share the logcat output:
```bash
adb logcat > crash_log.txt
```

Then check `crash_log.txt` for:
- Line with "FATAL EXCEPTION"
- Firebase errors
- Package name mismatches
- Missing permissions

---

**After my fixes, rebuilding should solve the crash! 🎉**

Just run:
```bash
flutter clean && flutter pub get && flutter build apk --release
```
