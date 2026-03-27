# Textify 📱

> Scan text from anywhere on your phone — camera or gallery — powered by Google ML Kit. 100% offline, 100% free.

---

## Features

- 📷 **Live Camera Scan** — point at any text and tap to extract
- 🖼️ **Gallery / Screenshot Scan** — pick any image from your phone
- 📋 **Copy & Share** — copy extracted text to clipboard or share to other apps
- 🔒 **Fully Offline** — no internet required, no data sent anywhere
- ⚡ **Fast** — ML Kit processes most images in under a second

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| OCR Engine | Google ML Kit Text Recognition |
| Camera | `camera` package |
| Image Picker | `image_picker` package |

---

## Getting Started

### Prerequisites

- Flutter SDK (stable, latest)
- Android Studio or VS Code with Flutter extension
- Android phone or emulator (API 21+)

### Run the app

```bash
git clone https://github.com/Dnggr/Textify.git
cd Textify
flutter pub get
flutter run
```

> ⚠️ For camera features, use a **real physical device**. Android emulators don't have real cameras.

---

## Project Structure

```
lib/
├── main.dart                  # App entry point + theme
├── screens/
│   ├── home_screen.dart       # Main menu
│   ├── camera_screen.dart     # Live camera OCR
│   ├── gallery_screen.dart    # Image picker OCR
│   └── result_screen.dart     # Extracted text display
├── services/
│   └── ocr_service.dart       # ML Kit OCR logic
└── widgets/
    ├── action_button.dart      # Reusable glow button
    └── text_result_card.dart   # Text display card
```

---

## Permissions

| Permission | Why |
|---|---|
| `CAMERA` | Live camera scan |
| `READ_MEDIA_IMAGES` | Pick images on Android 13+ |
| `READ_EXTERNAL_STORAGE` | Pick images on Android ≤12 |

---

## Made by

[@Dnggr](https://github.com/Dnggr) — a student project built with curiosity 🚀