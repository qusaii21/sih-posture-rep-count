import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:final_sai/exercises/exercise_detector_screen.dart';
import 'package:final_sai/models/exercise_models.dart';
import 'package:final_sai/other.dart';
import 'package:final_sai/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// NEW: video_player package
import 'package:video_player/video_player.dart';


// Tutorial Screen
class TutorialScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final ExerciseInfo exerciseInfo;

  const TutorialScreen({Key? key, required this.cameras, required this.exerciseInfo}) : super(key: key);

  @override
  _TutorialScreenState createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  bool _showVideo = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Compute default asset path from ExerciseType.
  // e.g. assets/videos/tutorial_pushUps.mp4
  String _defaultAssetForExercise() {
    // using the enum name for file naming
    final raw = widget.exerciseInfo.type.toString().split('.').last;
    return 'assets/videos/tutorial.mp4';
  }

  Future<void> _openVideo() async {
    final assetPath = _defaultAssetForExercise();
    // Navigate to player screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          assetPath: assetPath,
          title: widget.exerciseInfo.name,
          accentColor: widget.exerciseInfo.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [widget.exerciseInfo.color.withOpacity(0.08), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _showVideo ? _buildVideoTutorial() : _buildTextTutorial(),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exerciseInfo.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Text(
                  'Learn proper form and technique',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildToggleButton('Video', _showVideo, () {
                setState(() => _showVideo = true);
                _fadeController.reset();
                _fadeController.forward();
              }),
              const SizedBox(width: 10),
              _buildToggleButton('Text', !_showVideo, () {
                setState(() => _showVideo = false);
                _fadeController.reset();
                _fadeController.forward();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.exerciseInfo.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.exerciseInfo.color),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : widget.exerciseInfo.color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTutorial() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // PLAY AREA — tappable to open fullscreen player
          GestureDetector(
            onTap: _openVideo,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // soft background gradient so user sees exercise color
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.exerciseInfo.color.withOpacity(0.28),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Play CTA
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: widget.exerciseInfo.color,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Tap to play tutorial video',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Top-right small hint: "asset"
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildKeyPoints(),
        ],
      ),
    );
  }

  Widget _buildTextTutorial() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 20),
            _buildKeyPoints(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    final instructions = _getExerciseInstructions();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: widget.exerciseInfo.color),
              const SizedBox(width: 10),
              const Text(
                'Step by Step Instructions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: widget.exerciseInfo.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<String> _getExerciseInstructions() {
    switch (widget.exerciseInfo.type) {
      case ExerciseType.armRaises:
        return [
          'Stand straight with feet shoulder-width apart',
          'Hold your arms at your sides with palms facing forward',
          'Slowly raise both arms to shoulder height',
          'Keep your arms straight throughout the movement',
          'Hold for 1 second, then lower slowly',
          'Repeat the movement maintaining good form',
        ];
      case ExerciseType.pushUps:
        return [
          'Start in plank position with hands shoulder-width apart',
          'Keep your body in a straight line from head to heels',
          'Lower your body until chest nearly touches the ground',
          'Push back up to starting position',
          'Keep core engaged throughout the movement',
          'Breathe in on the way down, out on the way up',
        ];
      case ExerciseType.squats:
        return [
          'Stand with feet shoulder-width apart',
          'Keep your chest up and core engaged',
          'Lower your body as if sitting back into a chair',
          'Keep your knees behind your toes',
          'Lower until thighs are parallel to the ground',
          'Push through your heels to return to standing',
        ];
      case ExerciseType.sitUps:
        return [
          'Lie on your back with knees bent',
          'Place hands behind your head lightly',
          'Keep your feet flat on the ground',
          'Engage your core and lift your torso',
          'Rise until your torso is nearly vertical',
          'Lower back down with control',
        ];
    }
  }

  Widget _buildKeyPoints() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: widget.exerciseInfo.color),
              const SizedBox(width: 10),
              const Text(
                'Key Points to Remember',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTipItem('Maintain proper form throughout', Icons.check_circle),
          _buildTipItem('Control your breathing rhythm', Icons.air),
          _buildTipItem('Start slowly and focus on technique', Icons.speed),
          _buildTipItem('Keep your core engaged', Icons.fitness_center),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: BorderSide(color: widget.exerciseInfo.color),
              ),
              child: Text(
                'Back to Exercises',
                style: TextStyle(color: widget.exerciseInfo.color),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetectorScreen(
                      cameras: widget.cameras,
                      exerciseType: widget.exerciseInfo.type,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.exerciseInfo.color,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Start Assessment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Fullscreen video player that plays an asset video.
/// NOTE: requires `video_player` dependency and the asset registered in pubspec.yaml
class VideoPlayerScreen extends StatefulWidget {
  final String assetPath;
  final String title;
  final Color accentColor;

  const VideoPlayerScreen({Key? key, required this.assetPath, this.title = 'Tutorial', this.accentColor = Colors.blue})
      : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    // initialize from asset
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
        });
        _controller.play();
        setState(() {
          _playing = true;
        });
      }).catchError((err) {
        // error (likely missing asset) — show snack and pop
        debugPrint('Error initializing video asset: $err');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not load video: ${widget.assetPath}')),
            );
          }
        });
      });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // prevents keyboard/IME from changing layout
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _initialized
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Video area expands to available space
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: (_controller.value.isInitialized && _controller.value.aspectRatio > 0)
                            ? _controller.value.aspectRatio
                            : (16 / 9),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller),
                            // translucent overlay to capture taps and show icon
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                    _playing = false;
                                  } else {
                                    _controller.play();
                                    _playing = true;
                                  }
                                });
                              },
                              child: Container(
                                color: Colors.black26,
                                child: Center(
                                  child: Icon(
                                    _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                    size: 72,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Controls area — kept scrollable/padded so it won't overflow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(_formatDuration(_controller.value.position), style: const TextStyle(color: Colors.white70)),
                                Expanded(
                                  child: VideoProgressIndicator(
                                    _controller,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: widget.accentColor,
                                      bufferedColor: Colors.white24,
                                      backgroundColor: Colors.white12,
                                    ),
                                  ),
                                ),
                                Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    final pos = _controller.value.position - const Duration(seconds: 10);
                                    _controller.seekTo(pos > Duration.zero ? pos : Duration.zero);
                                  },
                                  icon: const Icon(Icons.replay_10, color: Colors.white),
                                ),
                                IconButton(
                                  onPressed: () {
                                    final pos = _controller.value.position + const Duration(seconds: 10);
                                    _controller.seekTo(pos < _controller.value.duration ? pos : _controller.value.duration);
                                  },
                                  icon: const Icon(Icons.forward_10, color: Colors.white),
                                ),
                                Row(children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _volume = (_volume - 0.25).clamp(0.0, 1.0);
                                        _controller.setVolume(_volume);
                                      });
                                    },
                                    icon: const Icon(Icons.volume_down, color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _volume = (_volume + 0.25).clamp(0.0, 1.0);
                                        _controller.setVolume(_volume);
                                      });
                                    },
                                    icon: const Icon(Icons.volume_up, color: Colors.white),
                                  ),
                                ]),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Done'),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
        ),
      ),
    );
  }
}
