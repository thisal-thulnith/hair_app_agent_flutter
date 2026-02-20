# 🌐 Ngrok Backend Setup for Android

## Quick Setup (3 Steps)

### **Step 1: Set Your Ngrok URL**

Edit: `lib/config/environment.dart`

Find line ~17 and replace `null` with your ngrok URL:

```dart
// BEFORE (line ~17):
static const String? remoteBackendUrl = null; // SET YOUR NGROK URL HERE

// AFTER:
static const String? remoteBackendUrl = 'https://your-ngrok-url.ngrok.io';
```

**Example:**
```dart
static const String? remoteBackendUrl = 'https://abc123.ngrok.io';
```

⚠️ **Important:**
- Include `https://` in the URL
- Do NOT include trailing slash (`/`)
- Do NOT include port number (ngrok handles this)

---

### **Step 2: Start Your Backend with Ngrok**

```bash
# Terminal 1: Start your backend
cd /Users/thisalthulnith/beuty/beauty_ai
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# Terminal 2: Start ngrok
ngrok http 8000
```

Copy the ngrok HTTPS URL (looks like: `https://abc123.ngrok.io`)

---

### **Step 3: Rebuild and Install APK**

```bash
cd /Users/thisalthulnith/.gemini/antigravity/scratch/salon-buff/flutter_app

# Clean previous build
flutter clean
flutter pub get

# Build APK with new backend URL
flutter build apk --release

# Install on device
flutter install
```

---

## ✅ Verify Backend Connection

### **Test 1: Check Backend Health**

Open phone browser and visit:
```
https://your-ngrok-url.ngrok.io/health
```

Should see: `{"status":"ok"}`

### **Test 2: Check in App**

1. Open app
2. Login screen should load properly
3. Try to login - should connect to backend

---

## 🐛 Troubleshooting

### **Issue: "Cannot connect to backend"**

**Solution:**
1. Verify ngrok URL is correct in `environment.dart`
2. Make sure ngrok is running
3. Test URL in phone browser first
4. Rebuild APK after changing URL

### **Issue: "Login failed" or "Network error"**

**Solutions:**
1. Check backend logs for errors
2. Verify Firebase Auth is enabled
3. Make sure ngrok tunnel is not expired (free plan expires every 2 hours)
4. Check if backend server is still running

### **Issue: "Images not loading"**

**Solutions:**
1. Images are stored as base64 in Firebase (should work offline)
2. If using URL images, make sure backend serves images over HTTPS
3. Check backend CORS settings allow ngrok domain

### **Issue: "Google Sign-In not working"**

**Solutions:**
1. Google Sign-In requires additional setup for production domains
2. Use Email/Password authentication instead
3. Or add ngrok domain to Firebase authorized domains:
   - Firebase Console → Authentication → Settings → Authorized domains
   - Add your ngrok domain (e.g., `abc123.ngrok.io`)

---

## 🔄 Updating Ngrok URL

When your ngrok URL changes (free plan changes URL every restart):

1. **Update environment.dart:**
   ```dart
   static const String? remoteBackendUrl = 'https://NEW-URL.ngrok.io';
   ```

2. **Rebuild APK:**
   ```bash
   flutter build apk --release
   flutter install
   ```

**Tip:** Get a persistent ngrok domain with a paid plan to avoid URL changes.

---

## 📱 Testing Checklist

After setting up ngrok:

- [ ] Backend health endpoint responds (`/health`)
- [ ] App can login with email/password
- [ ] App can send chat messages
- [ ] App can upload images
- [ ] AI responses work
- [ ] Images display correctly
- [ ] Chat history loads

---

## 🚀 Production Deployment (Optional)

For permanent deployment without ngrok:

1. **Deploy backend to cloud:**
   - Google Cloud Run
   - AWS Lambda
   - DigitalOcean
   - Heroku
   - Railway

2. **Update environment.dart:**
   ```dart
   static const String? remoteBackendUrl = 'https://api.yourapp.com';
   ```

3. **Enable HTTPS** (required for production)

4. **Configure CORS** on backend to allow your app domain

---

## 💡 Tips

1. **Free Ngrok Limits:**
   - URL changes on every restart
   - 2 hour session timeout
   - Limited to 40 connections/minute

2. **Paid Ngrok Benefits:**
   - Custom subdomain (e.g., `yourapp.ngrok.io`)
   - Persistent URL (no need to rebuild APK)
   - Higher connection limits

3. **Development Workflow:**
   - Use local backend for development
   - Use ngrok only for testing on physical devices not on same network
   - Use production backend for release builds

---

## 🔐 Security Note

⚠️ **Warning:** ngrok URLs are publicly accessible!

- Don't commit ngrok URLs to git
- Don't share ngrok URLs publicly
- Enable Firebase Auth to protect your backend
- Consider adding API authentication for production

---

## Quick Reference

### Backend URL Priority:
```
1. remoteBackendUrl (ngrok, production) ← Use this for Android APK
2. localNetworkIP (local network)
3. Platform default (localhost/10.0.2.2)
```

### Required Files to Edit:
```
lib/config/environment.dart - Set remoteBackendUrl
```

### Build Command:
```bash
flutter build apk --release && flutter install
```

---

**Your Android APK will now work with ngrok backend! 🎉**
