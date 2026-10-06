# English Fox v1.5 — Android

Android-first build of English Fox for phones and tablets.

## Included
- 6 adventure worlds / 42 missions
- responsive map for small and large screens
- stars, coins, rewards and achievements
- persistent progress with SharedPreferences
- English TTS
- child-friendly large touch targets
- Android target: phone + tablet

## Build APK on a computer with Flutter installed
```bash
flutter create .
flutter pub get
flutter analyze
flutter build apk --release
```
The APK will be in `build/app/outputs/flutter-apk/app-release.apk`.

For Google Play, build an AAB:
```bash
flutter build appbundle --release
```

Note: this repository is source code. It is not itself an installable APK.
