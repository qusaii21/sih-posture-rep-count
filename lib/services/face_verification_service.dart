import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Face verification service for exercise authentication
class FaceVerificationService {
  static late FaceDetector _faceDetector;
  static Uint8List? _profileImageBytes;
  static List<double>? _profileFaceEmbedding;
  static bool _isInitialized = false;

  /// Initialize the face verification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableClassification: true,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    await _loadProfileImage();
    _isInitialized = true;
  }

  /// Load profile image from assets and extract face embedding
  static Future<void> _loadProfileImage() async {
  try {
    // Load profile image from assets
    final ByteData data = await rootBundle.load('assets/profile_image.jpg');
    _profileImageBytes = data.buffer.asUint8List();
    
    // For asset images, it's often easier to use InputImage.fromFilePath
    // But since we're loading from assets, we'll use a simpler approach
    
    // Create a temporary file to work with ML Kit
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/temp_profile.jpg');
    await tempFile.writeAsBytes(_profileImageBytes!);
    
    // Create InputImage from file path (this handles format automatically)
    final inputImage = InputImage.fromFilePath(tempFile.path);

    // Extract face embedding from profile image
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      _profileFaceEmbedding = _extractFaceEmbedding(faces.first);
      print('Profile face embedding extracted successfully');
    } else {
      print('No face detected in profile image');
    }
    
    // Clean up temp file
    await tempFile.delete();
  } catch (e) {
    print('Error loading profile image: $e');
  }
}

  /// Extract face embedding (simplified feature vector)
  static List<double> _extractFaceEmbedding(Face face) {
    List<double> features = [];
    
    // Use face landmarks and contours to create a feature vector
    final boundingBox = face.boundingBox;
    
    // Bounding box features (normalized)
    features.addAll([
      boundingBox.left / 1000.0,
      boundingBox.top / 1000.0,
      boundingBox.width / 1000.0,
      boundingBox.height / 1000.0,
    ]);

    // Face landmarks features
    if (face.landmarks.isNotEmpty) {
      for (var landmark in face.landmarks.values) {
        features.addAll([
          landmark!.position.x / 1000.0,
          landmark!.position.y / 1000.0,
        ]);
      }
    }

    // Pad or truncate to fixed size (64 features)
    while (features.length < 64) {
      features.add(0.0);
    }
    if (features.length > 64) {
      features = features.take(64).toList();
    }

    return features;
  }

  /// Calculate similarity between two face embeddings
  static double _calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Verify face in camera image
  static Future<FaceVerificationResult> verifyFace(InputImage inputImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_profileFaceEmbedding == null) {
      return FaceVerificationResult(
        isVerified: false,
        faceCount: 0,
        similarity: 0.0,
        message: 'Profile face not loaded',
      );
    }

    try {
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        return FaceVerificationResult(
          isVerified: false,
          faceCount: 0,
          similarity: 0.0,
          message: 'No face detected',
        );
      }

      if (faces.length > 1) {
        return FaceVerificationResult(
          isVerified: false,
          faceCount: faces.length,
          similarity: 0.0,
          message: 'Multiple people detected. Please exercise alone.',
        );
      }

      // Single face detected, verify against profile
      final currentFaceEmbedding = _extractFaceEmbedding(faces.first);
      final similarity = _calculateSimilarity(_profileFaceEmbedding!, currentFaceEmbedding);
      
      // Threshold for face verification (adjust as needed)
      const double verificationThreshold = 0.7;
      final isVerified = similarity >= verificationThreshold;

      return FaceVerificationResult(
        isVerified: isVerified,
        faceCount: 1,
        similarity: similarity,
        message: isVerified 
            ? 'Face verified successfully'
            : 'Face does not match profile. Please ensure you are the registered user.',
        detectedFace: faces.first,
      );
    } catch (e) {
      return FaceVerificationResult(
        isVerified: false,
        faceCount: 0,
        similarity: 0.0,
        message: 'Face verification error: $e',
      );
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    if (_isInitialized) {
      await _faceDetector.close();
      _isInitialized = false;
    }
  }
}

/// Result of face verification
class FaceVerificationResult {
  final bool isVerified;
  final int faceCount;
  final double similarity;
  final String message;
  final Face? detectedFace;

  FaceVerificationResult({
    required this.isVerified,
    required this.faceCount,
    required this.similarity,
    required this.message,
    this.detectedFace,
  });
}

/// Enhanced pose painter that also shows face verification status
class EnhancedPosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final FaceVerificationResult? faceResult;

  EnhancedPosePainter(this.poses, this.imageSize, this.faceResult);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw pose landmarks
    final posePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      _drawPoseConnections(canvas, pose, posePaint, size);
      pose.landmarks.forEach((type, landmark) {
        final point = Offset(
          landmark.x * size.width / imageSize.width,
          landmark.y * size.height / imageSize.height,
        );
        canvas.drawCircle(point, 4, pointPaint);
      });
    }

    // Draw face verification indicator
    if (faceResult?.detectedFace != null) {
      final face = faceResult!.detectedFace!;
      final rect = Rect.fromLTWH(
        face.boundingBox.left * size.width / imageSize.width,
        face.boundingBox.top * size.height / imageSize.height,
        face.boundingBox.width * size.width / imageSize.width,
        face.boundingBox.height * size.height / imageSize.height,
      );

      final facePaint = Paint()
        ..color = faceResult!.isVerified ? Colors.green : Colors.red
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, facePaint);

      // Draw verification status text
      final textPainter = TextPainter(
        text: TextSpan(
          text: faceResult!.isVerified ? '✓ Verified' : '✗ Unverified',
          style: TextStyle(
            color: faceResult!.isVerified ? Colors.green : Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.left, rect.top - 25),
      );
    }
  }

  void _drawPoseConnections(Canvas canvas, Pose pose, Paint paint, Size size) {
    void draw(PoseLandmarkType a, PoseLandmarkType b) {
      final l1 = pose.landmarks[a];
      final l2 = pose.landmarks[b];
      if (l1 != null && l2 != null) {
        canvas.drawLine(
          Offset(
            l1.x * size.width / imageSize.width,
            l1.y * size.height / imageSize.height,
          ),
          Offset(
            l2.x * size.width / imageSize.width,
            l2.y * size.height / imageSize.height,
          ),
          paint,
        );
      }
    }

    draw(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    draw(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    draw(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    draw(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    draw(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    draw(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    draw(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    draw(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    draw(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    draw(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}