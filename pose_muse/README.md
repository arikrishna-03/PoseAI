# PoseMuse 📸✨
### AI Photo Pose Director (Flutter & On-Device ML)

**PoseMuse** is a cross-platform mobile application built in Flutter (Dart) designed to revolutionize photo taking. It provides real-time, on-device pose guidance for portraits, couples, and group photos. The app projects a semi-transparent "ghost" skeleton guide onto the live camera stream, matches the subject's posture in real-time, provides spoken/text hints, and automatically triggers the shutter when the target pose alignment hits 85%+.

---

## 🌟 Core Features

- **40+ Curated Poses**: Stored in offline JSON format across 6 categories:
  - *Solo Portrait*, *Standing*, *Sitting*, *Candid*, *Couple (2 people)*, and *Group (3+ people)*.
- **Smart Person-Count Recommendations**:
  - Automatically identifies whether 1, 2, or 3+ subjects are in frame and highlights relevant poses (e.g. suggests romantic couple poses when two people enter view).
- **Semi-Transparent Ghost Overlay**:
  - Displays the target pose skeleton faintly over the camera viewfinder as a visual reference guide.
- **Dynamic Real-Time Skeleton Feedback**:
  - CustomPainter draws the user's detected 33 MediaPipe landmarks with glowing joints and dynamic color-coded feedback:
    - 🔴 **Red (<55%)**: Initial positioning / off-pose
    - 🟡 **Yellow (55% - 84%)**: Getting close, adjust limbs
    - 🟢 **Neon Mint (≥85%)**: Target reached!
- **Actionable Posing Hints**:
  - Directional guidance such as *"Raise your left elbow"*, *"Straighten left leg"*, or *"Stand up straighter"*.
- **Hands-Free Auto-Capture**:
  - When the user holds the target pose at ≥85% match for 1.0 second, PoseMuse initiates an animated countdown and automatically snaps the photo.
- **Local Gallery**:
  - View saved guided photos with timestamp, matching pose name, and alignment percentage. Share directly or delete.
- **100% Offline & Private**:
  - Zero cloud dependencies. MediaPipe Pose detection runs entirely on-device hardware. No biometric data or video streams ever leave the phone.

---

## 🏗️ Architecture & Folder Structure

Built using **feature-first clean architecture** with Riverpod state management:

```
pose_muse/
├── pubspec.yaml                       # Dependencies & assets declaration
├── analysis_options.yaml              # Linting rules
├── README.md                          # Documentation & build instructions
├── assets/
│   ├── poses/
│   │   └── poses.json                 # 49 Curated poses with 33-point landmarks
│   └── icons/                         # App & category icons
├── android/
│   └── app/src/main/AndroidManifest.xml # Camera, storage & vibration permissions
├── ios/
│   └── Runner/Info.plist              # Camera & photo library privacy usage keys
├── lib/
│   ├── main.dart                      # App entrypoint, Hive init, ProviderScope
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart        # Photo-first neon dark aesthetic
│   │   │   ├── app_constants.dart     # Storage keys & ML thresholds
│   │   │   └── mediapipe_landmarks.dart # 33 Landmark indices & bone pairs
│   │   ├── theme/
│   │   │   └── app_theme.dart         # Material 3 dark & light themes
│   │   ├── utils/
│   │   │   ├── angle_calculator.dart  # Pure Dart vector math & joint angles
│   │   │   ├── haptic_service.dart    # Tactile feedback on milestone matches
│   │   │   └── image_converter.dart   # CameraImage to InputImage conversion
│   │   ├── widgets/
│   │   │   ├── animated_score_badge.dart # Match score pill
│   │   │   ├── glass_container.dart   # Frosted glass BackdropFilter container
│   │   │   └── grid_overlay.dart      # Rule of thirds photography grid
│   │   └── router/
│   │       └── app_router.dart        # GoRouter navigation
│   └── features/
│       ├── camera/
│       │   ├── data/pose_detector_service.dart   # Throttled ML stream (~15 FPS)
│       │   ├── domain/match_result.dart          # MatchResult & JointAngleMatch
│       │   ├── domain/pose_matcher.dart          # Scale-invariant similarity engine
│       │   └── presentation/
│       │       ├── camera_screen.dart            # Live viewfinder & overlays
│       │       ├── camera_view_model.dart        # Riverpod controller & capture logic
│       │       └── widgets/
│       │           ├── camera_control_bar.dart   # Shutter & auto-capture ring
│       │           ├── camera_top_bar.dart       # Flash, timer, grid, settings
│       │           ├── hint_banner.dart          # Actionable tip banner
│       │           ├── pose_skeleton_painter.dart # CustomPainter overlay
│       │           └── score_circular_indicator.dart # Circular progress ring
│       ├── poses/
│       │   ├── data/
│       │   │   ├── pose_repository.dart          # JSON loading & multi-filter search
│       │   │   └── pose_storage_service.dart     # Hive favorites & recents
│       │   ├── domain/
│       │   │   ├── pose_category.dart            # Category enum & labels
│       │   │   └── pose_model.dart               # PoseModel & TargetAngles
│       │   └── presentation/
│       │       ├── pose_picker_sheet.dart        # Bottom sheet modal with grid
│       │       └── pose_view_model.dart          # Riverpod pose selection state
│       ├── gallery/
│       │   ├── data/gallery_repository.dart      # Hive photo metadata manager
│       │   ├── domain/captured_photo.dart        # Captured photo record
│       │   └── presentation/
│       │       ├── gallery_screen.dart           # Grid gallery view
│       │       └── photo_view_screen.dart        # Fullscreen viewer with share/delete
│       ├── onboarding/
│       │   └── presentation/
│       │       ├── onboarding_screen.dart        # 3-step walkthrough
│       │       └── permission_screen.dart        # Camera & storage rationale
│       └── settings/
│           ├── domain/settings_state.dart        # Preferences state model
│           └── presentation/
│               ├── settings_screen.dart          # Settings switches & slider
│               └── settings_view_model.dart      # Riverpod preferences notifier
└── test/
    ├── angle_calculator_test.dart             # Pure Dart math unit tests
    └── pose_matcher_test.dart                 # Pose similarity & scale invariance tests
```

---

## 🧮 How the Pose Matching Engine Works

The `PoseMatcher` computes relative joint angles between 3 adjacent landmark vertices:
- **Left/Right Elbows**: `Angle(Shoulder, Elbow, Wrist)`
- **Left/Right Shoulders**: `Angle(Elbow, Shoulder, Hip)`
- **Left/Right Hips**: `Angle(Shoulder, Hip, Knee)`
- **Left/Right Knees**: `Angle(Hip, Knee, Ankle)`

$$\cos(\theta) = \frac{\vec{BA} \cdot \vec{BC}}{\|\vec{BA}\| \|\vec{BC}\|}, \quad \theta = \arccos(\text{clamp}(\cos(\theta), -1.0, 1.0)) \times \frac{180^\circ}{\pi}$$

### Why this is Scale & Distance Invariant:
Because similarity is computed using **internal joint angles** rather than absolute pixel distances, the match score remains consistent whether the person is standing close to the camera or far away.

---

## 🚀 Setup & Installation Instructions

### Prerequisites
- **Flutter SDK**: 3.19.0 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.3.0 or higher
- **Android**: Android Studio with Android SDK API 34, Min SDK 21
- **iOS**: macOS with Xcode 15+ and CocoaPods

### 1. Clone & Navigate
```bash
git clone https://github.com/arikrishna-03/PoseAI.git
cd poseai/pose_muse
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Unit Tests
Verify mathematical angle calculations, scale invariance, and directional hints:
```bash
flutter test
```

### 4. Run on Connected Device
```bash
flutter run
```

---

## 📦 Production Build Instructions

### Android Build

#### 1. Generate Debug APK
```bash
flutter build apk --debug
```
The output APK will be located at `build/app/outputs/flutter-apk/app-debug.apk`.

#### 2. Generate Release APK
```bash
flutter build apk --release
```
The optimized split or fat APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

#### 3. Generate Android App Bundle (.aab) for Google Play
```bash
flutter build appbundle --release
```
The output AAB will be at `build/app/outputs/bundle/release/app-release.aab`.

---

### iOS Build

#### 1. Install CocoaPods
```bash
cd ios
pod install
cd ..
```

#### 2. Build iOS Release Bundle
```bash
flutter build ios --release --no-codesign
```

#### 3. Create IPA Archive (via Xcode)
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select your development team under **Runner > Signing & Capabilities**.
3. Select target **Any iOS Device (arm64)**.
4. Go to **Product > Archive**.
5. Once the archive completes, click **Distribute App** to export an `.ipa` for TestFlight or Ad-Hoc distribution.

---

## 🔒 Privacy & Permissions

- **`android.permission.CAMERA` / `NSCameraUsageDescription`**:
  Required strictly for the live camera viewfinder and real-time landmark detection.
- **`android.permission.READ_MEDIA_IMAGES` / `NSPhotoLibraryAddUsageDescription`**:
  Required to save your captured guided photos directly to device storage.
- No network requests are made.
