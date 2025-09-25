import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:final_sai/models/analysis_models.dart';
import 'package:final_sai/models/exercise_models.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';


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

