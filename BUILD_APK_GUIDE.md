# 🏗️ Complete APK Build Guide - Buff Salon

## ✅ Your Code Status
- **No compilation errors** in active files
- All Firebase services integrated
- Google Sign-In ready
- Backend connected to ngrok

---

## 📋 Prerequisites

### 1. Install Android Studio
Download from: https://developer.android.com/studio

During installation, make sure to install:
- Android SDK
- Android SDK Platform
- Android SDK Build-Tools
- Android Emulator

### 2. Set Environment Variables

Add to your `~/.zshrc` or `~/.bash_profile`:

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

Then run:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

---

## 🔥 Firebase Setup for Android

### Step 1: Add Android App to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Add app** → Select **Android** (📱 icon)
4. Fill in:
   - **Package name**: `com.beautyai.salon_buff` (must match!)
   - **App nickname**: Buff Salon
   - **Debug signing certificate SHA-1**: (get from step 2 below)

### Step 2: Get SHA-1 Certificate

Run this command in your project directory:

```bash
cd android
./gradlew signingReport
```

Copy the **SHA-1** from the output (looks like: `12:34:56:78:90:AB:CD:EF:...`)

Go back to Firebase Console and paste it in the SHA-1 field.

### Step 3: Download google-services.json

1. In Firebase Console, click **Download google-services.json**
2. Move it to your project:

```bash
mv ~/Downloads/google-services.json android/app/google-services.json
```

### Step 4: Verify AndroidManifest.xml

Check `android/app/src/main/AndroidManifest.xml` has:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.beautyai.salon_buff">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

    <application
        android:label="Buff Salon"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">

        <!-- ... rest of your config ... -->
    </application>
</manifest>
```

### Step 5: Enable Google Sign-In in Firebase

1. Firebase Console → **Authentication** → **Sign-in method**
2. Enable **Google**
3. Set support email

---

## 🛠️ Build Configuration

### Update build.gradle

Check `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Important!
}

android {
    namespace = "com.beautyai.salon_buff"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.beautyai.salon_buff"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true  // ← Important for Firebase
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // For production, use proper signing config
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("androidx.multidex:multidex:2.0.1")
}
```

### Update project build.gradle

Check `android/build.gradle.kts`:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.gms:google-services:4.4.2")  // ← Important!
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

---

## 📱 Build the APK

### Method 1: Release APK (Recommended)

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Debug APK (For Testing)

```bash
flutter build apk --debug

# APK will be at:
# build/app/outputs/flutter-apk/app-debug.apk
```

### Method 3: Split APKs by Architecture (Smaller file sizes)

```bash
flutter build apk --split-per-abi

# Creates separate APKs:
# app-armeabi-v7a-release.apk (32-bit ARM)
# app-arm64-v8a-release.apk (64-bit ARM - most devices)
# app-x86_64-release.apk (Intel/AMD)
```

---

## 📦 Install APK

### On Connected Device:
```bash
flutter install

# Or manually:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Transfer to Phone:
- Copy APK to phone via USB/AirDrop/Email
- Enable "Install from Unknown Sources" in phone settings
- Open APK file and install

---

## ✅ Testing Checklist

After installing the APK, test:

- [ ] App launches successfully
- [ ] Google Sign-In button appears
- [ ] Clicking Google Sign-In opens account picker
- [ ] After signing in, user is created in Firestore
- [ ] Chat screen appears
- [ ] Can send text messages
- [ ] Can upload images
- [ ] Messages are saved to Firestore
- [ ] Backend connection works (ngrok endpoint)
- [ ] Logout works
- [ ] Re-login works with existing account

---

## 🐛 Troubleshooting

### "Google Sign-In Failed"
- ✅ Check SHA-1 is added to Firebase Console
- ✅ Check google-services.json is in android/app/
- ✅ Check package name matches exactly: `com.beautyai.salon_buff`
- ✅ Rebuild APK after changes

### "Network Error" / Can't Connect to Backend
- ✅ Check phone has internet connection
- ✅ Check ngrok URL is correct in environment.dart
- ✅ Test backend URL in browser on phone
- ✅ Check backend is running

### "Permission Denied"
- ✅ Check AndroidManifest.xml has all permissions
- ✅ Grant permissions in phone Settings → Apps → Buff Salon

### "Firestore Error"
- ✅ Enable Firestore in Firebase Console
- ✅ Check Firestore rules allow authenticated users
- ✅ Check internet connection

---

## 🎯 Quick Build Command

Once everything is set up, just run:

```bash
flutter clean && flutter pub get && flutter build apk --release
```

APK location:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📤 Share APK

To share with others:
1. Upload to Google Drive/Dropbox
2. Send direct download link
3. Users must enable "Install from Unknown Sources"

---

## 🔒 Production Build (Optional)

For Play Store release:

1. Generate signing key:
```bash
keytool -genkey -v -keystore ~/buff-salon-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias buff-salon
```

2. Create `android/key.properties`:
```
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=buff-salon
storeFile=/path/to/buff-salon-key.jks
```

3. Update `android/app/build.gradle.kts` to use signing config

4. Build signed APK:
```bash
flutter build apk --release
```

---

**Your app is ready to build! 🎉**

Just follow the steps above to create a working APK with Google Sign-In and Firestore!
