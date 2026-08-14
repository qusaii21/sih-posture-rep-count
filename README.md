# SAI Talent Scout

SAI Talent Scout is a Flutter-based computer vision application for real-time sports posture analysis and rep counting. It uses the device camera together with Google ML Kit pose detection to track body landmarks, estimate joint angles, and provide feedback on exercise form.

## Computer Vision Focus

This project is a good fit for a computer vision portfolio because it demonstrates practical vision-based inference in a mobile app:

- Real-time camera capture and frame processing
- Human pose estimation with body landmark detection
- Joint angle calculation from detected landmarks
- Rule-based posture assessment for exercise quality
- Visual overlay of pose skeletons on live video
- Face detection support through ML Kit packages already included in the app

The core workflow is:

1. Capture live video from the camera.
2. Detect body pose landmarks using ML Kit.
3. Convert landmarks into joint angles.
4. Evaluate posture and classify movement quality.
5. Render pose feedback on top of the camera preview.

## Why This Is Relevant for a Computer Vision Role

This project is useful to showcase on a computer vision resume because it shows that you can:

- Integrate a vision model into a production-style mobile app
- Work with real-time inference constraints
- Transform raw detections into meaningful biomechanics metrics
- Build feedback systems on top of CV outputs
- Combine camera input, pose estimation, and UI visualization into one pipeline

If you are applying for a computer vision, ML, or applied AI role, this project is stronger than a typical Flutter app because the main product value comes from vision-based analysis rather than static UI.

## Features

- Live camera preview
- Pose landmark detection
- Exercise posture analysis
- Rep/form feedback for supported movements
- Pose skeleton rendering overlay
- Multi-screen Flutter UI with splash and workout flow
- Asset-backed video and media support

## Tech Stack

- Flutter
- Dart
- `camera`
- `google_mlkit_pose_detection`
- `google_mlkit_commons`
- `google_mlkit_face_detection`
- `video_player`

## Project Structure

- `lib/main.dart` - app entry point and camera initialization
- `lib/services/pose_detection_service.dart` - pose landmark rendering
- `lib/services/pose_analysis_service.dart` - posture scoring and feedback logic
- `lib/models/` - analysis and exercise data models
- `lib/screens/` - app screens and user flows
- `assets/videos/` - media assets used by the app

## How It Works

The app starts by loading available cameras, then passes them into the main Flutter app. From there, the pose detection service draws landmarks and body connections, while the analysis service evaluates angles such as elbows and knees to judge exercise form.

The posture engine currently supports rule-based analysis for exercises such as:

- Arm raises
- Push-ups
- Squats
- Sit-ups

## Getting Started

### Prerequisites

- Flutter SDK
- Android Studio or Xcode, depending on the target platform
- A physical device with a camera for the best real-time vision experience

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
flutter run
```

## Notes

- This app is best demonstrated on a real device because it depends on live camera input.
- For a computer vision role, highlight the pose estimation pipeline, angle-based analysis, and real-time overlay rendering in your resume or portfolio.

## Flutter Reference

For general Flutter help, see the official documentation:

- [Flutter documentation](https://docs.flutter.dev/)
- [Flutter cookbook](https://docs.flutter.dev/cookbook)
