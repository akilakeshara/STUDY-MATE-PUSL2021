import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  final List<IconData> _allIcons = [
    Icons.menu_book_rounded,
    Icons.edit_note_rounded,
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.psychology_rounded,
    Icons.auto_awesome_rounded,
    Icons.biotech_rounded,
    Icons.functions_rounded,
    Icons.language_rounded,
    Icons.music_note_rounded,
    Icons.brush_rounded,
    Icons.history_edu_rounded,
  ];

  late List<IconData> _gameIcons;
  late List<bool> _isFlipped;
  late List<bool> _isMatched;

  int _currentLevel = 1;
  int? _firstIndex;
  bool _wait = false;
  int _matchesFound = 0;
  int _tries = 0;

  late Stopwatch _stopwatch;
  Timer? _timer;
  String _elapsedTime = "00:00";
  int _score = 0;
  int _pointsAwarded = 0;

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

  int get _gridCount {
    if (_currentLevel == 1) return 6;
    if (_currentLevel == 2) return 12;
    if (_currentLevel == 3) return 16;
    if (_currentLevel == 4) return 20;
    return 24;
  }

  int get _crossAxisCount {
    if (_currentLevel == 1) return 2;
    if (_currentLevel <= 3) return 3;
    return 4;
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

    setState(() {
      int pairsNeeded = _gridCount ~/ 2;
      List<IconData> selectedIcons = _allIcons.take(pairsNeeded).toList();
      _gameIcons = [...selectedIcons, ...selectedIcons]..shuffle();

      _isFlipped = List.generate(_gridCount, (_) => false);
      _isMatched = List.generate(_gridCount, (_) => false);
      _firstIndex = null;
      _wait = false;
      _matchesFound = 0;
      _tries = 0;
      _score = 0;
      _pointsAwarded = 0;
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _calculateScore() {
    // Base points for level
    int baseScore = _currentLevel * 100;

    // Tries bonus: Max possible tries (estimated) - actual tries
    int maxExpectedTries = _gridCount * 2;
    int triesBonus = max(0, (maxExpectedTries - _tries) * 10);

    // Time bonus: (Max time - actual time)
    int maxTimeSeconds = _currentLevel * 60;
    int timeBonus = max(0, (maxTimeSeconds - _stopwatch.elapsed.inSeconds) * 5);

    _score = baseScore + triesBonus + timeBonus;

    // Award "Real" study points: 1 point for every 200 game score, minimum 5 points per level
    _pointsAwarded = max(5, (_score / 100).floor() + (_currentLevel * 2));
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

  void _onCardTap(int index) {
    if (_wait || _isFlipped[index] || _isMatched[index]) return;

    setState(() {
      _isFlipped[index] = true;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _tries++;
      if (_gameIcons[_firstIndex!] == _gameIcons[index]) {
        _isMatched[_firstIndex!] = true;
        _isMatched[index] = true;
        _matchesFound++;
        _firstIndex = null;
        if (_matchesFound == _gridCount ~/ 2) {
          _stopwatch.stop();
          _timer?.cancel();
          _calculateScore();
          _awardStudyPoints();
          _showWinDialog();
        }
      } else {
        _wait = true;
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _isFlipped[_firstIndex!] = false;
              _isFlipped[index] = false;
              _firstIndex = null;
              _wait = false;
            });
          }
        });
      }
    }
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
                  color: Color(0xFFC5A059),
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
              _winStatRow("Time Taken", _elapsedTime),
              _winStatRow("Total Tries", "$_tries"),
              _winStatRow("High Score", "$_score"),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3A31D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF3A31D).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFF3A31D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "+$_pointsAwarded Study Points",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF3A31D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _currentLevel++);
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
                  child: const Text(
                    "Next Level",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
                  "Exit to Menu",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memory Match',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                fontSize: 18,
              ),
            ),
            Text(
              'Level $_currentLevel',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard("Time", _elapsedTime, const Color(0xFF5C71D1)),
                _statCard(
                  "Pairs Found",
                  "$_matchesFound/${_gridCount ~/ 2}",
                  Colors.green,
                ),
                _statCard("Total Tries", "$_tries", Colors.orange),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: _currentLevel == 1 ? 1.0 : 0.85,
              ),
              itemCount: _gridCount,
              itemBuilder: (context, index) {
                return _MemoryCard(
                  key: ValueKey('card_${_currentLevel}_$index'),
                  icon: _gameIcons[index],
                  isFlipped: _isFlipped[index],
                  isMatched: _isMatched[index],
                  onTap: () => _onCardTap(index),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              "Progress through levels for more challenge!",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final IconData icon;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;

  const _MemoryCard({
    super.key,
    required this.icon,
    required this.isFlipped,
    required this.isMatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final isBack = rotate.value > pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotate.value),
                alignment: Alignment.center,
                child: isBack ? Container() : child,
              );
            },
          );
        },
        child: isFlipped || isMatched
            ? Container(
                key: const ValueKey(true),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMatched
                        ? Colors.green.withOpacity(0.4)
                        : const Color(0xFF5C71D1).withOpacity(0.2),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMatched
                          ? Colors.green.withOpacity(0.1)
                          : const Color(0xFF5C71D1).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isMatched ? Colors.green : const Color(0xFF5C71D1),
                    size: 32,
                  ),
                ),
              )
            : Container(
                key: const ValueKey(false),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C71D1), Color(0xFF8B9BE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5C71D1).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.question_mark_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 32,
                  ),
                ),
              ),
      ),
    );
  }
}
