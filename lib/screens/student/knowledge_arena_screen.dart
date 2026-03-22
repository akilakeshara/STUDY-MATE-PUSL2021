import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class ForestQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String subject;
  ForestQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.subject,
  });
}

class KnowledgeArenaScreen extends StatefulWidget {
  const KnowledgeArenaScreen({super.key});

  @override
  State<KnowledgeArenaScreen> createState() => _KnowledgeArenaScreenState();
}

class _KnowledgeArenaScreenState extends State<KnowledgeArenaScreen>
    with TickerProviderStateMixin {
  int _score = 0;
  double _distance = 0;
  bool _isFalling = false;
  int _lives = 3;
  double _highScore = 0;

  int _pitCountdown = 6;
  bool _isPitActive = false;
  int _pitAnswerTimeLeft = 10;
  int _currentQuestionIndex = 0;

  Timer? _engineTimer;
  Timer? _pitAnswerTimer;
  late AnimationController _runController;
  late AnimationController _jumpController;
  late AnimationController _neonController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _jumpAnimation;
  late Animation<double> _neonPulse;

  double _speedMultiplier = 1.0;

  final List<ForestQuestion> _questionBank = [
    ForestQuestion(
      subject: "MATHS",
      question: "If 3x - 4 = 11, what is x?",
      options: ["3", "5", "7", "4"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Gradient of y = -2x + 5?",
      options: ["2", "5", "-2", "-5"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Value of log₁₀ 100?",
      options: ["1", "2", "10", "100"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Area of circle radius 7 (π=22/7)?",
      options: ["44", "154", "49", "77"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Subsets of A = {1, 2, 3}?",
      options: ["3", "6", "8", "9"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Value of cos(60°)?",
      options: ["0.5", "1", "0.86", "0"],
      correctIndex: 0,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Median of: 2, 5, 8, 10, 12?",
      options: ["5", "10", "8", "7"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "MATHS",
      question: "Probability of impossible event?",
      options: ["0", "0.5", "1", "-1"],
      correctIndex: 0,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Powerhouse of the Cell?",
      options: ["Nucleus", "Ribosome", "Mitochondria", "Golgi"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Chemical formula for Glucose?",
      options: ["C12H22O11", "C6H12O6", "CH4", "CO2"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Lens for Myopia correction?",
      options: ["Convex", "Concave", "Cylindrical", "Bifocal"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Acceleration due to gravity?",
      options: ["5", "9.8", "12", "1.6"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Universal Blood Donor?",
      options: ["A", "B", "AB", "O"],
      correctIndex: 3,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Sodium Chloride common name?",
      options: ["Sugar", "Soda", "Salt", "Vinegar"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Gas turning lime water milky?",
      options: ["O2", "H2", "N2", "CO2"],
      correctIndex: 3,
    ),
    ForestQuestion(
      subject: "SCIENCE",
      question: "Plant food making process?",
      options: ["Respiration", "Transpiration", "Photosynthesis", "Digestion"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "Logic gate known as Inverter?",
      options: ["AND", "OR", "NOT", "NAND"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "Base of Hexadecimal system?",
      options: ["2", "8", "10", "16"],
      correctIndex: 3,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "Which is volatile memory?",
      options: ["ROM", "Disk", "RAM", "Flash"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "Binary value of decimal 5?",
      options: ["100", "101", "110", "111"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "TCP/IP stands for?",
      options: [
        "Tech Control",
        "Transmission Control",
        "Transfer Center",
        "Total Connection",
      ],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "HTML tag for hyperlink?",
      options: ["<link>", "<a>", "<href>", "<url>"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "Example of Input device?",
      options: ["Monitor", "Printer", "Speaker", "Scanner"],
      correctIndex: 3,
    ),
    ForestQuestion(
      subject: "ICT",
      question: "Software to manage files?",
      options: ["OS", "Compiler", "Assembler", "Browser"],
      correctIndex: 0,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Correct spelling?",
      options: ["Accommodation", "Acomodation", "Accomodation", "Acommodation"],
      correctIndex: 0,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Opposite of 'Victory'?",
      options: ["Success", "Defeat", "Win", "Gain"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "She sings ____ morning.",
      options: ["for", "since", "from", "at"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Synonym of 'Enormous'?",
      options: ["Tiny", "Huge", "Weak", "Soft"],
      correctIndex: 1,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Animal doctor name?",
      options: ["Doctor", "Dentist", "Veterinarian", "Surgeon"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Past tense of 'Write'?",
      options: ["Written", "Writes", "Wrote", "Writing"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Which of these is a noun?",
      options: ["Beautiful", "Quickly", "Happiness", "Jump"],
      correctIndex: 2,
    ),
    ForestQuestion(
      subject: "ENGLISH",
      question: "Select the odd one out:",
      options: ["Apple", "Orange", "Potato", "Banana"],
      correctIndex: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _runController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).animate(CurvedAnimation(parent: _runController, curve: Curves.easeInOut));
    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -100,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -100,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 50,
      ),
    ]).animate(_jumpController);
    _neonPulse = Tween<double>(begin: 0.2, end: 1.0).animate(_neonController);

    _loadHighScore();
    _startNewRun();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getDouble('knowledge_arena_highscore') ?? 0;
    });
  }

  Future<void> _updateHighScore() async {
    if (_distance > _highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('knowledge_arena_highscore', _distance);
      setState(() {
        _highScore = _distance;
      });
    }
  }

  @override
  void dispose() {
    _engineTimer?.cancel();
    _pitAnswerTimer?.cancel();
    _runController.dispose();
    _jumpController.dispose();
    _neonController.dispose();
    super.dispose();
  }

  void _startNewRun() {
    _engineTimer?.cancel();
    _pitAnswerTimer?.cancel();
    _questionBank.shuffle();
    setState(() {
      _distance = 0;
      _score = 0;
      _lives = 3;
      _isFalling = false;
      _isPitActive = false;
      _pitCountdown = 6;
      _currentQuestionIndex = 0;
    });
    _runGameEngine();
  }

  void _runGameEngine() {
    _engineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isFalling || _isPitActive) return;
      setState(() {
        _speedMultiplier = 1.0 + (_distance / 500).floor() * 0.2;
        _distance += 25 * _speedMultiplier;
        if (_pitCountdown > 0) {
          _pitCountdown--;
        } else {
          _triggerPitTrap();
        }
      });
    });
  }

  void _triggerPitTrap() {
    setState(() {
      _isPitActive = true;
      _pitAnswerTimeLeft = 10;
    });
    _startPitTimer();
  }

  void _startPitTimer() {
    _pitAnswerTimer?.cancel();
    _pitAnswerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPitActive) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_pitAnswerTimeLeft > 0) {
          _pitAnswerTimeLeft--;
        } else {
          _handleDeath();
        }
      });
    });
  }

  void _handlePitAnswer(int index) {
    bool isCorrect = index == _questionBank[_currentQuestionIndex].correctIndex;
    if (isCorrect) {
      _pitAnswerTimer?.cancel();
      _jumpController.forward(from: 0);
      setState(() {
        _score += 20;
        _isPitActive = false;
        _pitCountdown = 6;
        _currentQuestionIndex =
            (_currentQuestionIndex + 1) % _questionBank.length;
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _lives--;
      });
      if (_lives <= 0) {
        _handleDeath();
      } else {
        _pitAnswerTimer?.cancel();
        setState(() {
          _isPitActive = false;
          _pitCountdown = 4;
          _currentQuestionIndex =
              (_currentQuestionIndex + 1) % _questionBank.length;
        });
      }
    }
  }

  void _handleDeath() {
    _pitAnswerTimer?.cancel();
    _updateHighScore();
    setState(() {
      _isFalling = true;
      _isPitActive = false;
    });
    Future.delayed(const Duration(seconds: 2), () => _startNewRun());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "KNOWLEDGE ARENA",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Parallax Layers
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_runController, _jumpController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: RealisticForestPainter(
                    _distance,
                    _bounceAnimation.value,
                    _jumpAnimation.value,
                  ),
                );
              },
            ),
          ),

          // Character Shadow & Dust Particles
          Positioned(
            bottom: 125,
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bounceAnimation, _jumpAnimation]),
              builder: (context, child) {
                double jumpOffset = _jumpAnimation.value.abs() / 100;
                double s =
                    (1.0 - (_bounceAnimation.value / 30)) * (1.0 - jumpOffset);
                return Column(
                  children: [
                    if (!_isFalling &&
                        !_isPitActive &&
                        _bounceAnimation.value < 2)
                      FadeIn(
                        child: const Icon(
                          Icons.cloud_rounded,
                          size: 15,
                          color: Colors.white12,
                        ),
                      ),
                    Container(
                      width: 80 * s,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(
                          0.4 * (1.0 - jumpOffset),
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.2 * (1.0 - jumpOffset),
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Fluid Lottie Runner
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            bottom: _isFalling
                ? -400
                : (130 +
                      (_isPitActive ? 0 : _bounceAnimation.value) +
                      _jumpAnimation.value),
            left: MediaQuery.of(context).size.width / 2 - 70,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 500),
              turns: _isFalling ? 0.5 : 0,
              child: Transform.rotate(
                angle: _isFalling
                    ? 0
                    : (0.15 * (_speedMultiplier - 0.8)), // Aggressive Lean
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Lottie.network(
                    "https://lottie.host/81a96752-0dcb-49ad-a7dd-f5480434460a/WjTToS3gJd.json",
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.directions_run_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          _buildHUD(),

          if (_isPitActive) _buildPitPanel(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    double progress = (_distance % 500) / 500;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                color: const Color(0xFF10B981),
                minHeight: 4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNeonStat("COINS", "$_score", Colors.amber),
                    _buildLives(),
                    _buildNeonStat(
                      "METERS",
                      "${_distance.toInt()}m",
                      Colors.greenAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    "BEST: ${_highScore.toInt()}m",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (!_isPitActive)
                  FadeInUp(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.4),
                            Colors.red.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "TRAP ENGAGING IN: ${_pitCountdown}s",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLives() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: index < _lives
                ? Pulse(
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.favorite_outline_rounded,
                    color: Colors.white12,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonStat(String label, String value, Color color) {
    return AnimatedBuilder(
      animation: _neonPulse,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1 * _neonPulse.value),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: color.withOpacity(0.3 * _neonPulse.value),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: color.withOpacity(0.6), blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPitPanel() {
    final q = _questionBank[_currentQuestionIndex];
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: ZoomIn(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.85),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white10, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.15),
                    blurRadius: 50,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.6),
                          ),
                        ),
                        child: Text(
                          q.subject,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_pitAnswerTimeLeft}s",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    q.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () => _handlePitAnswer(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white10),
                          ),
                        ),
                        child: Text(
                          q.options[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RealisticForestPainter extends CustomPainter {
  final double distance;
  final double bounce;
  final double jump;
  RealisticForestPainter(this.distance, this.bounce, this.jump);

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF020617),
          const Color(0xFF064E3B).withOpacity(0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      skyPaint,
    );

    double horizonY = size.height * 0.48;

    // Star Layer (Sparkles)
    final starPaint = Paint()..color = Colors.white.withOpacity(0.1);
    for (int i = 0; i < 15; i++) {
      double x = (i * 180 - (distance * 0.02) % 1800);
      canvas.drawCircle(Offset(x, 50 + (i % 5) * 40), 1, starPaint);
    }

    // Cloud Layer
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.02);
    for (int i = 0; i < 5; i++) {
      double x = (i * 350 - (distance * 0.04) % 1750);
      canvas.drawCircle(Offset(x, 120), 50, cloudPaint);
      canvas.drawCircle(Offset(x + 40, 100), 60, cloudPaint);
    }

    // Layer 1: Distant Forest (Parallax 0.1)
    _drawParallaxLayer(
      canvas,
      size,
      horizonY,
      distance * 0.1,
      const Color(0xFF022C22),
      70,
      45,
    );

    // Layer 2: Mid Forest (Parallax 0.3)
    _drawParallaxLayer(
      canvas,
      size,
      horizonY + 15,
      distance * 0.3,
      const Color(0xFF022C22).withOpacity(0.9),
      110,
      70,
    );

    // Ground
    final groundPaint = Paint()
      ..color = const Color(0xFF064E3B).withOpacity(0.8);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      groundPaint,
    );

    // Road (Perspective)
    final roadPaint = Paint()..color = const Color(0xFF020617);
    double cX = size.width / 2;
    final path = Path()
      ..moveTo(cX - 25, horizonY)
      ..lineTo(cX + 25, horizonY)
      ..lineTo(size.width * 1.8, size.height)
      ..lineTo(-size.width * 0.8, size.height)
      ..close();
    canvas.drawPath(path, roadPaint);

    // Road Lines (High Quality)
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 3;
    for (int i = 0; i < 20; i++) {
      double yRel = (i + (distance % 40) / 40) / 10;
      double y = horizonY + (yRel * (size.height - horizonY));
      if (y > horizonY && y < size.height) {
        double s = (y - horizonY) / (size.height - horizonY);
        double w = 80 * s;
        canvas.drawRect(Rect.fromLTWH(cX - (w / 2), y, w, 12 * s), linePaint);
      }
    }

    // Motion Blur speed lines
    if (distance > 300) {
      final blurPaint = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..strokeWidth = 1;
      for (int i = 0; i < 8; i++) {
        double lx = (i * 200 + (distance * 5) % 1600);
        canvas.drawLine(Offset(lx, 150), Offset(lx + 80, 150), blurPaint);
      }
    }

    // Layer 3: Grass Layer (Vibrant)
    final grassPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.2);
    for (int i = 0; i < 15; i++) {
      double yRel = (i + (distance % 30) / 30) / 10;
      double y = horizonY + (yRel * (size.height - horizonY));
      double s = (y - horizonY) / (size.height - horizonY);
      double offsetX = 320 * s;
      canvas.drawCircle(Offset(cX - offsetX - 80, y), 35 * s, grassPaint);
      canvas.drawCircle(Offset(cX + offsetX + 80, y), 35 * s, grassPaint);
    }
  }

  void _drawParallaxLayer(
    Canvas canvas,
    Size size,
    double y,
    double dist,
    Color color,
    double h,
    double w,
  ) {
    final p = Paint()..color = color;
    for (int i = -2; i < 15; i++) {
      double x = ((i * 180) - (dist % 180));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y - h, w, h),
          Radius.circular(w / 3),
        ),
        p,
      );
      canvas.drawCircle(Offset(x + w / 2, y - h), w * 0.9, p);
    }
  }

  @override
  bool shouldRepaint(RealisticForestPainter old) =>
      old.distance != distance || old.bounce != bounce || old.jump != jump;
}
