import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  final List<Map<String, dynamic>> _allPuzzleData = [
    // Level 1: Science Formulas
    {'q': 'F = m × ?', 'a': 'a', 'lvl': 1},
    {'q': 'V = I × ?', 'a': 'R', 'lvl': 1},
    {'q': 'W = m × ?', 'a': 'g', 'lvl': 1},
    {'q': 'P = F / ?', 'a': 'A', 'lvl': 1},
    // Level 2: Science Units
    {'q': 'Unit of Force', 'a': 'Newton', 'lvl': 2},
    {'q': 'Unit of Energy', 'a': 'Joule', 'lvl': 2},
    {'q': 'Unit of Power', 'a': 'Watt', 'lvl': 2},
    {'q': 'Unit of Current', 'a': 'Ampere', 'lvl': 2},
    // Level 3: Chemical Symbols
    {'q': 'Sodium', 'a': 'Na', 'lvl': 3},
    {'q': 'Potassium', 'a': 'K', 'lvl': 3},
    {'q': 'Iron', 'a': 'Fe', 'lvl': 3},
    {'q': 'Copper', 'a': 'Cu', 'lvl': 3},
    // Level 4: ICT Hardware
    {'q': 'Pointing Device', 'a': 'Mouse', 'lvl': 4},
    {'q': 'Display Output', 'a': 'Monitor', 'lvl': 4},
    {'q': 'Brain of PC', 'a': 'CPU', 'lvl': 4},
    {'q': 'Hard Copy Out', 'a': 'Printer', 'lvl': 4},
    // Level 5: ICT Data
    {'q': '8 Bits = ?', 'a': '1 Byte', 'lvl': 5},
    {'q': 'Volatile Memory', 'a': 'RAM', 'lvl': 5},
    {'q': 'Permanent Disk', 'a': 'HDD', 'lvl': 5},
    {'q': 'Binary (Off)', 'a': '0', 'lvl': 5},
    // Level 6: Math Logic
    {'q': '2, 4, 6, ?', 'a': '8', 'lvl': 6},
    {'q': '10, 20, 30, ?', 'a': '40', 'lvl': 6},
    {'q': '1, 4, 9, ?', 'a': '16', 'lvl': 6},
    {'q': '100 / 2', 'a': '50', 'lvl': 6},
    // Level 7: General Science
    {'q': 'H2O', 'a': 'Water', 'lvl': 7},
    {'q': 'CO2', 'a': 'Carbon', 'lvl': 7},
    {'q': 'O2', 'a': 'Oxygen', 'lvl': 7},
    {'q': 'Sun gives?', 'a': 'Energy', 'lvl': 7},
    // Level 8: IT Concepts
    {'q': 'Global Network', 'a': 'Internet', 'lvl': 8},
    {'q': 'World Wide Web', 'a': 'WWW', 'lvl': 8},
    {'q': 'Website Address', 'a': 'URL', 'lvl': 8},
    {'q': 'Short-range wireless', 'a': 'Bluetooth', 'lvl': 8},
    // Level 9: Advanced Mix
    {'q': '√81', 'a': '9', 'lvl': 9},
    {'q': '1/2 of 500', 'a': '250', 'lvl': 9},
    {'q': '10% of 1000', 'a': '100', 'lvl': 9},
    {'q': '3³', 'a': '27', 'lvl': 9},
    // Level 10: Master Challenge
    {'q': 'Newton\'s Law 2', 'a': 'F=ma', 'lvl': 10},
    {'q': 'Speed = Dist / ?', 'a': 'Time', 'lvl': 10},
    {'q': 'Density = ? / Vol', 'a': 'Mass', 'lvl': 10},
    {'q': 'Value of pi (π)', 'a': '3.14', 'lvl': 10},
  ];

  late List<String> _questions;
  late List<String> _answers;
  int _currentLevel = 1;
  int _score = 0;
  int _totalMatchesFound = 0;

  Set<String> _matchedQuestions = {};

  late Stopwatch _stopwatch;
  Timer? _timer;
  String _elapsedTime = "00:00";
  int _pointsAwarded = 0;

  // High-Energy State
  int _streak = 0;
  DateTime? _lastMatchTime;
  bool _showCombo = false;
  int _comboMultiplier = 1;
  double _levelProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame({bool resetLevel = false}) {
    if (resetLevel) _currentLevel = 1;

    _timer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = _formatTime(_stopwatch.elapsed);
        });
      }
    });

    List<Map<String, dynamic>> levelData = _allPuzzleData
        .where((e) => e['lvl'] == _currentLevel)
        .toList();
    levelData.shuffle();

    setState(() {
      _questions = levelData.map((e) => e['q'].toString()).toList();
      _answers = levelData.map((e) => e['a'].toString()).toList();
      _answers.shuffle();
      _totalMatchesFound = 0;
      _score = 0;
      _matchedQuestions.clear();
      _pointsAwarded = 0;
      _streak = 0;
      _lastMatchTime = null;
      _showCombo = false;
      _comboMultiplier = 1;
      _levelProgress = 0.0;
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _calculateScore() {
    int baseScore = _currentLevel * 200;
    int maxTimeSeconds = _questions.length * 20;
    int timeBonus = max(
      0,
      (maxTimeSeconds - _stopwatch.elapsed.inSeconds) * 10,
    );

    // Apply Combo Multiplier
    int rawScore = baseScore + timeBonus;
    _score = (rawScore * _comboMultiplier).floor();

    _pointsAwarded = max(5, (_score / 100).floor() + (_currentLevel * 3));
  }

  Future<void> _awardStudyPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) return;
        Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> studentData = Map<String, dynamic>.from(
          userData['studentData'] ?? {},
        );
        int currentPoints = studentData['points'] ?? 0;
        studentData['points'] = currentPoints + _pointsAwarded;
        transaction.update(userDoc, {'studentData': studentData});
      });
    } catch (e) {
      debugPrint("Error awarding points: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Subject Master 🧠",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                fontSize: 18,
              ),
            ),
            Text(
              "Level $_currentLevel - Challenge",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C71D1),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF5C71D1),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5C71D1)),
            onPressed: () => _startNewGame(resetLevel: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Animated Progress Bar
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _levelProgress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5C71D1),
                          const Color(0xFF5C71D1).withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5C71D1).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCard("Time", _elapsedTime, const Color(0xFF5C71D1)),
                    _statCard(
                      "Progress",
                      "$_totalMatchesFound/${_questions.length}",
                      Colors.green,
                    ),
                    _statCard(
                      "Total Score",
                      "$_score",
                      const Color(0xFFF3A31D),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Questions Column
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _questions.map((q) {
                            bool isMatched = _matchedQuestions.contains(q);
                            return FadeInLeft(
                              duration: const Duration(milliseconds: 500),
                              child: isMatched
                                  ? _buildBox(
                                      q,
                                      Colors.green.withOpacity(0.1),
                                      isMatched: true,
                                    )
                                  : Draggable<String>(
                                      data: q,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: 150,
                                          child: _buildBox(
                                            q,
                                            const Color(
                                              0xFF5C71D1,
                                            ).withOpacity(0.9),
                                            isDragging: true,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: _buildBox(
                                        "...",
                                        Colors.grey.shade200,
                                        isPlaceholder: true,
                                      ),
                                      child: _buildBox(
                                        q,
                                        Colors.white,
                                        isQuestion: true,
                                      ),
                                    ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Answers Column
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _answers.map((a) {
                            var matchingData = _allPuzzleData.firstWhere(
                              (e) =>
                                  e['a'].toString() == a &&
                                  e['lvl'] == _currentLevel,
                            );
                            String correspondingQ = matchingData['q']
                                .toString();
                            bool isMatched = _matchedQuestions.contains(
                              correspondingQ,
                            );

                            return FadeInRight(
                              duration: const Duration(milliseconds: 500),
                              child: isMatched
                                  ? _buildBox(
                                      a,
                                      Colors.green.withOpacity(0.1),
                                      isMatched: true,
                                    )
                                  : DragTarget<String>(
                                      onWillAccept: (data) => true,
                                      onAccept: (data) {
                                        if (correspondingQ == data) {
                                          HapticFeedback.lightImpact();
                                          DateTime now = DateTime.now();

                                          setState(() {
                                            if (_lastMatchTime != null &&
                                                now.difference(
                                                      _lastMatchTime!,
                                                    ) <
                                                    const Duration(
                                                      seconds: 8,
                                                    )) {
                                              _streak++;
                                              _comboMultiplier =
                                                  (_streak / 2).floor() + 1;
                                              _showCombo = true;
                                              Timer(
                                                const Duration(seconds: 2),
                                                () {
                                                  if (mounted)
                                                    setState(
                                                      () => _showCombo = false,
                                                    );
                                                },
                                              );
                                            } else {
                                              _streak = 0;
                                              _comboMultiplier = 1;
                                            }
                                            _lastMatchTime = now;

                                            _totalMatchesFound++;
                                            _matchedQuestions.add(data);
                                            _levelProgress =
                                                _totalMatchesFound /
                                                _questions.length;
                                            _calculateScore();

                                            if (_totalMatchesFound ==
                                                _questions.length) {
                                              _stopwatch.stop();
                                              _timer?.cancel();
                                              _awardStudyPoints();
                                              _showWinDialog();
                                            }
                                          });
                                        } else {
                                          HapticFeedback.heavyImpact();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Wrong Answer! Try again.",
                                                textAlign: TextAlign.center,
                                              ),
                                              backgroundColor: Colors.redAccent,
                                              duration: Duration(
                                                milliseconds: 600,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      builder:
                                          (
                                            context,
                                            candidateData,
                                            rejectedData,
                                          ) {
                                            return _buildBox(
                                              a,
                                              Colors.white,
                                              isTarget: true,
                                              isHighlighted:
                                                  candidateData.isNotEmpty,
                                            );
                                          },
                                    ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Drag labels to match their correct results!",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          // Combo Popup Overlay
          if (_showCombo)
            Positioned(
              top: 150,
              right: 40,
              child: ElasticIn(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3A31D), Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "COMBO x$_comboMultiplier",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox(
    String text,
    Color color, {
    bool isQuestion = false,
    bool isTarget = false,
    bool isHighlighted = false,
    bool isMatched = false,
    bool isDragging = false,
    bool isPlaceholder = false,
  }) {
    return Container(
      width: 150,
      height: 75,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF5C71D1).withOpacity(0.2) : color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMatched
              ? Colors.green
              : (isTarget
                    ? const Color(0xFF5C71D1).withOpacity(0.5)
                    : (isPlaceholder
                          ? Colors.grey.shade300
                          : const Color(0xFFEEF2FF))),
          width: isMatched ? 2.5 : 2,
        ),
        boxShadow: (isQuestion && !isMatched && !isDragging && !isPlaceholder)
            ? [
                BoxShadow(
                  color: const Color(0xFF5C71D1).withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: isMatched
              ? Colors.green.shade700
              : (isDragging
                    ? Colors.white
                    : (isPlaceholder ? Colors.grey : const Color(0xFF1E293B))),
        ),
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C71D1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF3A31D),
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Level $_currentLevel Complete!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _winStatRow("Time", _elapsedTime),
              _winStatRow("Level Score", "$_score"),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EBD85).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2EBD85).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFF2EBD85),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "+$_pointsAwarded Study Points",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2EBD85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildRankBadge(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      if (_currentLevel < 10)
                        _currentLevel++;
                      else
                        _currentLevel = 1;
                    });
                    _startNewGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C71D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentLevel < 10 ? "Next Challenge" : "Play Again",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Exit to Games",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _winStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    String rank = "B";
    Color rankColor = Colors.orange;
    if (_stopwatch.elapsed.inSeconds < 30) {
      rank = "S";
      rankColor = const Color(0xFFF3A31D);
    } else if (_stopwatch.elapsed.inSeconds < 60) {
      rank = "A";
      rankColor = const Color(0xFF5C71D1);
    }

    return Column(
      children: [
        const Text(
          "PERFORMANCE RANK",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rankColor.withOpacity(0.3)),
          ),
          child: Text(
            rank,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: rankColor,
            ),
          ),
        ),
      ],
    );
  }
}
