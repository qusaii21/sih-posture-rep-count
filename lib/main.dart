import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:final_sai/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(SAISportsApp(cameras: cameras));
}

class SAISportsApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SAISportsApp({Key? key, required this.cameras}) : super(key: key);

  @override
  _SAISportsAppState createState() => _SAISportsAppState();
}

class _SAISportsAppState extends State<SAISportsApp> {
  Locale _currentLocale = const Locale('en', 'US');

  void _changeLanguage(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAI Talent Scout',
      debugShowCheckedModeBanner: false, // debug flag removed (banner disabled)
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      locale: _currentLocale,
      home: SplashScreen(
        cameras: widget.cameras,
        onLanguageChange: _changeLanguage,
      ),
    );
  }
}
