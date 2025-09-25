import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:final_sai/models/exercise_models.dart';
import 'package:final_sai/other.dart';
import 'package:final_sai/screens/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// Responsive Home Screen with Exercise Selection + Sport-Specific Templates (view-only)
// This file adds MediaQuery-based responsiveness (breakpoints for mobile/tablet/desktop)

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(Locale) onLanguageChange;

  const HomeScreen({Key? key, required this.cameras, required this.onLanguageChange}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSport = 'Athletics';
  SportTemplate? _selectedTemplate;

  // Frontend-only sample templates using string keys (no enum changes)
  final Map<String, List<SportTemplate>> _sportTemplates = {
    'Athletics': [
      SportTemplate(
        id: 'ath_01',
        name: 'Sprint & Power (U16)',
        exercises: [
          TemplateExercise('verticalJump', 'Vertical Jump', weightage: 40),
          TemplateExercise('shuttleRun', 'Shuttle Run 5x', weightage: 30),
          TemplateExercise('sitUps', 'Sit-Ups 60s', weightage: 15),
          
        ],
      ),
      SportTemplate(
        id: 'ath_02',
        name: 'Endurance Focus',
        exercises: [
          TemplateExercise('enduranceRun', 'Endurance 2km', weightage: 60),
          TemplateExercise('sitUps', 'Sit-Ups 60s', weightage: 20),
          TemplateExercise('armRaises', 'Arm Raises', weightage: 20),
        ],
      ),
    ],
    'Basketball': [
      SportTemplate(
        id: 'bb_01',
        name: 'Basketball Basic',
        exercises: [
          TemplateExercise('verticalJump', 'Vertical Jump', weightage: 40),
          TemplateExercise('squats', 'Squats', weightage: 30),
          TemplateExercise('pushUps', 'Push-Ups', weightage: 30),
        ],
      ),
    ],
    'Football': [
      SportTemplate(
        id: 'fb_01',
        name: 'Football Fitness',
        exercises: [
          TemplateExercise('shuttleRun', 'Shuttle Run 5x', weightage: 40),
          TemplateExercise('squats', 'Squats', weightage: 30),
          TemplateExercise('enduranceRun', 'Endurance 2km', weightage: 30),
        ],
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    final templates = _sportTemplates[_selectedSport];
    if (templates != null && templates.isNotEmpty) _selectedTemplate = templates.first;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    // Breakpoints
    final isSmall = width < 600; // phones
    final isMedium = width >= 600 && width < 900; // tablets
    final isLarge = width >= 900; // desktop / large tablet

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context, isSmall, isMedium, isLarge),
              SliverToBoxAdapter(child: _buildWelcomeCard(context, isSmall)),
              SliverToBoxAdapter(child: _buildStatsCard(context, isSmall)),
              SliverToBoxAdapter(child: _buildTemplateSelector(context, isSmall)),
              SliverToBoxAdapter(child: _buildTemplatesList(context, isSmall, isMedium, isLarge)),
              SliverToBoxAdapter(child: _buildExercisesGrid(context, isSmall, isMedium, isLarge)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isSmall, bool isMedium, bool isLarge) {
    // scale text sizes slightly based on breakpoints
    final titleSize = isSmall ? 18.0 : isMedium ? 20.0 : 22.0;
    final subtitleSize = isSmall ? 11.0 : 12.0;

    // Slightly increased expandedHeight for more vertical space
    final expandedH = isSmall ? 90.0 : 110.0;

    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: expandedH,
      flexibleSpace: Container(
        padding: EdgeInsets.all(isSmall ? 12 : 20),
        child: Row(
          children: [
            Container(
              width: isSmall ? 44 : 50,
              height: isSmall ? 44 : 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.sports_gymnastics, color: Colors.white),
            ),
            SizedBox(width: isSmall ? 10 : 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SAI Talent Scout',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(height: isSmall ? 4 : 6),
                  Text(
                    'Discover Your Athletic Potential',
                    style: TextStyle(fontSize: subtitleSize, color: Colors.grey),
                  ),
                ],
              ),
            ),
            _buildLanguageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Color(0xFF1565C0)),
      onSelected: widget.onLanguageChange,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: Locale('en', 'US'),
          child: Row(
            children: [
              Text('🇺🇸', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text('English'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: Locale('hi', 'IN'),
          child: Row(
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text('हिंदी'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: Locale('ta', 'IN'),
          child: Row(
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Text('தமிழ்'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context, bool isSmall) {
    return Container(
      margin: EdgeInsets.all(isSmall ? 14 : 20),
      padding: EdgeInsets.all(isSmall ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Champion!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmall ? 6 : 10),
                Text(
                  'Ready for your next challenge?',
                  style: TextStyle(color: Colors.white70, fontSize: isSmall ? 12 : 14),
                ),
                SizedBox(height: isSmall ? 12 : 15),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Start Training'),
                ),
              ],
            ),
          ),
          if (!isSmall) const Icon(Icons.emoji_events, color: Colors.white, size: 80) else const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, bool isSmall) {
    // Request: always show side-by-side as a row like before
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Tests Completed', '12', Icons.check_circle, Colors.green, isSmall)),
          Expanded(child: _buildStatItem('Best Score', '92%', Icons.star, Colors.orange, isSmall)),
          Expanded(child: _buildStatItem('Current Rank', '#1,247', Icons.trending_up, Colors.blue, isSmall)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isSmall) {
    return Container(
      margin: EdgeInsets.all(isSmall ? 6 : 6),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 14, vertical: isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 26 : 30),
          SizedBox(height: isSmall ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isSmall ? 6 : 6),
          Text(
            label,
            style: TextStyle(fontSize: isSmall ? 10 : 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ------------------- Template Selector UI (view-only) -------------------
  Widget _buildTemplateSelector(BuildContext context, bool isSmall) {
    final sports = _sportTemplates.keys.toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: isSmall ? 10 : 12),
      padding: EdgeInsets.all(isSmall ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Sport & Template', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          SizedBox(height: isSmall ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSport,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedSport = v;
                      final templates = _sportTemplates[_selectedSport];
                      _selectedTemplate = templates != null && templates.isNotEmpty ? templates.first : null;
                    });
                  },
                ),
              ),
              SizedBox(width: isSmall ? 8 : 12),
              // Create button intentionally removed for view-only mode
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(BuildContext context, bool isSmall, bool isMedium, bool isLarge) {
    final templates = _sport_templates_safe();
    final width = MediaQuery.of(context).size.width;

    // responsive card width for horizontal list
    double cardWidth() {
      if (isSmall) return min(360, width * 0.86);
      if (isMedium) return min(420, width * 0.52);
      return min(480, width * 0.36);
    }

    // Increased heights for template cards as requested
    double listHeight() {
      if (isSmall) return 220;
      if (isMedium) return 240;
      return 260;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: listHeight(),
            child: templates.isEmpty
                ? const Center(child: Text('No templates for this sport.'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final t = templates[index];
                      final isSelected = t == _selectedTemplate;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTemplate = t),
                        child: Container(
                          width: cardWidth(),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1565C0) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.name, style: TextStyle(fontSize: isSmall ? 15 : 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                              const SizedBox(height: 8),
                              Text('${t.exercises.length} exercises • Total weight ${t.totalWeight}%', style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: min(4, t.exercises.length), // show more lines thanks to increased height
                                  itemBuilder: (context, i) {
                                    final ex = t.exercises[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text('• ${ex.title} (${ex.weightage}%)', style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: isSmall ? 12 : 13)),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _openTemplateDetail(context, t),
                                    child: Text(isSelected ? 'View' : 'Details', style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1565C0))),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    onPressed: () => _startTemplateRun(context, t),
                                    style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.white : const Color(0xFF1565C0)),
                                    child: Text(isSelected ? 'Start' : 'Use', style: TextStyle(color: isSelected ? const Color(0xFF1565C0) : Colors.white)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper to safely get templates map without re-evaluating _sportTemplates each time
  List<SportTemplate> _sport_templates_safe() {
    return _sportTemplates[_selectedSport] ?? [];
  }

  // Template detail modal (view-only)
  void _openTemplateDetail(BuildContext context, SportTemplate t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Total ${t.totalWeight}%', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              ...t.exercises.map((e) => ListTile(
                    title: Text(e.title),
                    subtitle: Text('${e.weightage}%'),
                    trailing: Icon(_mapExerciseIconFromKey(e.typeKey)),
                  )),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startTemplateRun(context, t);
                },
                child: const Text('Start Template'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Start running the template — open a screen listing exercises to run
  void _startTemplateRun(BuildContext context, SportTemplate t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TemplateExercisesScreen(cameras: widget.cameras, template: t)),
    );
  }

  // ------------------- Exercises Grid (existing) -------------------
  Widget _buildExercisesGrid(BuildContext context, bool isSmall, bool isMedium, bool isLarge) {
    final exercises = [
      ExerciseInfo(
        'Arm Raises',
        'Shoulder strength & mobility test',
        Icons.accessibility_new,
        Colors.blue,
        ExerciseType.armRaises,
      ),
      ExerciseInfo(
        'Push-Ups',
        'Upper body strength assessment',
        Icons.fitness_center,
        Colors.red,
        ExerciseType.pushUps,
      ),
      ExerciseInfo(
        'Squats',
        'Lower body power evaluation',
        Icons.sports_gymnastics,
        Colors.green,
        ExerciseType.squats,
      ),
      ExerciseInfo(
        'Sit-Ups',
        'Core strength measurement',
        Icons.sports_handball,
        Colors.orange,
        ExerciseType.sitUps,
      ),
    ];

    // responsive grid count
    int crossAxisCount = isSmall ? 2 : isMedium ? 3 : 4;
    double aspect = isSmall ? 0.85 : 0.95;

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fitness Assessment Tests',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: aspect,
            ),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return _buildExerciseCard(context, exercises[index], isSmall);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseInfo exercise, bool isSmall) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TutorialScreen(
              cameras: widget.cameras,
              exerciseInfo: exercise,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: isSmall ? 70 : 80,
              decoration: BoxDecoration(
                color: exercise.color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  exercise.icon,
                  size: isSmall ? 36 : 40,
                  color: exercise.color,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 12 : 15),
                child: Column(
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmall ? 6 : 8),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        fontSize: isSmall ? 11 : 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 12, vertical: isSmall ? 6 : 6),
                      decoration: BoxDecoration(
                        color: exercise.color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers: map string keys to icons
  IconData _mapExerciseIconFromKey(String key) {
    switch (key) {
      case 'armRaises':
        return Icons.accessibility_new;
      case 'pushUps':
        return Icons.fitness_center;
      case 'squats':
        return Icons.sports_gymnastics;
      case 'sitUps':
        return Icons.sports_handball;
      case 'verticalJump':
        return Icons.trending_up;
      case 'shuttleRun':
        return Icons.directions_run;
      case 'enduranceRun':
        return Icons.timeline;
      default:
        return Icons.fitness_center;
    }
  }

  List<TemplateExercise> _canonicalExercises() {
    return [
      TemplateExercise('verticalJump', 'Vertical Jump', weightage: 10),
      TemplateExercise('shuttleRun', 'Shuttle Run 5x', weightage: 10),
      TemplateExercise('sitUps', 'Sit-Ups 60s', weightage: 10),
      TemplateExercise('enduranceRun', 'Endurance 2km', weightage: 10),
      TemplateExercise('armRaises', 'Arm Raises', weightage: 10),
      TemplateExercise('pushUps', 'Push-Ups', weightage: 10),
      TemplateExercise('squats', 'Squats', weightage: 10),
    ];
  }
}

// ------------------- Template Data Models (frontend-only) -------------------
class SportTemplate {
  final String id;
  String name;
  List<TemplateExercise> exercises;

  SportTemplate({required this.id, required this.name, required this.exercises});

  int get totalWeight => exercises.fold(0, (a, b) => a + b.weightage);
}

class TemplateExercise {
  // typeKey is a string name referencing existing exercise types (frontend-only)
  final String typeKey;
  final String title;
  int weightage;

  TemplateExercise(this.typeKey, this.title, {this.weightage = 10});
}

// ------------------- Template Runner Screen -------------------
class TemplateExercisesScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  final SportTemplate template;

  const TemplateExercisesScreen({Key? key, required this.cameras, required this.template}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(template.name), backgroundColor: const Color(0xFF1565C0)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: template.exercises.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ex = template.exercises[index];
          final info = _toExerciseInfo(ex);
          return ListTile(
            leading: CircleAvatar(child: Icon(_mapIconForInfo(info))),
            title: Text(info.name),
            subtitle: Text(info.description),
            trailing: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TutorialScreen(cameras: cameras, exerciseInfo: info),
                ),
              ),
              child: const Text('Start'),
            ),
          );
        },
      ),
    );
  }

  ExerciseInfo _toExerciseInfo(TemplateExercise te) {
    // map template exercise key to the ExerciseInfo used by TutorialScreen
    switch (te.typeKey) {
      case 'sitUps':
        return ExerciseInfo('Sit-Ups 60s', 'Core endurance test', Icons.sports_handball, Colors.orange, ExerciseType.sitUps);
      case 'pushUps':
        return ExerciseInfo('Push-Ups', 'Upper body strength', Icons.fitness_center, Colors.red, ExerciseType.pushUps);
      case 'squats':
        return ExerciseInfo('Squats', 'Lower body strength', Icons.sports_gymnastics, Colors.green, ExerciseType.squats);
      case 'armRaises':
      default:
        return ExerciseInfo('Arm Raises', 'Shoulder mobility test', Icons.accessibility_new, Colors.blue, ExerciseType.armRaises);
    }
  }

  IconData _mapIconForInfo(ExerciseInfo info) => info.icon;
}

// ------------------- ExerciseInfo class (kept here for completeness) -------------------
class ExerciseInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final ExerciseType type;

  ExerciseInfo(this.name, this.description, this.icon, this.color, this.type);
}
