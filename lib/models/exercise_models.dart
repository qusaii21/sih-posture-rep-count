import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:final_sai/models/analysis_models.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';



/// Data class for exercise session
class ExerciseSession {
  final String exerciseType;
  final DateTime startTime;
  final List<PoseData> poseDataList;
  int repCount;

  ExerciseSession({
    required this.exerciseType,
    required this.startTime,
    required this.poseDataList,
    this.repCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseType': exerciseType,
      'startTime': startTime.toIso8601String(),
      'totalReps': repCount,
      'duration': poseDataList.isNotEmpty
          ? poseDataList.last.timestamp.difference(startTime).inMilliseconds
          : 0,
      'poseData': poseDataList.map((pose) => pose.toJson()).toList(),
    };
  }
}

/// Data class for individual pose measurements
class PoseData {
  final DateTime timestamp;
  final Map<String, JointAngle> angles;
  final Map<String, Point> landmarks;
  final bool isUpPosition;
  final String status;
  final PostureAnalysis? postureAnalysis; // Added posture analysis

  PoseData({
    required this.timestamp,
    required this.angles,
    required this.landmarks,
    required this.isUpPosition,
    required this.status,
    this.postureAnalysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'isUpPosition': isUpPosition,
      'status': status,
      'angles': angles.map((key, value) => MapEntry(key, value.toJson())),
      'landmarks': landmarks.map((key, value) => MapEntry(key, value.toJson())),
      if (postureAnalysis != null) 'postureAnalysis': postureAnalysis!.toJson(),
    };
  }
}

/// Joint angle data
class JointAngle {
  final double degrees;
  final String jointName;
  final List<String> involvedLandmarks;

  JointAngle({
    required this.degrees,
    required this.jointName,
    required this.involvedLandmarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'degrees': degrees,
      'jointName': jointName,
      'involvedLandmarks': involvedLandmarks,
    };
  }
}

/// Point data for landmarks
class Point {
  final double x;
  final double y;
  final double? visibility;

  Point({required this.x, required this.y, this.visibility});

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      if (visibility != null) 'visibility': visibility,
    };
  }
}



/// Enum for exercises
enum ExerciseType { armRaises, pushUps, squats, sitUps,}



