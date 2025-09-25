import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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