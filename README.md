# English Fox 0.5.0

A children's English-learning Android game with 6 worlds and 42 missions.

- Illustrated welcome screen and local learner profile (name, age 5–9, avatar).
- Map, Lessons, Shop and Profile navigation.
- Offline pictures for all 148 vocabulary words.
- Listen-and-repeat cards, picture quizzes and a Great job results screen.
- Persistent progress, earned coins and cosmetic accessories.
- Updated Android launcher icon.

See UPDATE_V5_RU.md for the Russian change and validation report, IMAGE_ASSETS.md for generated asset prompts, and screenshots/ for UI previews. Third-party art and font licenses are included under assets/.

## Build

Use Flutter 3.47.5, Android SDK 36 and a physical project path without non-ASCII characters on Windows.

```sh
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --release
```

The current release build uses the standard Android debug signing configuration for local installation. Set up your own release signing before publishing.

The profile is local to the device. Speech playback uses the device TTS engine; there is no speech recording, remote account, or real-money purchase.
