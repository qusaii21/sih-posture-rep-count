// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:math';
// import 'package:final_sai/exercises/exercise_detector_screen.dart';
// import 'package:final_sai/models/exercise_models.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
// import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// /// First screen: Choose exercise
// class ExerciseSelectionScreen extends StatelessWidget {
//   final List<CameraDescription> cameras;

//   const ExerciseSelectionScreen({Key? key, required this.cameras})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Select Exercise")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ExerciseButton(
//                 label: "Arm Raises",
//                 cameras: cameras,
//                 type: ExerciseType.armRaises),
//             ExerciseButton(
//                 label: "Push-Ups",
//                 cameras: cameras,
//                 type: ExerciseType.pushUps),
//             ExerciseButton(
//                 label: "Squats", cameras: cameras, type: ExerciseType.squats),
//             ExerciseButton(
//                 label: "Sit-Ups", cameras: cameras, type: ExerciseType.sitUps),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ExerciseButton extends StatelessWidget {
//   final String label;
//   final List<CameraDescription> cameras;
//   final ExerciseType type;

//   const ExerciseButton(
//       {Key? key,
//       required this.label,
//       required this.cameras,
//       required this.type})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) =>
//                   ExerciseDetectorScreen(cameras: cameras, exerciseType: type),
//             ),
//           );
//         },
//         child: Text(label),
//       ),
//     );
//   }
// }