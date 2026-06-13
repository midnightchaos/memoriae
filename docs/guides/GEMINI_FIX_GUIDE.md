# Gemini Chatbot Not Responding - Fix Guide

## Problem
The Menta chatbot is not receiving responses from Gemini AI when users send messages.

## Root Causes Identified

### 1. **Missing or Invalid API Key**
   - The app requires a Gemini API key to work
   - API key might not be configured in the app

### 2. **Silent Error Handling**
   - Errors are being caught but not properly logged
   - MentaService falls back to local responses without showing the real error

### 3. **No Network Diagnostic Logging**
   - Can't see HTTP requests/responses in the logs you provided
   - Need better logging to diagnose issues

## Solutions

### Solution 1: Add Your Gemini API Key

1. **Get a Gemini API Key:**
   - Go to: https://aistudio.google.com/app/apikey
   - Create a new API key (it's free)
   - Copy the key

2. **Add the key to your app:**
   
   **Option A: Via App Settings (Recommended)**
   ```dart
   // The app already has a settings screen
   // Just navigate to Settings and enter your API key
   ```

   **Option B: Add as Environment Variable**
   ```bash
   # When building the app
   flutter run --dart-define=GEMINI_API_KEY=YOUR_API_KEY_HERE
   ```

   **Option C: Hardcode for Testing (Not recommended for production)**
   ```dart
   // In lib/config/env_config.dart
   class EnvConfig {
     static const String geminiApiKey = 'YOUR_API_KEY_HERE';
     static bool get hasDefaultApiKey => geminiApiKey.isNotEmpty;
   }
   ```

### Solution 2: Use the Enhanced GeminiService

Replace the current `gemini_service.dart` with the fixed version that includes better logging:

```bash
# Backup current service
mv lib/services/gemini_service.dart lib/services/gemini_service_backup.dart

# Use the fixed version
mv lib/services/gemini_service_fixed.dart lib/services/gemini_service.dart
```

### Solution 3: Run Diagnostic Test

Before using the app, test your API key:

```bash
# Edit test_gemini_diagnosis.dart and add your API key
# Then run:
flutter run test_gemini_diagnosis.dart
```

This will tell you:
- ✅ If your API key is valid
- ✅ If network requests are working
- ✅ If Gemini API is accessible
- ❌ Where the problem is if something fails

### Solution 4: Check Internet Permissions

Make sure your app has internet permission:

**Android: `android/app/src/main/AndroidManifest.xml`**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**iOS: `ios/Runner/Info.plist`**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Solution 5: Enable Better Logging

To see what's happening, check logs with:

```bash
# Flutter logs
flutter logs

# Android logs (more detailed)
adb logcat | grep -E "(GeminiService|Menta|HTTP)"
```

Look for these log patterns:
```
[GeminiService] ========== SEND MESSAGE START ==========
[GeminiService] Has API key: true/false
[GeminiService] Making API request...
[GeminiService] Response status: 200
```

## Quick Checklist

- [ ] Got Gemini API key from https://aistudio.google.com/app/apikey
- [ ] Added API key to app (via Settings or env variable)
- [ ] Replaced gemini_service.dart with fixed version
- [ ] Ran diagnostic test successfully
- [ ] Confirmed internet permissions in AndroidManifest.xml
- [ ] Rebuilt the app (`flutter clean && flutter build apk`)
- [ ] Tested with a simple message like "Hello"

## Expected Behavior After Fix

When you send "Tell me a joke":
1. You see logs: `[GeminiService] ========== SEND MESSAGE START ==========`
2. Status: `[GeminiService] Response status: 200`
3. Response: `[GeminiService] Response text length: XX characters`
4. UI updates with Menta's joke response

## Still Not Working?

If the issue persists after trying all solutions:

1. **Check the diagnostic output:**
   ```bash
   flutter run test_gemini_diagnosis.dart
   ```
   This will show exactly what's failing.

2. **Test with curl:**
   ```bash
   curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_KEY \
     -H 'Content-Type: application/json' \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
   ```

3. **Common Issues:**
   - **401 Error**: Invalid API key
   - **403 Error**: API key doesn't have permission
   - **Timeout**: Network issue or slow connection
   - **No response**: Check if app has internet permission

## Testing the Fix

After applying the fix:

```bash
# 1. Clean and rebuild
flutter clean
flutter pub get
flutter build apk

# 2. Install on device
flutter install

# 3. Watch logs while testing
flutter logs

# 4. In the app, go to chat and send: "Tell me a joke"
# 5. Check logs for [GeminiService] messages
```

## Need More Help?

Check these logs locations:
1. Flutter logs: `flutter logs`
2. Android logs: `adb logcat`
3. App debug console in VS Code/Android Studio

Share the output from `test_gemini_diagnosis.dart` if still having issues.
