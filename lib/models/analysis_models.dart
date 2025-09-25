import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';



/// Posture analysis result
class PostureAnalysis {
  final bool isCorrectPosture;
  final List<PostureFeedback> feedback;
  final double overallScore; // 0-100
  final Map<String, double> jointScores;

  PostureAnalysis({
    required this.isCorrectPosture,
    required this.feedback,
    required this.overallScore,
    required this.jointScores,
  });

  Map<String, dynamic> toJson() {
    return {
      'isCorrectPosture': isCorrectPosture,
      'overallScore': overallScore,
      'jointScores': jointScores,
      'feedback': feedback.map((f) => f.toJson()).toList(),
    };
  }
}

/// Individual feedback item
class PostureFeedback {
  final String joint;
  final String issue;
  final String suggestion;
  final PostureSeverity severity;
  final double currentAngle;
  final double recommendedAngleMin;
  final double recommendedAngleMax;

  PostureFeedback({
    required this.joint,
    required this.issue,
    required this.suggestion,
    required this.severity,
    required this.currentAngle,
    required this.recommendedAngleMin,
    required this.recommendedAngleMax,
  });

  Map<String, dynamic> toJson() {
    return {
      'joint': joint,
      'issue': issue,
      'suggestion': suggestion,
      'severity': severity.name,
      'currentAngle': currentAngle,
      'recommendedAngleRange': '${recommendedAngleMin.toInt()}°-${recommendedAngleMax.toInt()}°',
    };
  }
}

enum PostureSeverity { good, minor, moderate, severe }

/// Session analysis result
class SessionAnalysis {
  final int totalReps;
  final int correctReps;
  final double averageScore;
  final Map<String, int> commonIssues;
  final List<String> recommendations;
  final Map<String, double> jointConsistency;

  SessionAnalysis({
    required this.totalReps,
    required this.correctReps,
    required this.averageScore,
    required this.commonIssues,
    required this.recommendations,
    required this.jointConsistency,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalReps': totalReps,
      'correctReps': correctReps,
      'accuracy': totalReps > 0 ? (correctReps / totalReps * 100).toStringAsFixed(1) : '0.0',
      'averageScore': averageScore.toStringAsFixed(1),
      'commonIssues': commonIssues,
      'recommendations': recommendations,
      'jointConsistency': jointConsistency.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(1)))),
    };
  }
}

