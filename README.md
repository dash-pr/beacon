# Beacon — Disaster P2P Communication App

Offline-first BLE mesh disaster communication app with on-device AI, triage assistance, translation, and situational awareness. Built for scenarios where cell towers are down and internet is unavailable.

Two Android phones can communicate via Bluetooth Low Energy (BLE) without any internet connection. When connectivity is restored, messages sync to the cloud.

## Live Demo

**[Web UI Demo](https://web-sooty-tau-95.vercel.app)** — browse the full app interface in your browser. This is a UI-only preview; BLE mesh, camera, AI, and voice features require the Android APK on a physical device.

## Download APK

Download the latest pre-built APK from [GitHub Releases](https://github.com/dash-pr/beacon/releases/latest).

Install on your Android device:
1. Transfer the APK to your phone (USB, AirDrop, email, etc.)
2. Enable **Settings → Security → Install Unknown Apps** for your file manager
3. Open the APK and tap Install

Or via ADB:
```bash
adb install beacon-v1.0.apk
```

## Features

- **BLE Mesh Chat** — P2P messaging between devices using Bluetooth Low Energy, no internet required
- **Manual SOS** — One-tap SOS button in chat with confirmation dialog
- **Direct Messages** — Private P2P conversations between discovered devices
- **On-Device AI Assistant** — Gemma 3 1B LLM for offline first-aid and disaster guidance
- **Camera Triage** — ML Kit image labeling for offline damage/injury assessment
- **Voice Input** — On-device speech-to-text for hands-free messaging
- **Translation** — ML Kit on-device translation (EN, JA, ZH, KO)
- **Multi-Language UI** — Full app localization in English, Japanese, Chinese, Korean
- **Community Forum** — Resource reports (food, shelter, medical, hazards) with approval system
- **Disaster Alerts** — J-Alert XML feed with translation support
- **Topographic Maps** — OpenTopoMap with shelter markers and forum resource overlays
- **au Starlink Direct** — Satellite backup mode for areas with no cellular coverage
- **Safety Checks** — Mutual safety confirmation between connected users
- **Responder Dashboard** — SOS feed with severity filtering and map view
- **Cloud Sync** — Firebase Firestore sync when internet becomes available

## Prerequisites

- **Flutter SDK** >= 3.11.1 (stable channel)
- **Dart SDK** >= 3.11.1 (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter/Dart plugins
- **Android SDK** with API level 21+ (Android 5.0+)
- **Java Development Kit (JDK)** 17 (required by Android Gradle plugin)
- **Two Android devices** for BLE mesh testing (emulators don't support BLE)

### Optional (for online features)

- **Firebase project** with Firestore enabled — add `google-services.json` to `android/app/`
- **DeepL API key** — for alert translation
- **Gemini API key** — for enhanced online image triage

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/dash-pr/beacon.git
cd beacon
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate Hive adapters

The project uses Hive for local storage with generated type adapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

Connect an Android device via USB (with USB debugging enabled) and run:

```bash
flutter run
```

Or build a release APK:

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### 5. Install APK on device

```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer the APK file to the device and open it
# (Enable "Install Unknown Apps" in device Settings > Security)
```

## Environment Variables (Optional)

Create a `.env` file in the project root for online features:

```
FIREBASE_PROJECT_ID=your_project_id
DEEPL_API_KEY=your_key_here
GEMINI_API_KEY=your_key_here
```

These are only needed for cloud sync, translation, and enhanced AI triage. The core BLE mesh chat and on-device AI work fully offline.

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp + providers setup
├── core/
│   ├── constants/                     # Colors, config
│   ├── theme/                         # Material 3 dark theme
│   └── utils/                         # SOS detector, permissions
├── models/                            # Data models (Message, User, Alert, Shelter)
├── providers/                         # State management (Provider)
├── screens/
│   ├── home/                          # Dashboard + mesh status
│   ├── chat/                          # BLE mesh P2P chat
│   ├── assistant/                     # On-device LLM chat
│   ├── camera/                        # Image capture + AI triage
│   ├── map/                           # Offline map with shelters
│   ├── alerts/                        # J-Alert feed + translations
│   └── responder/                     # Responder dashboard
└── services/
    ├── mesh/                          # BLE Central + Peripheral
    ├── ai/                            # LLM, voice, image analysis
    ├── alerts/                        # J-Alert XML parsing
    ├── map/                           # Shelter data
    ├── safety/                        # Safety check service
    ├── sync/                          # Connectivity monitoring
    └── translation/                   # On-device translation (ML Kit)
```

## First Launch Notes

- **Gemma 3 1B model** (~1GB) downloads on first launch — ensure internet access for the initial setup
- **ML Kit models** auto-download on first use — open the camera once with internet before going offline
- **BLE range** is ~10-30 meters indoors — keep devices in the same room for testing
- **BLE requires physical devices** — Android emulators do not support Bluetooth Low Energy

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — Android |
| P2P / Mesh | `flutter_blue_plus` + `ble_peripheral` |
| On-Device LLM | `flutter_gemma` (Gemma 3 1B) |
| On-Device Vision | `google_mlkit_image_labeling` |
| On-Device OCR | `google_mlkit_text_recognition` |
| On-Device Translation | `google_mlkit_translation` |
| Voice to Text | `speech_to_text` |
| Local Storage | `hive` |
| Maps | `flutter_map` + OpenStreetMap |
| State Management | `provider` |
| Design System | Material 3 |

## License

MIT

---

*"When infrastructure fails, people shouldn't."*
