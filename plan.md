# Tasuke (助け) — Disaster P2P Communication App
## Hackathon Build Plan

---

## Project Overview

**App Name:** Tasuke (助け) — "Help" in Japanese
**Platform:** Flutter — Android only (demo on 2 Android devices)
**Purpose:** Offline-first BLE mesh disaster communication with on-device AI,
             triage assistance, translation, and situational awareness
**Demo Target:** 2 Android phones communicating without internet + sync when online

---

## APK Installation (No Play Store Needed)

```bash
# Build release APK
flutter build apk --release

# APK location after build
build/app/outputs/flutter-apk/app-release.apk

# Install options:
# 1. USB: adb install build/app/outputs/flutter-apk/app-release.apk
# 2. Transfer APK file directly to device → open → install
# 3. Share via QR code using any file sharing app

# Enable on device first:
# Settings → Security → Install Unknown Apps → Allow
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) — Android only |
| P2P / Mesh | `flutter_blue_plus` (BLE Central + Peripheral) |
| On-Device LLM | `flutter_gemma` (Gemma 3 1B — first aid + Q&A) |
| On-Device Vision | `google_mlkit_image_labeling` |
| On-Device OCR | `google_mlkit_text_recognition` |
| Voice to Text | `speech_to_text` (on-device Android engine) |
| Local Storage | `hive` (offline-first NoSQL) |
| Cloud Sync | Firebase Firestore |
| Push Notifications | Firebase Cloud Messaging |
| Maps | `flutter_map` + OpenStreetMap (pre-cached tiles) |
| Cloud AI Vision | Gemini Vision API (online fallback) |
| Translation | DeepL API (online) |
| Disaster Alerts | J-Alert XML feed |
| Backend | Firebase (serverless) |

---

## Project Structure

```
tasuke/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_config.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       ├── connectivity_utils.dart
│   │       └── sos_detector.dart
│   │
│   ├── models/
│   │   ├── message_model.dart
│   │   ├── user_model.dart
│   │   ├── alert_model.dart
│   │   ├── shelter_model.dart
│   │   └── danger_zone_model.dart
│   │
│   ├── services/
│   │   ├── mesh/
│   │   │   ├── ble_mesh_service.dart          # BLE Central + Peripheral
│   │   │   └── message_queue_service.dart     # Offline message queue
│   │   ├── sync/
│   │   │   ├── firebase_sync_service.dart     # Cloud sync when online
│   │   │   └── connectivity_service.dart      # Monitor network state
│   │   ├── ai/
│   │   │   ├── llm_service.dart               # flutter_gemma on-device LLM
│   │   │   ├── voice_service.dart             # Speech to text
│   │   │   ├── image_analysis_service.dart    # ML Kit + Gemini Vision
│   │   │   └── sos_detection_service.dart     # SOS scoring + priority
│   │   ├── alerts/
│   │   │   ├── jalert_service.dart            # J-Alert XML fetch + parse
│   │   │   └── translation_service.dart       # DeepL API
│   │   └── map/
│   │       ├── shelter_service.dart           # Load shelter data
│   │       └── map_cache_service.dart         # Offline tile caching
│   │
│   ├── providers/
│   │   ├── mesh_provider.dart
│   │   ├── message_provider.dart
│   │   ├── llm_provider.dart
│   │   ├── map_provider.dart
│   │   ├── alert_provider.dart
│   │   └── user_provider.dart
│   │
│   └── screens/
│       ├── splash/
│       │   └── splash_screen.dart             # Model download progress
│       ├── home/
│       │   └── home_screen.dart               # Dashboard + mesh status
│       ├── chat/
│       │   ├── chat_screen.dart               # BLE mesh P2P chat
│       │   └── widgets/
│       │       ├── message_bubble.dart
│       │       ├── sos_banner.dart
│       │       └── voice_input_button.dart
│       ├── assistant/
│       │   ├── assistant_screen.dart          # On-device LLM chat
│       │   └── widgets/
│       │       └── assistant_bubble.dart
│       ├── map/
│       │   ├── map_screen.dart
│       │   └── widgets/
│       │       ├── shelter_marker.dart
│       │       ├── danger_marker.dart
│       │       └── map_legend.dart
│       ├── camera/
│       │   ├── camera_screen.dart             # Image capture + AI triage
│       │   └── widgets/
│       │       └── triage_result_card.dart
│       └── alerts/
│           ├── alerts_screen.dart             # J-Alert + translations
│           └── widgets/
│               └── alert_card.dart
│
├── assets/
│   ├── shelters/
│   │   └── tokyo_shelters.json               # Pre-loaded government shelter data
│   ├── prompts/
│   │   └── system_prompt.txt                 # LLM system prompt
│   └── icons/
│
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── pubspec.yaml
└── README.md
```

---

## Data Models

### MessageModel
```dart
// lib/models/message_model.dart
class MessageModel {
  String id;           // UUID — prevents duplicate rebroadcast
  String senderId;     // Device BLE ID
  String senderName;   // Display name
  String content;      // Text content
  String? imageBase64; // Compressed image (offline)
  String? imageUrl;    // Firebase URL (when synced)
  MessageType type;    // text | voice | image | sos | system
  Priority priority;   // normal | urgent | sos
  DateTime timestamp;
  bool isSynced;       // Has reached Firebase
  int hopCount;        // Mesh hops traversed
  double? lat;         // Optional location
  double? lng;
}

enum MessageType { text, voice, image, sos, system }
enum Priority { normal, urgent, sos }
```

### AlertModel
```dart
// lib/models/alert_model.dart
class AlertModel {
  String id;
  String type;            // earthquake | tsunami | flood | fire
  String severity;        // minor | moderate | severe | extreme
  String originalText;    // Japanese original from J-Alert
  String translatedText;  // English translation
  String affectedArea;
  DateTime issuedAt;
  bool isRead;
}
```

### ShelterModel
```dart
// lib/models/shelter_model.dart
class ShelterModel {
  String id;
  String name;
  String nameJa;
  double lat;
  double lng;
  String type;      // shelter | hospital | food_water | assembly_point
  int? capacity;
  bool isVerified;  // Official government data
  bool? isOpen;     // Crowdsourced real-time status
}
```

---

## Core Services — Implementation Notes

### 1. BLE Mesh Service
**File:** `lib/services/mesh/ble_mesh_service.dart`

- Use `flutter_blue_plus`
- Device acts as **both** Central (scanner) and Peripheral (advertiser) simultaneously
- Custom GATT Service UUID for Tasuke: `00001234-0000-1000-8000-00805f9b34fb`
- Custom Characteristic UUID for messages: `00005678-0000-1000-8000-00805f9b34fb`
- Message flow:
  ```
  Send message:
    → Save to Hive with isSynced=false
    → Write to all connected BLE peripheral characteristics
    → Each receiver checks seenMessageIds Set (prevent loops)
    → Receiver saves + rebroadcasts to their own connections (1 hop)
  
  Receive message:
    → Parse JSON from BLE bytes
    → Check against seenMessageIds — if seen, discard
    → Add to seenMessageIds
    → Save to Hive
    → Run SOS detection
    → Notify UI via stream
    → Rebroadcast to other connected devices
  ```
- Keep `Set<String> seenMessageIds` — prevents infinite rebroadcast loops
- Max message size per BLE packet: 512 bytes — chunk larger messages
- Compress images before sending over BLE (max 50KB for demo)

### 2. On-Device LLM Service
**File:** `lib/services/ai/llm_service.dart`

- Use `flutter_gemma` with Gemma 3 1B model
- Model downloaded on **first app launch** (~1GB) with progress indicator
- Model stored in app documents directory (persists between launches)
- System prompt loaded from `assets/prompts/system_prompt.txt`:
  ```
  You are Tasuke, an emergency first-aid and disaster assistant.
  You help survivors during earthquakes, floods, and disasters in Japan.
  Keep answers SHORT, CLEAR, and ACTIONABLE — max 4 sentences.
  Focus only on: first aid, food/water safety, shelter, immediate safety.
  Do not give medical diagnoses. Always recommend professional help when available.
  If asked anything unrelated to disaster/emergency, redirect politely.
  Respond in the same language the user writes in.
  ```
- Streaming response for better UX (tokens appear as generated)
- Runs fully offline — no API key needed after model download
- Conversation history: keep last 6 turns for context, then reset

### 3. SOS Detection Service
**File:** `lib/services/ai/sos_detection_service.dart`

```
Scoring Logic (pure Dart — instant, no ML needed):

  Japanese SOS keywords: 助けて, 救助, 怪我, 火事, 危険, 死, 血    → +3 each
  English SOS keywords:  help, SOS, trapped, injured, fire, dying  → +3 each
  Urgent keywords:       痛い, 病院, 水ない, no water, no food      → +1 each
  Image label match:     injury, fire, flood, collapse, smoke       → +3
  Image label match:     damage, debris, broken                     → +2

  Score >= 5  → Priority.sos    (red banner, queue jump, vibrate)
  Score 2-4   → Priority.urgent (orange highlight)
  Score 0-1   → Priority.normal
```

### 4. Image Analysis Service
**File:** `lib/services/ai/image_analysis_service.dart`

```
Offline path (always):
  → ML Kit Image Labeling → list of labels + confidence scores
  → ML Kit Text Recognition → extract visible text from scene
  → Map labels to disaster categories:
      fire_*, flame, smoke       → hazard: fire
      injury, wound, blood       → hazard: medical
      flood, water_damage        → hazard: flood
      rubble, collapse, debris   → hazard: structural
  → Generate offline triage card from label mapping

Online path (when connected):
  → Send compressed image to Gemini Vision API
  → Structured prompt returns JSON:
    {
      "severity": "low|medium|high|critical",
      "hazard_type": "fire|medical|flood|structural|unknown",
      "immediate_action_en": "...",
      "immediate_action_ja": "...",
      "safe_to_approach": true|false,
      "call_emergency": true|false
    }
  → Display enhanced triage card with Gemini result
```

### 5. Firebase Sync Service
**File:** `lib/services/sync/firebase_sync_service.dart`

```
Trigger: connectivity_plus stream detects internet

On connection detected:
  1. Upload all Hive messages where isSynced == false
  2. Pull messages from Firestore for last 2 hours
  3. Fetch latest J-Alerts from server
  4. Update shelter open/closed status
  5. Mark all uploaded messages isSynced = true
  6. Schedule next sync in 30 seconds

On disconnection:
  1. Log disconnect time
  2. Continue BLE mesh only
  3. Queue all new messages in Hive
```

### 6. J-Alert Service
**File:** `lib/services/alerts/jalert_service.dart`

- Poll JMA XML feed every 60s when online
- Endpoint: `https://www.data.jma.go.jp/developer/xml/feed/eqvol.xml`
- Parse XML → AlertModel
- Send Japanese text to DeepL API for translation
- Cache in Hive (readable offline after last fetch)
- Trigger local notification for severity >= severe

---

## Android Permissions
**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<!-- Location (required for BLE scan on Android 12+) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Camera + Microphone -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Network -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Vibration for SOS alerts -->
<uses-permission android:name="android.permission.VIBRATE" />
```

---

## pubspec.yaml

```yaml
name: tasuke
description: Offline-first disaster P2P communication with on-device AI

publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # P2P BLE Mesh
  flutter_blue_plus: ^1.31.0

  # On-Device LLM (Gemma 3 1B)
  flutter_gemma: ^0.3.0

  # On-Device Vision AI
  google_mlkit_image_labeling: ^0.9.0
  google_mlkit_text_recognition: ^0.11.0

  # Voice to Text (on-device)
  speech_to_text: ^6.6.0

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Firebase
  firebase_core: ^2.24.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.9

  # Maps
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  flutter_map_cache: ^1.1.1

  # Network + Connectivity
  connectivity_plus: ^5.0.2
  http: ^1.2.0

  # Location
  geolocator: ^11.0.0

  # Camera
  camera: ^0.10.5

  # XML parsing (J-Alert)
  xml: ^6.5.0

  # Utilities
  uuid: ^4.3.3
  intl: ^0.19.0
  permission_handler: ^11.3.0
  path_provider: ^2.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
  flutter_lints: ^3.0.0
```

---

## Firebase Firestore Structure

```
firestore/
├── messages/
│   └── {messageId}/
│       ├── content, type, priority
│       ├── senderId, senderName
│       ├── timestamp
│       ├── lat, lng
│       ├── hopCount
│       └── imageUrl (optional)
│
├── alerts/
│   └── {alertId}/
│       ├── type, severity
│       ├── originalText
│       ├── translatedText
│       ├── affectedArea
│       └── issuedAt
│
├── shelters/
│   └── {shelterId}/
│       ├── name, nameJa
│       ├── type, capacity
│       ├── lat, lng
│       ├── isVerified
│       └── isOpen
│
└── danger_zones/
    └── {zoneId}/
        ├── type, severity
        ├── lat, lng, radius
        ├── reportedBy
        ├── timestamp
        └── description
```

---

## Splash Screen — Model Download Flow

```
App first launch:
  1. Show Tasuke logo + tagline
  2. Check if Gemma 3 1B model exists in documents directory
  3. If not:
     → Show download progress bar
     → "Downloading AI model for offline use... (1.0 GB)"
     → Download via flutter_gemma model manager
  4. If yes:
     → Skip download, proceed immediately
  5. Initialize Hive boxes
  6. Initialize BLE service
  7. Navigate to Home screen
```

---

## Build Order (48-Hour Sprint)

### Phase 1 — Foundation (Hour 0–6)
- [ ] Flutter project setup + all dependencies installed
- [ ] Android permissions configured in AndroidManifest.xml
- [ ] Hive initialized + MessageModel adapter generated
- [ ] App theme (dark, disaster-appropriate — red/dark grey palette)
- [ ] Splash screen with Gemma model download progress
- [ ] Home screen shell with navigation

### Phase 2 — BLE Mesh Chat (Hour 6–14)
- [ ] BLE peripheral: advertise Tasuke GATT service
- [ ] BLE central: scan + connect to nearby Tasuke devices
- [ ] Send/receive messages over BLE characteristic
- [ ] Seen message ID deduplication (prevent rebroadcast loops)
- [ ] Save messages to Hive
- [ ] Chat screen UI with message bubbles
- [ ] **Milestone: 2 phones chatting on airplane mode ✅**

### Phase 3 — SOS + Voice + Camera (Hour 14–22)
- [ ] SOS keyword scoring on every received message
- [ ] SOS banner UI (red, full-width, undismissable)
- [ ] Vibration on SOS received
- [ ] Voice input button → speech_to_text → send as message
- [ ] Camera screen → ML Kit image labeling (offline)
- [ ] Offline triage result card from label mapping
- [ ] **Milestone: SOS fires on keyword. Photo → offline triage card ✅**

### Phase 4 — On-Device LLM Assistant (Hour 22–28)
- [ ] LLM service initialized with Gemma 3 1B
- [ ] System prompt loaded from assets
- [ ] Assistant screen with chat UI
- [ ] Streaming token response displayed
- [ ] Example questions pre-loaded as quick-tap suggestions
- [ ] **Milestone: Ask first aid question → LLM answers offline ✅**

### Phase 5 — Sync + Alerts (Hour 28–34)
- [ ] Firebase project setup + Firestore security rules
- [ ] Connectivity monitoring service
- [ ] Upload queued messages when internet detected
- [ ] J-Alert XML fetch + parse + DeepL translation
- [ ] Alerts screen with language toggle (🇯🇵 🇺🇸)
- [ ] Cache alerts in Hive for offline reading
- [ ] **Milestone: Come online → messages sync → translated alert appears ✅**

### Phase 6 — Map (Hour 34–40)
- [ ] flutter_map setup with OpenStreetMap tiles
- [ ] Load tokyo_shelters.json → shelter markers
- [ ] Layer toggles: shelters | food/water | danger zones
- [ ] Report danger zone at current location (FAB)
- [ ] Pre-cache Tokyo map tiles on install
- [ ] Distance to nearest shelter displayed
- [ ] **Milestone: Offline map with shelters + reported dangers ✅**

### Phase 7 — Polish + Demo Prep (Hour 40–48)
- [ ] Home screen: live mesh status, connected devices count
- [ ] Home screen: last sync time, SOS active indicator
- [ ] Gemini Vision integration (online image triage upgrade)
- [ ] Test full demo flow on both Android devices
- [ ] Fix crashes + edge cases
- [ ] Rehearse 2-minute demo script
- [ ] **Milestone: Clean demo flow on 2 devices ✅**

---

## Demo Script (2 Minutes)

**Setup:** 2 Android phones. Phone A + B start on airplane mode.

**Beat 1 — Mesh works without internet**
> "Earthquake hits Tokyo. Cell towers are down."
> → Both phones on airplane mode
> → Send message A → B → appears instantly via BLE ✅

**Beat 2 — SOS Detection**
> "A survivor nearby types for help."
> → Type "助けて" on Phone B
> → Red SOS banner fires on Phone A with vibration ✅

**Beat 3 — Voice Input**
> "They're injured and can't type."
> → Hold voice button → speak "I need help, there is fire"
> → Transcribed + sent + SOS triggers ✅

**Beat 4 — AI Triage (Camera)**
> "They photograph the damage."
> → Take photo of mock injury / damage
> → Offline ML Kit: labels appear (fire, injury, smoke)
> → Triage card: severity + action ✅

**Beat 5 — On-Device LLM**
> "No internet. They need first aid guidance."
> → Open AI Assistant
> → Ask: "I have a deep cut, what do I do?"
> → Gemma answers offline, streamed in real-time ✅

**Beat 6 — Back Online**
> "Phone B finds WiFi. It bridges the mesh to the world."
> → Turn on WiFi on Phone B
> → All queued messages sync to Firebase dashboard
> → Translated J-Alert appears on screen ✅

**Beat 7 — Map**
> "Where is the nearest shelter?"
> → Open map → Tokyo shelter markers
> → Works offline — pre-cached tiles ✅

---

## Environment Variables

```
# .env (do not commit — use flutter_dotenv)
FIREBASE_PROJECT_ID=tasuke-hackathon
DEEPL_API_KEY=your_key_here
GEMINI_API_KEY=your_key_here
JALERT_API_ENDPOINT=https://www.data.jma.go.jp/developer/xml/feed/eqvol.xml
```

---

## Key Constraints + Honest Notes

- **BLE background on Android:** Works but may throttle — keep app in foreground for demo
- **Gemma model download:** ~1GB — pre-download on both phones before demo day
- **BLE range:** ~10-30 meters indoors — demo devices should be in same room
- **BLE MTU:** Max ~512 bytes per packet — images must be chunked (handle in BLE service)
- **Multi-hop:** Implemented as 1-hop rebroadcast for demo reliability
- **J-Alert API:** May need mock data as fallback — prepare sample XML response
- **ML Kit models:** Auto-downloaded on first use — run app once with internet before demo

---

## Pre-Demo Checklist

```
Night before demo:
  [ ] Both APKs installed on both phones
  [ ] Gemma 3 1B model downloaded on both phones
  [ ] ML Kit models initialized (open camera once on each phone)
  [ ] Tokyo map tiles pre-cached (open map once with internet)
  [ ] Firebase project live + Firestore rules deployed
  [ ] DeepL + Gemini API keys working
  [ ] Both phones charged to 100%
  [ ] Demo script rehearsed x3
  [ ] Mock injury photo ready in camera roll
  [ ] Airplane mode tested — BLE chat confirmed working
```

---

## Resources

| Resource | URL |
|---|---|
| flutter_blue_plus | https://pub.dev/packages/flutter_blue_plus |
| flutter_gemma | https://pub.dev/packages/flutter_gemma |
| Google ML Kit Flutter | https://pub.dev/packages/google_mlkit_image_labeling |
| flutter_map | https://pub.dev/packages/flutter_map |
| J-Alert JMA XML | https://www.data.jma.go.jp/developer/xml/feed/ |
| Tokyo Shelter Data | https://catalog.data.metro.tokyo.lg.jp |
| DeepL API | https://www.deepl.com/pro-api |
| Gemini API | https://ai.google.dev |

---

*Built for IMPACT TOKYO Hackathon — Track 2: Smart Cities & Urban Resilience*
*"When infrastructure fails, people shouldn't."*