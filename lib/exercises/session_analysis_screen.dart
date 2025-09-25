// session_analysis_screen_modern.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:final_sai/models/analysis_models.dart';
import 'package:final_sai/models/exercise_models.dart';
import 'package:final_sai/other.dart';

/// Playful, modern, media-queried Session Analysis Screen
class SessionAnalysisScreen extends StatefulWidget {
  final ExerciseSession session;
  final SessionAnalysis analysis;

  const SessionAnalysisScreen({
    Key? key,
    required this.session,
    required this.analysis,
  }) : super(key: key);

  @override
  State<SessionAnalysisScreen> createState() => _SessionAnalysisScreenState();
}

class _SessionAnalysisScreenState extends State<SessionAnalysisScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    // show confetti when exceptional score
    if (widget.analysis.averageScore >= 90) {
      _showConfetti = true;
      _confettiController.forward();
      Timer(const Duration(milliseconds: 1400), () {
        _confettiController.reverse();
        setState(() {
          _showConfetti = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _exportAnalysis(BuildContext context) {
    final duration = widget.session.poseDataList.isNotEmpty
        ? widget.session.poseDataList.last.timestamp.difference(widget.session.startTime).inMilliseconds
        : 0;
    final analysisJson = {
      'sessionSummary': {
        'exerciseType': widget.session.exerciseType,
        'startTime': widget.session.startTime.toIso8601String(),
        'durationMs': duration,
        'totalDataPoints': widget.session.poseDataList.length,
      },
      'analysis': widget.analysis.toJson(),
      'detailedSession': widget.session.toJson(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(analysisJson);

    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete analysis copied to clipboard!')));
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final theme = Theme.of(context);
    final averageScore = analysis.averageScore.clamp(0, 100).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFF0D47A1),
            child: Icon(Icons.sports_tennis, color: Colors.white),
          ),
        ),
        title: Text('${widget.session.exerciseType.toUpperCase()} Analysis',
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        actions: [
          IconButton(
            tooltip: 'Export analysis JSON',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _exportAnalysis(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final padding = EdgeInsets.symmetric(horizontal: isWide ? 36 : 16, vertical: 12);

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayfulHeader(averageScore, isWide),
              const SizedBox(height: 18),
              isWide ? _buildWideBody(analysis) : _buildNarrowBody(analysis),
              const SizedBox(height: 26),
            ],
          ),
        );
      }),
    );
  }

  // ---------------- Header ----------------
  Widget _buildPlayfulHeader(double averageScore, bool isWide) {
    // derive level & xp
    final level = (averageScore / 20).clamp(0, 5).ceil();
    final xp = (averageScore % 20) / 20.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFEEF6FF), const Color(0xFFF6FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // animated score ring
              _ScoreRing(score: averageScore, size: isWide ? 140 : 110),
              const SizedBox(width: 18),
              // stats + badges
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    children: [
                      Text(
                        _getScoreHeadline(averageScore),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          const Icon(Icons.emoji_events, size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 6),
                          Text('Lvl ${((averageScore / 20).clamp(0, 5).ceil())}', style: const TextStyle(fontWeight: FontWeight.w700))
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${averageScore.toInt()}% • ${analysisDescription(averageScore)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('XP Progress', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              minHeight: 12,
                              value: xp,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF0D47A1)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${(xp * 100).toInt()} XP to next level', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      _miniStat('Reps', '${widget.analysis.totalReps}', icon: Icons.repeat, color: Colors.purple),
                      const SizedBox(width: 8),
                      _miniStat('Acc', '${_accuracyPercent(widget.analysis)}%', icon: Icons.track_changes, color: Colors.teal),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ),
        // confetti overlay when high score
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(_confettiController),
              ),
            ),
          ),
      ],
    );
  }

  String _getScoreHeadline(double score) {
    if (score >= 95) return 'Legendary!';
    if (score >= 90) return 'Outstanding';
    if (score >= 75) return 'Great Form';
    if (score >= 50) return 'Keep Improving';
    return 'Practice Needed';
  }

  String analysisDescription(double score) {
    if (score >= 90) return 'Form is exceptional — small refinements only.';
    if (score >= 75) return 'Good form. Keep the consistency up.';
    if (score >= 50) return 'Noticeable issues. Follow recommendations.';
    return 'Significant correction required.';
  }

  Widget _miniStat(String title, String value, {required IconData icon, required Color color}) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
      ]),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ]),
    );
  }

  // ---------------- Layout bodies ----------------

  Widget _buildNarrowBody(SessionAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 12),
        _buildScoreCard(),
        const SizedBox(height: 12),
        _buildBadgesRow(),
        const SizedBox(height: 12),
        _buildIssuesCard(),
        const SizedBox(height: 12),
        _buildRecommendationsCard(),
        const SizedBox(height: 12),
        _buildConsistencyCard(),
      ],
    );
  }

  Widget _buildWideBody(SessionAnalysis analysis) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // left column
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 12),
              _buildRecommendationsCard(),
              const SizedBox(height: 12),
              _buildConsistencyCard(),
            ],
          ),
        ),
        const SizedBox(width: 18),
        // right column
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildScoreCard(),
              const SizedBox(height: 12),
              _buildBadgesRow(),
              const SizedBox(height: 12),
              _buildIssuesCard(),
            ],
          ),
        )
      ],
    );
  }

  // ---------------- Existing content but upgraded visually ----------------

  Widget _buildSummaryCard() {
    final session = widget.session;
    final analysis = widget.analysis;
    final duration = session.poseDataList.isNotEmpty
        ? session.poseDataList.last.timestamp.difference(session.startTime)
        : Duration.zero;

    return _fancyCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Session Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statPill('Total Reps', '${analysis.totalReps}', icon: Icons.fitness_center),
            _statPill('Correct Reps', '${analysis.correctReps}', icon: Icons.check_circle),
            _statPill('Accuracy', '${analysis.totalReps > 0 ? (analysis.correctReps / analysis.totalReps * 100).toInt() : 0}%', icon: Icons.percent),
            _statPill('Duration', '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}', icon: Icons.timer),
          ],
        ),
      ]),
    );
  }

  Widget _buildScoreCard() {
    final average = widget.analysis.averageScore;
    final color = average >= 75 ? Colors.green : average >= 50 ? Colors.orange : Colors.red;

    return _fancyCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Form Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.analysis.averageScore),
                  duration: const Duration(milliseconds: 950),
                  builder: (context, value, _) => Text('${value.toInt()}%',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: color)),
                ),
                const SizedBox(height: 6),
                Text(_getScoreDescription(widget.analysis.averageScore), style: const TextStyle(fontSize: 14)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.analysis.averageScore / 100),
                  duration: const Duration(milliseconds: 950),
                  builder: (context, progress, _) => LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Form stability and joint alignment', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ]),
            ),
          ],
        ),
      ]),
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return 'Excellent Form!';
    if (score >= 75) return 'Good Form';
    if (score >= 50) return 'Needs Improvement';
    return 'Poor Form';
  }

  Widget _buildIssuesCard() {
    final issues = widget.analysis.commonIssues;
    if (issues.isEmpty) {
      return _fancyCard(
        color: Colors.green.shade50,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Common Issues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('No common issues detected. Great job!', style: TextStyle(color: Colors.green, fontSize: 14)),
        ]),
      );
    }

    return _fancyCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Common Issues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...issues.entries.take(6).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${entry.value}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.key)),
              ],
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildRecommendationsCard() {
    final recs = widget.analysis.recommendations;
    return _fancyCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Column(
          children: recs.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildConsistencyCard() {
    final joints = widget.analysis.jointConsistency;
    if (joints.isEmpty) return const SizedBox.shrink();
    return _fancyCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Joint Consistency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Higher scores indicate more consistent form throughout the exercise', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 12),
        Column(
          children: joints.entries.map((entry) {
            final percent = entry.value.clamp(0, 100).toDouble();
            final color = percent >= 70 ? Colors.green : percent >= 50 ? Colors.orange : Colors.red;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_formatJointName(entry.key), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('${percent.toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }

  String _formatJointName(String jointName) {
    return jointName
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(' ')
        .map((w) => w.isNotEmpty ? (w[0].toUpperCase() + w.substring(1)) : w)
        .join(' ');
  }

  // ---------------- Gamified badges ----------------

  Widget _buildBadgesRow() {
    final badges = _computeBadges(widget.analysis);
    return _fancyCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges
              .map((b) => Chip(
                    avatar: CircleAvatar(child: Icon(b.icon, size: 18, color: Colors.white), backgroundColor: b.color),
                    label: Text(b.label),
                    backgroundColor: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.03),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  ))
              .toList(),
        ),
      ]),
    );
  }

  List<_Badge> _computeBadges(SessionAnalysis a) {
    final List<_Badge> out = [];
    if (a.averageScore >= 90) out.add(_Badge('Perfection', Icons.star, Colors.amber.shade700));
    if (a.totalReps >= 50) out.add(_Badge('Endurance', Icons.repeat, Colors.purple));
    if (a.correctReps >= (a.totalReps * 0.9).ceil() && a.totalReps > 0) out.add(_Badge('Precision', Icons.check, Colors.green));
    if (a.jointConsistency.values.any((v) => v >= 85)) out.add(_Badge('Stable Joints', Icons.shield, Colors.teal));
    if (a.recommendations.length >= 3) out.add(_Badge('Coachable', Icons.school, Colors.blue));
    return out;
  }

  // ---------------- Helpers & small UI pieces ----------------

  Widget _fancyCard({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _statPill(String label, String value, {IconData? icon}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) Icon(icon, size: 14, color: Colors.black45),
              if (icon != null) const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
          ],
        ),
      ),
    );
  }

  int _accuracyPercent(SessionAnalysis a) {
    if (a.totalReps == 0) return 0;
    return ((a.correctReps / a.totalReps) * 100).toInt();
  }
}

// ---------- Animated score ring widget ----------
class _ScoreRing extends StatelessWidget {
  final double score; // 0-100
  final double size;

  const _ScoreRing({Key? key, required this.score, this.size = 120}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = (score / 100).clamp(0.0, 1.0);
    final ringColor = score >= 75 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: percent),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white, Colors.grey.shade50]),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
                ),
              ),
              // base ring
              SizedBox(
                width: size * 0.86,
                height: size * 0.86,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: size * 0.14,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(ringColor),
                ),
              ),
              // center number
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(score >= 75 ? 'Pro' : score >= 50 ? 'Amateur' : 'Beginner', style: TextStyle(fontSize: size * 0.08, color: Colors.black54)),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ---------- Confetti painter (simple animated dots) ----------
class _ConfettiPainter extends CustomPainter {
  final Animation<double> progress;
  final Random _rng = Random();

  _ConfettiPainter(this.progress) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint();
    const colors = [Colors.amber, Colors.pink, Colors.lightGreen, Colors.cyan, Colors.orangeAccent];

    for (int i = 0; i < 30; i++) {
      final x = size.width * (i / 30.0);
      final y = size.height * (0.15 + 0.6 * (1 - t)) + _rng.nextDouble() * 40 * (1 - t);
      paint.color = colors[i % colors.length].withOpacity(0.9 * (1 - (i % 5) * 0.06));
      final sizeDot = 4.0 + (i % 7);
      canvas.drawCircle(Offset(x, y * (0.6 + 0.4 * t)), sizeDot, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _Badge {
  final String label;
  final IconData icon;
  final Color color;
  _Badge(this.label, this.icon, this.color);
}
