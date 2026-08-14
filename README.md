# VisionFit - Real-Time Pose Analysis & Exercise Tracking

VisionFit is a Flutter-based real-time computer vision application for human pose estimation, exercise tracking, and movement analysis. Using the device camera and Google ML Kit's pose detection capabilities, the application detects body landmarks, derives joint angles, analyzes movement patterns, counts repetitions, and provides visual feedback on exercise form.



https://github.com/user-attachments/assets/e3a946d6-c8da-461d-843b-65b8808c8d6d



## Overview

The application processes live camera frames to build a real-time human pose analysis pipeline:

1. Capture live video from the device camera.
2. Process camera frames for pose estimation.
3. Detect and track human body landmarks.
4. Calculate geometric features such as joint angles.
5. Analyze movement and exercise form using rule-based logic.
6. Render detected landmarks and feedback over the live camera preview.

This creates an end-to-end pipeline from raw visual input to structured movement analysis and user feedback.

## Features

* Real-time camera capture and frame processing
* Human pose landmark detection
* Body skeleton visualization
* Joint angle estimation
* Exercise movement analysis
* Repetition counting
* Rule-based posture and form evaluation
* Real-time visual feedback
* Support for multiple exercise movements
* Face detection support through Google ML Kit
* Flutter-based interactive workout interface
* Video and media asset support

## Supported Exercises

The current posture analysis pipeline includes rule-based analysis for:

* Arm Raises
* Push-ups
* Squats
* Sit-ups

Each exercise uses detected body landmarks and calculated joint angles to evaluate movement states and determine repetitions or form-related feedback.

## Vision Pipeline

```text
Camera Input
     ↓
Frame Processing
     ↓
Pose Detection
     ↓
Body Landmarks
     ↓
Geometric Analysis
     ↓
Joint Angle Calculation
     ↓
Movement / Posture Classification
     ↓
Rep Counting & Feedback
     ↓
Visual Overlay
```

The system uses body landmark coordinates as the primary representation for movement analysis. Joint angles are calculated from relevant landmark points and used as features for determining exercise states and posture quality.

## Tech Stack

* **Flutter**
* **Dart**
* **Google ML Kit Pose Detection**
* **Google ML Kit Face Detection**
* **Camera API**
* **Video Player**

### Key Packages

```yaml
camera
google_mlkit_pose_detection
google_mlkit_commons
google_mlkit_face_detection
video_player
```

## Project Structure

```text
lib/
├── main.dart
├── models/
│   └── ...
├── screens/
│   └── ...
└── services/
    ├── pose_detection_service.dart
    └── pose_analysis_service.dart

assets/
└── videos/
```

### Core Components

* `lib/main.dart`
  Application entry point, camera initialization, and application setup.

* `lib/services/pose_detection_service.dart`
  Handles pose landmark processing and visualization of the detected body skeleton.

* `lib/services/pose_analysis_service.dart`
  Performs movement analysis, joint-angle calculations, posture evaluation, and exercise-specific logic.

* `lib/models/`
  Contains data structures used for exercise and movement analysis.

* `lib/screens/`
  Contains the application's UI screens and workout flows.

* `assets/videos/`
  Contains video and other media assets used within the application.

## How It Works

The application initializes the available device cameras and uses the selected camera as the visual input stream.

Each frame is processed through the pose detection pipeline. The detected landmarks provide coordinates for key body joints such as the shoulders, elbows, hips, knees, and ankles.

These landmarks are then used to derive geometric measurements, including joint angles:

```text
Body Landmarks
      ↓
Landmark Coordinates
      ↓
Joint Geometry
      ↓
Angle Calculation
      ↓
Movement State
      ↓
Exercise Analysis
```

For example, elbow and knee angles can be used to identify different stages of movements such as push-ups and squats. Consecutive movement states can then be used to estimate repetitions and provide feedback.

## Real-Time Visualization

Detected landmarks and skeletal connections are rendered directly over the camera preview, allowing the user to observe the pose estimation results while performing an exercise.

This provides a visual representation of the intermediate output of the pose estimation pipeline rather than treating the model as a black-box prediction system.

## Getting Started

### Prerequisites

* Flutter SDK
* Android Studio or Xcode
* Android/iOS device with a camera
* Physical device recommended for real-time camera processing

### Clone the Repository

```bash
git clone <repository-url>
cd <project-directory>
```

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
flutter run
```

## Notes

* The application relies on live camera input and is best tested on a physical device.
* Real-time performance may vary depending on the device hardware and camera configuration.
* Pose detection and analysis are performed as part of the live camera processing pipeline.
