# PoseMuse 📸✨
### AI Photographer Assistant & Real-Time Pose Director

**PoseMuse** is an intelligent photographer assistant built in Flutter (Dart) powered by Cloud Vision AI (Anthropic Claude) and on-device multi-person pose tracking. 

The user points their camera at any setting with one or more people and taps **"Get Ideas"**. The app captures a snapshot, analyzes the physical surroundings, lighting, people, outfits, and props, and generates **5–6 fresh, achievable photo ideas crafted specifically for that scene**. When the user picks an idea, PoseMuse projects semi-transparent ghost skeletons, coaches each subject into position with real-time feedback and voice tips, and triggers auto-capture when the alignment reaches 85%+.

> **No Fixed Pose Library • No Template Engine**  
> Every idea is generated fresh on the fly by the Cloud Vision AI for every unique scan.

---

## 🌟 Core Flow

1. **SCAN**: Tap *"Get Ideas"*. The app takes a snapshot, downsizes it to max 768px on the long side (JPEG ~70%), and transmits it to the backend.
2. **ANALYZE & GENERATE (Cloud Vision AI)**:
   - Evaluates: location type, lighting direction/quality, subject count & placement, outfits & colors, props (stairs, railings, walls, benches, trees), and negative space.
   - Generates 5–6 unique photo ideas with photographer camera direction (height, angle, distance, orientation), expression tips, and **17 COCO normalized keypoints per person**.
3. **CHOOSE**: Ideas slide up as swipeable cards displaying title, *"why this works here"*, camera tips, difficulty pill, and a mini skeleton preview.
4. **COACH (On-Device)**: Ghost skeletons overlay the live camera feed. Multi-person tracking matches subjects to their target positions (handling spatial swaps automatically) and provides visual and voice hints (e.g. *"Raise your left elbow"*).
5. **CAPTURE**: Auto-capture triggers when the match holds at ≥85% for 1 second continuously, or users can tap manual shutter with an optional **Burst of 3**.
6. **REVIEW & LEARN**: Users rate ideas (Thumbs Up / Down). Liked/disliked titles are saved locally in Hive and sent in subsequent scan requests so the AI learns user taste over time!

---

## 🔒 Security & Privacy Architecture

- **API Key Secrecy**: The mobile app **NEVER** contains the AI API key. All Claude Vision API calls go through the serverless backend in [`functions/`](file:///a:/guit%20hub%20cloned%20files/poseai/pose_muse/functions).
- **Zero Image Retention**: Snapshots are processed strictly in-memory by the backend and discarded immediately after generation. No user images or biometric landmarks are ever stored in the cloud.
- **Privacy Notice**: Displayed transparently to users during onboarding:  
  *“Your snapshot is sent securely to AI to create ideas and is not stored.”*

---

## 📂 Project Architecture

```
pose_muse/
├── functions/                         # Cloud Vision AI Backend (Node.js/TypeScript)
│   ├── package.json
│   ├── tsconfig.json
│   ├── .env.example                   # Environment configuration (ANTHROPIC_API_KEY)
│   └── src/
│       ├── index.ts                   # Express server with POST /generate-ideas
│       ├── claude_service.ts          # Anthropic Claude Vision API caller with 15s timeout & retry
│       ├── validator.ts               # Zod response validation & bone ratio sanity check
│       ├── rate_limiter.ts            # Anonymous user rate limiter (30 scans/day)
│       └── validator.test.ts          # Unit tests for schema validation
├── prompt/
│   ├── ai_prompt.md                   # Full AI system prompt for the Vision model
│   └── idea_schema.json               # JSON schema for 5-6 structured photo ideas
├── pubspec.yaml                       # Flutter dependencies (Dio, Connectivity, Camera, Hive, Riverpod)
├── lib/
│   ├── main.dart                      # App entrypoint, Hive init, ProviderScope
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Neon Mint & Dark aesthetics
│   │   │   ├── app_constants.dart     # Backend URLs & thresholds
│   │   │   └── coco_landmarks.dart    # 17 COCO landmark indices & skeleton bones
│   │   ├── utils/
│   │   │   ├── angle_calculator.dart  # Pure Dart vector dot product & joint angles
│   │   │   ├── image_downsampler.dart # Downsamples to max 768px JPEG 70%
│   │   │   ├── voice_coach_service.dart # Spoken voice hints (TTS)
│   │   │   └── haptic_service.dart    # Milestone haptic feedback
│   │   ├── widgets/
│   │   │   ├── animated_score_badge.dart
│   │   │   ├── glass_container.dart
│   │   │   └── grid_overlay.dart
│   │   └── router/app_router.dart     # GoRouter navigation
│   └── features/
│       ├── ideas/                     # Fresh AI idea generation feature
│       │   ├── data/ideas_api_service.dart   # Dio client with offline check
│       │   ├── domain/photo_idea.dart        # PhotoIdea & SceneAnalysis models
│       │   └── presentation/
│       │       ├── ideas_view_model.dart     # StateNotifier with rotating thoughts
│       │       └── widgets/
│       │           ├── scan_loading_overlay.dart # Laser sweep & rotating thoughts
│       │           ├── idea_card.dart            # Swipeable card with thumbs up/down
│       │           └── idea_detail_sheet.dart    # Full camera tips & start coaching CTA
│       ├── coaching/                  # Live multi-person pose coaching
│       │   ├── data/pose_tracker.dart        # Multi-person pose inference (~15 FPS)
│       │   ├── domain/pose_matcher.dart      # COCO 17 angle matching & group score
│       │   ├── domain/person_assigner.dart   # Bipartite spatial matcher (auto swaps)
│       │   └── presentation/
│       │       ├── coaching_screen.dart      # Viewfinder, ghost guides, score pill
│       │       ├── coaching_view_model.dart  # Stream listener & auto-capture logic
│       │       └── widgets/
│       │           └── multi_person_skeleton_painter.dart # CustomPainter overlay
│       ├── camera/                    # Main camera viewfinder & Get Ideas action
│       ├── gallery/                   # Gallery with idea metadata & sharing
│       ├── onboarding/                # 3-step walkthrough & clear privacy notice
│       └── settings/                  # Style preferences, voice hints, dark mode
└── test/
    ├── angle_calculator_test.dart     # Vector angle calculations unit tests
    ├── pose_matcher_test.dart         # COCO 17 scale-invariance & hints tests
    └── person_assigner_test.dart      # Multi-person assignment & swap tests
```

---

## 🚀 Setup & Run Instructions

### 1. Backend Setup (`functions/`)

1. Navigate to the backend directory:
   ```bash
   cd pose_muse/functions
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create your `.env` file with your Anthropic Claude API key:
   ```bash
   cp .env.example .env
   # Open .env and insert your ANTHROPIC_API_KEY
   ```
4. Build and start the backend:
   ```bash
   npm run build
   npm start
   ```
   The server will listen at `http://localhost:8080`.

5. Run backend unit tests:
   ```bash
   npm test
   ```

---

### 2. Mobile App Setup (`pose_muse/`)

1. Navigate to the Flutter app directory:
   ```bash
   cd pose_muse
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run unit tests (testing PoseMatcher scale invariance, AngleCalculator, and PersonAssigner):
   ```bash
   flutter test
   ```
4. Run on a connected Android/iOS device or emulator:
   ```bash
   flutter run
   ```
   *(Note: Android Emulator automatically connects to `http://10.0.2.2:8080` to communicate with the local backend).*

---

## 📦 Building for Production

### Android
```bash
# Debug APK
flutter build apk --debug

# Optimized Release APK
flutter build apk --release

# Google Play App Bundle (.aab)
flutter build appbundle --release
```

### iOS
```bash
cd ios
pod install
cd ..
flutter build ios --release --no-codesign
```
Open `ios/Runner.xcworkspace` in Xcode to configure your signing identity and archive for App Store / TestFlight distribution.

---

## 🧮 Mathematical Pose Matching & Multi-Person Logic

### Joint-Angle Invariance
The `PoseMatcher` computes relative joint angles for elbows, shoulders, hips, and knees:
$$\cos(\theta) = \frac{\vec{BA} \cdot \vec{BC}}{\|\vec{BA}\| \|\vec{BC}\|}, \quad \theta = \arccos(\text{clamp}(\cos(\theta), -1.0, 1.0)) \times \frac{180^\circ}{\pi}$$
Because it relies on joint vertices rather than pixel distances, the match score is **100% scale and distance invariant**—a person standing 2 meters or 5 meters from the camera receives the exact same score.

### PersonAssigner (Swap Recovery)
`PersonAssigner` calculates the centroid of all detected people and matches them to targets (Left, Center, Right) using bipartite cost minimization. If two subjects walk past each other and swap positions, the assigner re-maps them automatically so their target ghost skeletons follow them across the viewfinder.
