# Textify 📱

> Scan text from anywhere on your phone — camera or gallery — powered by Google ML Kit. 100% offline, 100% free.

---

## 📥 Download & Install

**Ready to use Textify?** Download the latest APK directly from the link below and install it on your Android device:

[![Download APK](https://img.shields.io/badge/Download-Android_APK-green?style=for-the-badge&logo=android)](https://drive.google.com/drive/folders/1Jx4efvQGhp4vboODRP2tM8fMQ7Dl29TW)

> **Note:** Since this is a student project, you may need to "Allow installation from unknown sources" in your Android settings to install the APK.

---

## ✨ Features

- 📷 **Live Camera Scan** — Point at any text and tap to extract.
- 🖼️ **Gallery / Screenshot Scan** — Pick any image from your phone.
- 📋 **Copy & Share** — Copy extracted text to clipboard or share to other apps.
- 🔒 **Fully Offline** — No internet required; your data stays on your device.
- ⚡ **Fast** — ML Kit processes most images in under a second.

---

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **OCR Engine** | Google ML Kit Text Recognition |
| **Camera** | `camera` package |
| **Image Picker** | `image_picker` package |

---

## 🚀 Getting Started (Developers)

### Prerequisites
- Flutter SDK (stable, latest)
- Android Studio or VS Code with Flutter extension
- Android phone or emulator (API 21+)

### Run the app
```bash
git clone [https://github.com/Dnggr/Textify.git](https://github.com/Dnggr/Textify.git)
cd Textify
flutter pub get
flutter run
