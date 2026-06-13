# App Icon Guide

## Current Icon Setup

Your app currently uses `assets/app.jpg` as the launcher icon.

## How to Change the App Icon Look

### Method 1: Quick Change (Use Existing Image)
Run this command with any image from your assets:
```bash
dart run generate_app_icon.dart assets/images/1.png
```

Available images:
- `assets/images/1.png`
- `assets/images/2.png`
- `assets/images/3.png`
- `assets/images/4.png`
- `assets/images/6.png`
- `assets/images/18.png`
- `assets/images/121.png`

### Method 2: Professional Setup (Recommended)
1. **Edit or replace** `assets/app.jpg` with your new icon design
2. Run: `generate_professional_icons.bat`
3. This uses flutter_launcher_icons package for better quality

### Method 3: Design a New Icon

#### Icon Design Guidelines:
- **Size**: 1024x1024 pixels (minimum 512x512)
- **Format**: PNG (transparent background) or JPG
- **Keep it simple**: Bold, recognizable design
- **Safe area**: Keep important content in center 70%
- **Test on dark/light backgrounds**

#### Free Design Tools:
1. **Canva** - https://www.canva.com (easiest)
2. **GIMP** - Free Photoshop alternative
3. **AppIcon.co** - https://www.appicon.co
4. **IconKitchen** - https://icon.kitchen

#### Steps:
1. Create your icon design (1024x1024px)
2. Save as `assets/app.jpg` or `assets/app.png`
3. Update `pubspec.yaml` if you changed the filename:
   ```yaml
   flutter_launcher_icons:
     image_path: "assets/app.png"  # Change here
   ```
4. Run: `generate_professional_icons.bat`

### Method 4: Adaptive Icons (Android 8.0+)

Create separate foreground and background layers:

1. Create two images:
   - `assets/app_foreground.png` (your logo/icon)
   - `assets/app_background.png` (background color/pattern)

2. Edit `pubspec.yaml`:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/app.jpg"
     adaptive_icon_foreground: "assets/app_foreground.png"
     adaptive_icon_background: "#FFFFFF"  # Or use PNG background
   ```

3. Run: `generate_professional_icons.bat`

## After Changing Icon

Always run these commands after generating new icons:
```bash
flutter clean
flutter pub get
flutter run
```

Or uninstall and reinstall the app on your phone.

## Tips for Great Icons

✅ **DO:**
- Keep it simple and memorable
- Use high contrast colors
- Test on different backgrounds
- Make it recognizable at small sizes
- Use vector graphics if possible

❌ **DON'T:**
- Use too many details
- Include small text
- Use low contrast colors
- Make it too complex

## Current Configuration

Your icon is configured in:
- `pubspec.yaml` → flutter_launcher_icons section
- `android/app/src/main/AndroidManifest.xml` → android:icon="@mipmap/ic_launcher"

The icon file location:
- Source: `assets/app.jpg`
- Generated Android icons: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Generated iOS icons: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
