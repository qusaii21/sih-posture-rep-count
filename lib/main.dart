import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Counter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ExerciseSelectionScreen(cameras: cameras),
    );
  }
}

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

/// Rule-based posture analyzer
class PostureRuleEngine {
  static PostureAnalysis analyzePose(ExerciseType exerciseType, Map<String, JointAngle> angles) {
    switch (exerciseType) {
      case ExerciseType.armRaises:
        return _analyzeArmRaises(angles);
      case ExerciseType.pushUps:
        return _analyzePushUps(angles);
      case ExerciseType.squats:
        return _analyzeSquats(angles);
      case ExerciseType.sitUps:
        return _analyzeSitUps(angles);
    }
  }

  static PostureAnalysis _analyzeArmRaises(Map<String, JointAngle> angles) {
    List<PostureFeedback> feedback = [];
    Map<String, double> jointScores = {};
    
    final leftElbowAngle = angles['leftElbow']?.degrees;
    final rightElbowAngle = angles['rightElbow']?.degrees;

    // Analyze left elbow
    if (leftElbowAngle != null) {
      if (leftElbowAngle < 140) {
        feedback.add(PostureFeedback(
          joint: 'Left Elbow',
          issue: 'Elbow too bent (${leftElbowAngle.toInt()}°)',
          suggestion: 'Straighten your left arm more. Keep elbow angle > 140°',
          severity: leftElbowAngle < 120 ? PostureSeverity.severe : PostureSeverity.moderate,
          currentAngle: leftElbowAngle,
          recommendedAngleMin: 140,
          recommendedAngleMax: 180,
        ));
        jointScores['leftElbow'] = max(0, (leftElbowAngle - 90) / 50 * 100);
      } else {
        jointScores['leftElbow'] = 100;
      }
    }

    // Analyze right elbow
    if (rightElbowAngle != null) {
      if (rightElbowAngle < 140) {
        feedback.add(PostureFeedback(
          joint: 'Right Elbow',
          issue: 'Elbow too bent (${rightElbowAngle.toInt()}°)',
          suggestion: 'Straighten your right arm more. Keep elbow angle > 140°',
          severity: rightElbowAngle < 120 ? PostureSeverity.severe : PostureSeverity.moderate,
          currentAngle: rightElbowAngle,
          recommendedAngleMin: 140,
          recommendedAngleMax: 180,
        ));
        jointScores['rightElbow'] = max(0, (rightElbowAngle - 90) / 50 * 100);
      } else {
        jointScores['rightElbow'] = 100;
      }
    }

    // Check arm symmetry
    if (leftElbowAngle != null && rightElbowAngle != null) {
      final difference = (leftElbowAngle - rightElbowAngle).abs();
      if (difference > 20) {
        feedback.add(PostureFeedback(
          joint: 'Arm Symmetry',
          issue: 'Arms not symmetric (${difference.toInt()}° difference)',
          suggestion: 'Keep both arms at the same level and angle',
          severity: difference > 30 ? PostureSeverity.moderate : PostureSeverity.minor,
          currentAngle: difference,
          recommendedAngleMin: 0,
          recommendedAngleMax: 15,
        ));
      }
    }

    final overallScore = jointScores.values.isEmpty ? 0.0 : 
        jointScores.values.reduce((a, b) => a + b) / jointScores.length;
    
    return PostureAnalysis(
      isCorrectPosture: feedback.where((f) => f.severity == PostureSeverity.severe).isEmpty,
      feedback: feedback,
      overallScore: overallScore,
      jointScores: jointScores,
    );
  }

  static PostureAnalysis _analyzePushUps(Map<String, JointAngle> angles) {
    List<PostureFeedback> feedback = [];
    Map<String, double> jointScores = {};
    
    final leftElbowAngle = angles['leftElbow']?.degrees;
    final rightElbowAngle = angles['rightElbow']?.degrees;

    // Analyze left elbow for push-up
    if (leftElbowAngle != null) {
      // Down position: 70-110°, Up position: 150-180°
      double score = 0;
      if (leftElbowAngle >= 70 && leftElbowAngle <= 110) {
        // Good down position
        score = 100;
      } else if (leftElbowAngle >= 150 && leftElbowAngle <= 180) {
        // Good up position
        score = 100;
      } else if (leftElbowAngle > 110 && leftElbowAngle < 150) {
        // Incomplete range of motion
        feedback.add(PostureFeedback(
          joint: 'Left Elbow',
          issue: 'Incomplete range of motion (${leftElbowAngle.toInt()}°)',
          suggestion: 'Go lower (70-110°) or fully extend (150-180°)',
          severity: PostureSeverity.moderate,
          currentAngle: leftElbowAngle,
          recommendedAngleMin: 70,
          recommendedAngleMax: 110,
        ));
        score = 60;
      } else if (leftElbowAngle < 70) {
        feedback.add(PostureFeedback(
          joint: 'Left Elbow',
          issue: 'Going too low (${leftElbowAngle.toInt()}°)',
          suggestion: 'Don\'t go below 70° to protect shoulders',
          severity: PostureSeverity.minor,
          currentAngle: leftElbowAngle,
          recommendedAngleMin: 70,
          recommendedAngleMax: 110,
        ));
        score = 80;
      }
      jointScores['leftElbow'] = score;
    }

    // Similar analysis for right elbow
    if (rightElbowAngle != null) {
      double score = 0;
      if (rightElbowAngle >= 70 && rightElbowAngle <= 110) {
        score = 100;
      } else if (rightElbowAngle >= 150 && rightElbowAngle <= 180) {
        score = 100;
      } else if (rightElbowAngle > 110 && rightElbowAngle < 150) {
        feedback.add(PostureFeedback(
          joint: 'Right Elbow',
          issue: 'Incomplete range of motion (${rightElbowAngle.toInt()}°)',
          suggestion: 'Go lower (70-110°) or fully extend (150-180°)',
          severity: PostureSeverity.moderate,
          currentAngle: rightElbowAngle,
          recommendedAngleMin: 70,
          recommendedAngleMax: 110,
        ));
        score = 60;
      } else if (rightElbowAngle < 70) {
        feedback.add(PostureFeedback(
          joint: 'Right Elbow',
          issue: 'Going too low (${rightElbowAngle.toInt()}°)',
          suggestion: 'Don\'t go below 70° to protect shoulders',
          severity: PostureSeverity.minor,
          currentAngle: rightElbowAngle,
          recommendedAngleMin: 70,
          recommendedAngleMax: 110,
        ));
        score = 80;
      }
      jointScores['rightElbow'] = score;
    }

    final overallScore = jointScores.values.isEmpty ? 0.0 : 
        jointScores.values.reduce((a, b) => a + b) / jointScores.length;
    
    return PostureAnalysis(
      isCorrectPosture: feedback.where((f) => f.severity == PostureSeverity.severe).isEmpty,
      feedback: feedback,
      overallScore: overallScore,
      jointScores: jointScores,
    );
  }

  static PostureAnalysis _analyzeSquats(Map<String, JointAngle> angles) {
    List<PostureFeedback> feedback = [];
    Map<String, double> jointScores = {};
    
    final leftKneeAngle = angles['leftKnee']?.degrees;
    final rightKneeAngle = angles['rightKnee']?.degrees;

    // Analyze left knee
    if (leftKneeAngle != null) {
      double score = 0;
      if (leftKneeAngle >= 80 && leftKneeAngle <= 110) {
        // Good squat depth
        score = 100;
      } else if (leftKneeAngle > 110 && leftKneeAngle < 140) {
        // Partial squat
        feedback.add(PostureFeedback(
          joint: 'Left Knee',
          issue: 'Not deep enough (${leftKneeAngle.toInt()}°)',
          suggestion: 'Squat deeper, aim for 80-110° knee angle',
          severity: PostureSeverity.moderate,
          currentAngle: leftKneeAngle,
          recommendedAngleMin: 80,
          recommendedAngleMax: 110,
        ));
        score = 70;
      } else if (leftKneeAngle >= 140) {
        // Standing/too shallow
        feedback.add(PostureFeedback(
          joint: 'Left Knee',
          issue: 'Too shallow or standing (${leftKneeAngle.toInt()}°)',
          suggestion: 'Bend knees more for proper squat form',
          severity: PostureSeverity.minor,
          currentAngle: leftKneeAngle,
          recommendedAngleMin: 80,
          recommendedAngleMax: 110,
        ));
        score = 40;
      } else if (leftKneeAngle < 80) {
        // Too deep
        feedback.add(PostureFeedback(
          joint: 'Left Knee',
          issue: 'Squatting too deep (${leftKneeAngle.toInt()}°)',
          suggestion: 'Don\'t go below 80° to protect knees',
          severity: PostureSeverity.minor,
          currentAngle: leftKneeAngle,
          recommendedAngleMin: 80,
          recommendedAngleMax: 110,
        ));
        score = 80;
      }
      jointScores['leftKnee'] = score;
    }

    // Similar analysis for right knee
    if (rightKneeAngle != null) {
      double score = 0;
      if (rightKneeAngle >= 80 && rightKneeAngle <= 110) {
        score = 100;
      } else if (rightKneeAngle > 110 && rightKneeAngle < 140) {
        feedback.add(PostureFeedback(
          joint: 'Right Knee',
          issue: 'Not deep enough (${rightKneeAngle.toInt()}°)',
          suggestion: 'Squat deeper, aim for 80-110° knee angle',
          severity: PostureSeverity.moderate,
          currentAngle: rightKneeAngle,
          recommendedAngleMin: 80,
          recommendedAngleMax: 110,
        ));
        score = 70;
      } else if (rightKneeAngle >= 140) {
        feedback.add(PostureFeedback(
          joint: 'Right Knee',
          issue: 'Too shallow or standing (${rightKneeAngle.toInt()}°)',
          suggestion: 'Bend knees more for proper squat form',
          severity: PostureSeverity.minor,
          currentAngle: rightKneeAngle,
          recommendedAngleMin: 80,
          recommendedAngleMax: 110,
        ));
        score = 40;
      } else if (rightKneeAngle < 80) {
        feedback.add(PostureFeedback(
          joint: 'Right Knee',
          issue: 'Squatting too deep (${rightKneeAngle.toInt()}°)',
          suggestion: 'Don\'t go below 80° to protect knees',
          severity: PostureSeverity.minor,
          currentAngle: rightKneeAngle,
          recommendedAngleMin: 80,
          recommendedAngleMax: 110,
        ));
        score = 80;
      }
      jointScores['rightKnee'] = score;
    }

    final overallScore = jointScores.values.isEmpty ? 0.0 : 
        jointScores.values.reduce((a, b) => a + b) / jointScores.length;
    
    return PostureAnalysis(
      isCorrectPosture: feedback.where((f) => f.severity == PostureSeverity.severe).isEmpty,
      feedback: feedback,
      overallScore: overallScore,
      jointScores: jointScores,
    );
  }

  static PostureAnalysis _analyzeSitUps(Map<String, JointAngle> angles) {
    List<PostureFeedback> feedback = [];
    Map<String, double> jointScores = {};
    
    final leftHipAngle = angles['leftHip']?.degrees;
    final rightHipAngle = angles['rightHip']?.degrees;

    // Analyze left hip
    if (leftHipAngle != null) {
      double score = 0;
      if (leftHipAngle >= 30 && leftHipAngle <= 60) {
        // Good sit-up position
        score = 100;
      } else if (leftHipAngle > 60 && leftHipAngle <= 90) {
        // Partial sit-up
        feedback.add(PostureFeedback(
          joint: 'Left Hip',
          issue: 'Not lifting enough (${leftHipAngle.toInt()}°)',
          suggestion: 'Lift torso more, aim for 30-60° hip angle',
          severity: PostureSeverity.moderate,
          currentAngle: leftHipAngle,
          recommendedAngleMin: 30,
          recommendedAngleMax: 60,
        ));
        score = 70;
      } else if (leftHipAngle > 90) {
        // Lying down
        feedback.add(PostureFeedback(
          joint: 'Left Hip',
          issue: 'Not engaging core (${leftHipAngle.toInt()}°)',
          suggestion: 'Lift your torso using core muscles',
          severity: PostureSeverity.minor,
          currentAngle: leftHipAngle,
          recommendedAngleMin: 30,
          recommendedAngleMax: 60,
        ));
        score = 40;
      } else if (leftHipAngle < 30) {
        // Over-extending
        feedback.add(PostureFeedback(
          joint: 'Left Hip',
          issue: 'Lifting too high (${leftHipAngle.toInt()}°)',
          suggestion: 'Don\'t over-extend, 30° is enough',
          severity: PostureSeverity.minor,
          currentAngle: leftHipAngle,
          recommendedAngleMin: 30,
          recommendedAngleMax: 60,
        ));
        score = 80;
      }
      jointScores['leftHip'] = score;
    }

    // Similar analysis for right hip
    if (rightHipAngle != null) {
      double score = 0;
      if (rightHipAngle >= 30 && rightHipAngle <= 60) {
        score = 100;
      } else if (rightHipAngle > 60 && rightHipAngle <= 90) {
        feedback.add(PostureFeedback(
          joint: 'Right Hip',
          issue: 'Not lifting enough (${rightHipAngle.toInt()}°)',
          suggestion: 'Lift torso more, aim for 30-60° hip angle',
          severity: PostureSeverity.moderate,
          currentAngle: rightHipAngle,
          recommendedAngleMin: 30,
          recommendedAngleMax: 60,
        ));
        score = 70;
      } else if (rightHipAngle > 90) {
        feedback.add(PostureFeedback(
          joint: 'Right Hip',
          issue: 'Not engaging core (${rightHipAngle.toInt()}°)',
          suggestion: 'Lift your torso using core muscles',
          severity: PostureSeverity.minor,
          currentAngle: rightHipAngle,
          recommendedAngleMin: 30,
          recommendedAngleMax: 60,
        ));
        score = 40;
      } else if (rightHipAngle < 30) {
        feedback.add(PostureFeedback(
          joint: 'Right Hip',
          issue: 'Lifting too high (${rightHipAngle.toInt()}°)',
          suggestion: 'Don\'t over-extend, 30° is enough',
          severity: PostureSeverity.minor,
          currentAngle: rightHipAngle,
          recommendedAngleMin: 30,
          recommendedAngleMax: 60,
        ));
        score = 80;
      }
      jointScores['rightHip'] = score;
    }

    final overallScore = jointScores.values.isEmpty ? 0.0 : 
        jointScores.values.reduce((a, b) => a + b) / jointScores.length;
    
    return PostureAnalysis(
      isCorrectPosture: feedback.where((f) => f.severity == PostureSeverity.severe).isEmpty,
      feedback: feedback,
      overallScore: overallScore,
      jointScores: jointScores,
    );
  }

  /// Analyze complete session
  static SessionAnalysis analyzeSession(ExerciseSession session) {
    if (session.poseDataList.isEmpty) {
      return SessionAnalysis(
        totalReps: 0,
        correctReps: 0,
        averageScore: 0,
        commonIssues: {},
        recommendations: ['No data recorded'],
        jointConsistency: {},
      );
    }

    Map<String, int> issueCount = {};
    Map<String, List<double>> jointAngles = {};
    List<double> scores = [];
    int correctReps = 0;

    // Process each pose data
    for (var poseData in session.poseDataList) {
      final analysis = PostureRuleEngine.analyzePose(
        ExerciseType.values.firstWhere((e) => e.name == session.exerciseType),
        poseData.angles
      );

      scores.add(analysis.overallScore);
      
      if (analysis.isCorrectPosture) {
        correctReps++;
      }

      // Count issues
      for (var feedback in analysis.feedback) {
        issueCount[feedback.issue] = (issueCount[feedback.issue] ?? 0) + 1;
      }

      // Track joint angle consistency
      for (var entry in poseData.angles.entries) {
        jointAngles.putIfAbsent(entry.key, () => []).add(entry.value.degrees);
      }
    }

    // Calculate joint consistency (lower standard deviation = more consistent)
    Map<String, double> jointConsistency = {};
    for (var entry in jointAngles.entries) {
      if (entry.value.length > 1) {
        final mean = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final variance = entry.value.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / entry.value.length;
        final stdDev = sqrt(variance);
        jointConsistency[entry.key] = max(0, 100 - stdDev); // Convert to consistency score
      }
    }

    // Generate recommendations
    List<String> recommendations = _generateRecommendations(session.exerciseType, issueCount, scores);

    return SessionAnalysis(
      totalReps: session.repCount,
      correctReps: correctReps,
      averageScore: scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length,
      commonIssues: issueCount,
      recommendations: recommendations,
      jointConsistency: jointConsistency,
    );
  }

  static List<String> _generateRecommendations(String exerciseType, Map<String, int> issues, List<double> scores) {
    List<String> recommendations = [];

    // General score-based recommendations
    final avgScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
    
    if (avgScore < 50) {
      recommendations.add('Focus on form over speed. Your average form score is ${avgScore.toInt()}%');
    } else if (avgScore < 75) {
      recommendations.add('Good progress! Work on consistency to improve from ${avgScore.toInt()}%');
    } else {
      recommendations.add('Excellent form! Keep up the great work with ${avgScore.toInt()}% average score');
    }

    // Issue-specific recommendations
    final sortedIssues = issues.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    for (var issue in sortedIssues.take(3)) {
      switch (exerciseType) {
        case 'armRaises':
          if (issue.key.contains('Elbow too bent')) {
            recommendations.add('Practice arm raises with lighter weights to maintain straight arms');
          } else if (issue.key.contains('not symmetric')) {
            recommendations.add('Focus on raising both arms to the same height simultaneously');
          }
          break;
        case 'pushUps':
          if (issue.key.contains('Incomplete range')) {
            recommendations.add('Practice push-ups against a wall first, then progress to knees, then full push-ups');
          } else if (issue.key.contains('too low')) {
            recommendations.add('Stop when your chest is about 2 inches from the ground');
          }
          break;
        case 'squats':
          if (issue.key.contains('Not deep enough')) {
            recommendations.add('Practice bodyweight squats focusing on sitting back like sitting in a chair');
          } else if (issue.key.contains('too deep')) {
            recommendations.add('Squat until thighs are parallel to the ground, no deeper');
          }
          break;
        case 'sitUps':
          if (issue.key.contains('Not lifting enough')) {
            recommendations.add('Focus on lifting your shoulder blades off the ground using core muscles');
          } else if (issue.key.contains('too high')) {
            recommendations.add('A 30-45 degree lift is sufficient for effective core engagement');
          }
          break;
      }
    }

    if (recommendations.length == 1) {
      recommendations.addAll([
        'Practice proper form slowly before increasing speed',
        'Consider recording yourself to monitor form',
        'Focus on quality over quantity of repetitions'
      ]);
    }

    return recommendations;
  }
}

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

/// First screen: Choose exercise
class ExerciseSelectionScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ExerciseSelectionScreen({Key? key, required this.cameras})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Exercise")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExerciseButton(
                label: "Arm Raises",
                cameras: cameras,
                type: ExerciseType.armRaises),
            ExerciseButton(
                label: "Push-Ups",
                cameras: cameras,
                type: ExerciseType.pushUps),
            ExerciseButton(
                label: "Squats", cameras: cameras, type: ExerciseType.squats),
            ExerciseButton(
                label: "Sit-Ups", cameras: cameras, type: ExerciseType.sitUps),
          ],
        ),
      ),
    );
  }
}

class ExerciseButton extends StatelessWidget {
  final String label;
  final List<CameraDescription> cameras;
  final ExerciseType type;

  const ExerciseButton(
      {Key? key,
      required this.label,
      required this.cameras,
      required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ExerciseDetectorScreen(cameras: cameras, exerciseType: type),
            ),
          );
        },
        child: Text(label),
      ),
    );
  }
}

/// Enum for exercises
enum ExerciseType { armRaises, pushUps, squats, sitUps }

/// Main detector screen
class ExerciseDetectorScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final ExerciseType exerciseType;

  const ExerciseDetectorScreen(
      {Key? key, required this.cameras, required this.exerciseType})
      : super(key: key);

  @override
  _ExerciseDetectorScreenState createState() => _ExerciseDetectorScreenState();
}

class _ExerciseDetectorScreenState extends State<ExerciseDetectorScreen> {
  CameraController? _cameraController;
  late PoseDetector _poseDetector;
  bool _isDetecting = false;

  int _repCount = 0;
  bool _isUp = false;
  bool _isCountingStarted = false;
  bool _isRecording = false;

  List<Pose> _poses = [];
  String _status = "Position yourself in front of camera";
  late ExerciseSession _currentSession;
  PostureAnalysis? _currentPostureAnalysis;
  List<PostureFeedback> _activeFeedback = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    _currentSession = ExerciseSession(
      exerciseType: widget.exerciseType.name,
      startTime: DateTime.now(),
      poseDataList: [],
    );
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      final poses = await _poseDetector.processImage(inputImage);
      _processPoses(poses);
    } catch (e) {
      print('Error: $e');
    }

    _isDetecting = false;
  }

  InputImage _convertCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) allBytes.putUint8List(plane.bytes);
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final sensorOrientation = widget.cameras.first.sensorOrientation;

    final rotation = {
          0: InputImageRotation.rotation0deg,
          90: InputImageRotation.rotation90deg,
          180: InputImageRotation.rotation180deg,
          270: InputImageRotation.rotation270deg,
        }[sensorOrientation] ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void _processPoses(List<Pose> poses) {
    setState(() => _poses = poses);
    if (poses.isEmpty) {
      setState(() => _status = "No person detected");
      return;
    }
    final pose = poses.first;
    _analyzeExercise(pose);
  }

  /// Calculate angle between three points
  double _calculateAngle(
      PoseLandmark point1, PoseLandmark point2, PoseLandmark point3) {
    double angle1 = atan2(point1.y - point2.y, point1.x - point2.x);
    double angle2 = atan2(point3.y - point2.y, point3.x - point2.x);
    double angle = angle2 - angle1;

    // Convert to degrees and normalize
    angle = angle * 180 / pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;

    return angle;
  }

  /// Extract landmarks and calculate angles based on exercise type
  Map<String, JointAngle> _calculateExerciseAngles(Pose pose) {
    Map<String, JointAngle> angles = {};

    switch (widget.exerciseType) {
      case ExerciseType.armRaises:
        // Left arm angle (shoulder-elbow-wrist)
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
        final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

        if (leftShoulder != null && leftElbow != null && leftWrist != null) {
          angles['leftElbow'] = JointAngle(
            degrees: _calculateAngle(leftShoulder, leftElbow, leftWrist),
            jointName: 'leftElbow',
            involvedLandmarks: ['leftShoulder', 'leftElbow', 'leftWrist'],
          );
        }

        // Right arm angle
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
        final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

        if (rightShoulder != null && rightElbow != null && rightWrist != null) {
          angles['rightElbow'] = JointAngle(
            degrees: _calculateAngle(rightShoulder, rightElbow, rightWrist),
            jointName: 'rightElbow',
            involvedLandmarks: ['rightShoulder', 'rightElbow', 'rightWrist'],
          );
        }
        break;

      case ExerciseType.pushUps:
        // Same elbow angles as arm raises
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
        final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

        if (leftShoulder != null && leftElbow != null && leftWrist != null) {
          angles['leftElbow'] = JointAngle(
            degrees: _calculateAngle(leftShoulder, leftElbow, leftWrist),
            jointName: 'leftElbow',
            involvedLandmarks: ['leftShoulder', 'leftElbow', 'leftWrist'],
          );
        }

        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
        final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

        if (rightShoulder != null && rightElbow != null && rightWrist != null) {
          angles['rightElbow'] = JointAngle(
            degrees: _calculateAngle(rightShoulder, rightElbow, rightWrist),
            jointName: 'rightElbow',
            involvedLandmarks: ['rightShoulder', 'rightElbow', 'rightWrist'],
          );
        }
        break;

      case ExerciseType.squats:
        // Left knee angle (hip-knee-ankle)
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
        final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

        if (leftHip != null && leftKnee != null && leftAnkle != null) {
          angles['leftKnee'] = JointAngle(
            degrees: _calculateAngle(leftHip, leftKnee, leftAnkle),
            jointName: 'leftKnee',
            involvedLandmarks: ['leftHip', 'leftKnee', 'leftAnkle'],
          );
        }

        // Right knee angle
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
        final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

        if (rightHip != null && rightKnee != null && rightAnkle != null) {
          angles['rightKnee'] = JointAngle(
            degrees: _calculateAngle(rightHip, rightKnee, rightAnkle),
            jointName: 'rightKnee',
            involvedLandmarks: ['rightHip', 'rightKnee', 'rightAnkle'],
          );
        }
        break;

      case ExerciseType.sitUps:
        // Hip angle (shoulder-hip-knee)
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

        if (leftShoulder != null && leftHip != null && leftKnee != null) {
          angles['leftHip'] = JointAngle(
            degrees: _calculateAngle(leftShoulder, leftHip, leftKnee),
            jointName: 'leftHip',
            involvedLandmarks: ['leftShoulder', 'leftHip', 'leftKnee'],
          );
        }

        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

        if (rightShoulder != null && rightHip != null && rightKnee != null) {
          angles['rightHip'] = JointAngle(
            degrees: _calculateAngle(rightShoulder, rightHip, rightKnee),
            jointName: 'rightHip',
            involvedLandmarks: ['rightShoulder', 'rightHip', 'rightKnee'],
          );
        }
        break;
    }

    return angles;
  }

  /// Extract relevant landmarks for the exercise
  Map<String, Point> _extractLandmarks(Pose pose) {
    Map<String, Point> landmarks = {};

    // Common landmarks for all exercises
    final commonLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final landmarkType in commonLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null) {
        landmarks[landmarkType.name] = Point(
          x: landmark.x,
          y: landmark.y,
          visibility: landmark.likelihood,
        );
      }
    }

    return landmarks;
  }

  /// Exercise-specific logic with posture analysis
  void _analyzeExercise(Pose pose) {
    bool isUp = false;

    switch (widget.exerciseType) {
      case ExerciseType.armRaises:
        isUp = _analyzeArmRaises(pose);
        break;
      case ExerciseType.pushUps:
        isUp = _analyzePushUps(pose);
        break;
      case ExerciseType.squats:
        isUp = _analyzeSquats(pose);
        break;
      case ExerciseType.sitUps:
        isUp = _analyzeSitUps(pose);
        break;
    }

    // Calculate angles and perform posture analysis
    final angles = _calculateExerciseAngles(pose);
    final postureAnalysis = PostureRuleEngine.analyzePose(widget.exerciseType, angles);
    
    setState(() {
      _currentPostureAnalysis = postureAnalysis;
      _activeFeedback = postureAnalysis.feedback
          .where((f) => f.severity != PostureSeverity.good)
          .take(2) // Show only top 2 issues to avoid clutter
          .toList();
    });

    // Record pose data if recording is enabled
    if (_isRecording) {
      final landmarks = _extractLandmarks(pose);

      _currentSession.poseDataList.add(PoseData(
        timestamp: DateTime.now(),
        angles: angles,
        landmarks: landmarks,
        isUpPosition: isUp,
        status: _status,
        postureAnalysis: postureAnalysis,
      ));
    }
  }

  bool _analyzeArmRaises(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if ([leftShoulder, rightShoulder, leftWrist, rightWrist].contains(null)) {
      setState(() => _status = "Can't detect all arm joints");
      return false;
    }

    final shoulderHeight = (leftShoulder!.y + rightShoulder!.y) / 2;
    final wristHeight = (leftWrist!.y + rightWrist!.y) / 2;
    final isUp = wristHeight < shoulderHeight - 50;

    _updateRepCount(isUp);
    return isUp;
  }

  bool _analyzePushUps(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    if ([leftShoulder, rightShoulder, leftElbow, rightElbow].contains(null)) {
      setState(() => _status = "Can't detect all joints for push-ups");
      return false;
    }

    final shoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final elbowY = (leftElbow!.y + rightElbow!.y) / 2;
    final isDown = elbowY < shoulderY + 50; // arms bent (down position)

    _updateRepCount(isDown);
    return isDown;
  }

  bool _analyzeSquats(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    if ([leftHip, rightHip, leftKnee, rightKnee].contains(null)) {
      setState(() => _status = "Can't detect all joints for squats");
      return false;
    }

    final hipY = (leftHip!.y + rightHip!.y) / 2;
    final kneeY = (leftKnee!.y + rightKnee!.y) / 2;
    final isDown = kneeY > hipY + 50; // squat down

    _updateRepCount(isDown);
    return isDown;
  }

  bool _analyzeSitUps(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if ([leftHip, rightHip, leftShoulder, rightShoulder].contains(null)) {
      setState(() => _status = "Can't detect all joints for sit-ups");
      return false;
    }

    final hipY = (leftHip!.y + rightHip!.y) / 2;
    final shoulderY = (leftShoulder!.y + rightShoulder!.y) / 2;
    final isUp = shoulderY < hipY - 50; // upper body lifted

    _updateRepCount(isUp);
    return isUp;
  }

  void _updateRepCount(bool isUp) {
    if (!_isCountingStarted && isUp) {
      _isCountingStarted = true;
      _status = "Counting started! Perform the exercise";
    }
    if (!_isCountingStarted) {
      setState(() => _status = "Get ready to start");
      return;
    }
    if (isUp && !_isUp) {
      _isUp = true;
      _status = "Up position detected";
    } else if (!isUp && _isUp) {
      _isUp = false;
      _repCount++;
      _currentSession.repCount = _repCount;
      _status = "Rep completed! Count: $_repCount";
    }
    setState(() {});
  }

  void _resetCounter() {
    setState(() {
      _repCount = 0;
      _isUp = false;
      _isCountingStarted = false;
      _status = "Counter reset";
      _currentSession = ExerciseSession(
        exerciseType: widget.exerciseType.name,
        startTime: DateTime.now(),
        poseDataList: [],
      );
      _currentPostureAnalysis = null;
      _activeFeedback.clear();
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _status = "Recording started!";
        _currentSession = ExerciseSession(
          exerciseType: widget.exerciseType.name,
          startTime: DateTime.now(),
          poseDataList: [],
          repCount: _repCount,
        );
      } else {
        _status = "Recording stopped";
      }
    });
  }

  void _exportJson() {
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(_currentSession.toJson());

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON data copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );

    // Print to console for debugging
    print('Exercise Session JSON:');
    print(jsonString);
  }

  void _showSessionAnalysis() {
    if (_currentSession.poseDataList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to analyze. Start recording first!')),
      );
      return;
    }

    final analysis = PostureRuleEngine.analyzeSession(_currentSession);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionAnalysisScreen(
          session: _currentSession,
          analysis: analysis,
        ),
      ),
    );
  }

  Color _getSeverityColor(PostureSeverity severity) {
    switch (severity) {
      case PostureSeverity.good:
        return Colors.green;
      case PostureSeverity.minor:
        return Colors.orange;
      case PostureSeverity.moderate:
        return Colors.red;
      case PostureSeverity.severe:
        return Colors.red.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseType.name.toUpperCase()),
        actions: [
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
            onPressed: _toggleRecording,
            color: _isRecording ? Colors.red : null,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showSessionAnalysis,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed:
                _currentSession.poseDataList.isNotEmpty ? _exportJson : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCounter,
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          CustomPaint(
            painter: PosePainter(
                _poses,
                Size(_cameraController!.value.previewSize!.height,
                    _cameraController!.value.previewSize!.width)),
            child: Container(),
          ),
          // Main info panel
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reps: $_repCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          if (_currentPostureAnalysis != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _currentPostureAnalysis!.isCorrectPosture
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentPostureAnalysis!.overallScore.toInt()}%',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_isRecording)
                            const Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 24),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_status,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center),
                  if (_currentSession.poseDataList.isNotEmpty)
                    Text(
                        'Poses recorded: ${_currentSession.poseDataList.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          // Posture feedback panel
          if (_activeFeedback.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Feedback:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._activeFeedback.map((feedback) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: _getSeverityColor(feedback.severity),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${feedback.joint}: ${feedback.suggestion}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentSession.poseDataList.isNotEmpty)
            FloatingActionButton(
              heroTag: "analysis",
              onPressed: _showSessionAnalysis,
              backgroundColor: Colors.purple,
              child: const Icon(Icons.analytics),
              tooltip: 'View Analysis',
            ),
          const SizedBox(height: 16),
          if (_currentSession.poseDataList.isNotEmpty)
            FloatingActionButton(
              heroTag: "export",
              onPressed: _exportJson,
              child: const Icon(Icons.download),
              tooltip: 'Export JSON',
              backgroundColor: Colors.green,
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "record",
            onPressed: _toggleRecording,
            child: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
            tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
            backgroundColor: _isRecording ? Colors.red : Colors.blue,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "reset",
            onPressed: _resetCounter,
            child: const Icon(Icons.refresh),
            tooltip: 'Reset Counter',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }
}

/// Session Analysis Screen
class SessionAnalysisScreen extends StatelessWidget {
  final ExerciseSession session;
  final SessionAnalysis analysis;

  const SessionAnalysisScreen({
    Key? key,
    required this.session,
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${session.exerciseType.toUpperCase()} Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportAnalysis(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildScoreCard(),
            const SizedBox(height: 16),
            _buildIssuesCard(),
            const SizedBox(height: 16),
            _buildRecommendationsCard(),
            const SizedBox(height: 16),
            _buildConsistencyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final duration = session.poseDataList.isNotEmpty
        ? session.poseDataList.last.timestamp.difference(session.startTime)
        : Duration.zero;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Reps', '${analysis.totalReps}'),
                _buildStatItem('Correct Reps', '${analysis.correctReps}'),
                _buildStatItem('Accuracy', '${analysis.totalReps > 0 ? (analysis.correctReps / analysis.totalReps * 100).toInt() : 0}%'),
                _buildStatItem('Duration', '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${analysis.averageScore.toInt()}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: analysis.averageScore >= 75 ? Colors.green : 
                             analysis.averageScore >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getScoreDescription(analysis.averageScore),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: analysis.averageScore / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          analysis.averageScore >= 75 ? Colors.green : 
                          analysis.averageScore >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return 'Excellent Form!';
    if (score >= 75) return 'Good Form';
    if (score >= 50) return 'Needs Improvement';
    return 'Poor Form';
  }

  Widget _buildIssuesCard() {
    if (analysis.commonIssues.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common Issues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'No common issues detected. Great job!',
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Common Issues',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...analysis.commonIssues.entries
                .take(5)
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...analysis.recommendations.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyCard() {
    if (analysis.jointConsistency.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Joint Consistency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Higher scores indicate more consistent form throughout the exercise',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...analysis.jointConsistency.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatJointName(entry.key),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${entry.value.toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: entry.value >= 70 ? Colors.green : 
                                     entry.value >= 50 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value >= 70 ? Colors.green : 
                          entry.value >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatJointName(String jointName) {
    return jointName
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _exportAnalysis(BuildContext context) {
    final analysisJson = {
      'sessionSummary': {
        'exerciseType': session.exerciseType,
        'startTime': session.startTime.toIso8601String(),
        'duration': session.poseDataList.isNotEmpty
            ? session.poseDataList.last.timestamp.difference(session.startTime).inMilliseconds
            : 0,
        'totalDataPoints': session.poseDataList.length,
      },
      'analysis': analysis.toJson(),
      'detailedSession': session.toJson(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(analysisJson);

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete analysis copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );

    print('Complete Exercise Analysis JSON:');
    print(jsonString);
  }
}

/// Painter for pose landmarks
class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;

  PosePainter(this.poses, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      _drawConnections(canvas, pose, paint, size);
      pose.landmarks.forEach((type, landmark) {
        final point = Offset(landmark.x * size.width / imageSize.width,
            landmark.y * size.height / imageSize.height);
        canvas.drawCircle(point, 4, pointPaint);
      });
    }
  }

  void _drawConnections(Canvas canvas, Pose pose, Paint paint, Size size) {
    void draw(PoseLandmarkType a, PoseLandmarkType b) {
      final l1 = pose.landmarks[a];
      final l2 = pose.landmarks[b];
      if (l1 != null && l2 != null) {
        canvas.drawLine(
            Offset(l1.x * size.width / imageSize.width,
                l1.y * size.height / imageSize.height),
            Offset(l2.x * size.width / imageSize.width,
                l2.y * size.height / imageSize.height),
            paint);
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