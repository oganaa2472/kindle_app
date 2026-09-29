# Kindle App

A Flutter ebook reader with a Kindle-inspired library and reading experience.
The app loads EPUB books bundled in `assets/books/`, splits their content into
readable pages, and provides reading preferences plus tap-to-define word lookup.

## Features

- EPUB library loaded from `assets/books/`
- Search books by title or author
- Card-based Kindle-style library UI
- Page-by-page reading view
- Sepia, light, and dark reading themes
- Adjustable reading font size
- EPUB HTML cleanup and paragraph-aware pagination
- Tap an English word to view:
  - English dictionary definitions
  - Part of speech
  - Example sentences
  - Similar words when available
  - Mongolian translation when available
- Hive-backed persistence for reading preferences

## Requirements

- Flutter SDK compatible with Dart `^3.13.4`
- Xcode for iOS development
- Android Studio/Android SDK for Android development
- An internet connection for word definitions and translations

Check the local Flutter setup with:

```bash
flutter doctor
```

## Run locally

Install dependencies:

```bash
flutter pub get
```

List available devices:

```bash
flutter devices
```

Run the app:

```bash
flutter run
```

Run tests:

```bash
flutter test
```

## Add EPUB books

Copy `.epub` files into:

```text
assets/books/
```

The directory is already registered in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/books/
```

After adding a book, restart the app or use the refresh button in the library.
When adding or removing assets during development, run:

```bash
flutter pub get
```

The EPUB files are bundled into release builds, so they do not need to be
copied separately to the device.

## iOS installation

For development:

1. Connect an iPhone to the Mac and select **Trust This Computer**.
2. Enable **Developer Mode** on the iPhone.
3. Open the iOS workspace:

   ```bash
   open ios/Runner.xcworkspace
   ```

4. In Xcode, select the `Runner` target.
5. Open **Signing & Capabilities** and select an Apple Developer Team.
6. Select the iPhone as the run destination and run the app.

For a device build, configure signing in Xcode and use:

```bash
flutter build ios --release
```

An unpaid Apple account may require the app to be re-signed periodically.
TestFlight or a paid Apple Developer account is recommended for longer-term
device testing.

## Android installation

For a connected Android device:

```bash
flutter install --release
```

To generate a standalone APK:

```bash
flutter build apk --release
```

The APK is generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install that APK on the device. Once installed, the app does not need to stay
connected to USB.

## Word lookup and translation

The reader currently uses these public services:

- English definitions: `api.dictionaryapi.dev`
- English-to-Mongolian translation: `api.mymemory.translated.net`

The app sends the normalized English word only. Punctuation around a word is
removed before the request. The reader itself works offline, but word lookup
and translation require Wi-Fi or mobile data.

These public APIs may experience rate limits, timeouts, or temporary outages.
The UI displays a clear error or fallback message when a service is
unavailable.

## Project structure

```text
lib/
├── core/theme/                       # App colors and themes
├── features/library/                 # Book library and book cards
└── features/reader/
    ├── cubit/                        # Reading preferences state
    ├── data/                         # EPUB and dictionary services
    └── view/                         # Reader UI and word lookup sheet
assets/books/                         # Bundled EPUB files
test/                                 # Flutter and EPUB parser tests
```

## License

This project is not currently published under a formal open-source license.
Only add books and other assets that you have permission to distribute.
