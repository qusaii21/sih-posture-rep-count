import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:final_sai/exercises/session_analysis_screen.dart';
import 'package:final_sai/models/analysis_models.dart';
import 'package:final_sai/models/exercise_models.dart';
import 'package:final_sai/services/pose_analysis_service.dart';
import 'package:final_sai/services/pose_detection_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
export 'exercise_detector_screen.dart' show ExerciseDetectorScreen, ExerciseType, PostureAnalysis, PostureRuleEngine, ExerciseSession, SessionAnalysis, PostureFeedback, PostureSeverity;





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