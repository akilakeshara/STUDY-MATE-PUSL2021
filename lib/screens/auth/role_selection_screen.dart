import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'registration_screen.dart';
import '../sponsor/sponsor_application_screen.dart';
import '../teacher/teacher_application_screen.dart';
import '../../core/page_transition.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  static const Color _bgTop = Color(0xFFF8FAFF);
  static const Color _bgMid = Color(0xFFE8EEFF);
  static const Color _bgBottom = Color(0xFFD7E3FF);
  static const Color _accentBlue = Color(0xFF5C71D1);
  static const Color _primaryTextDark = Color(0xFF1F2433);
  static const Color _secondaryText = Color(0xFF4D5F8A);

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _cardShakeController;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _cardShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _shakeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) _cardShakeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _mainController.dispose();
    _pulseController.dispose();
    _cardShakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgBottom],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.9),
                  radius: 0.9,
                  colors: [_accentBlue.withOpacity(0.14), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, 1.0),
                  radius: 1.1,
                  colors: [_accentBlue.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          _buildPulseCircle(
            top: -size.height * 0.05,
            left: -size.width * 0.1,
            size: size.width * 0.6,
          ),
          _buildPulseCircle(
            bottom: size.height * 0.1,
            right: -size.width * 0.2,
            size: size.width * 0.5,
          ),
          CustomPaint(size: Size.infinite, painter: RoleDotsPainter()),
          ...List.generate(10, (index) => _buildParticle(index)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  _buildHeader(),
                  const SizedBox(height: 26),

                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildGlassCard(
                            index: 0,
                            title: "I am a Student",
                            subtitle: "Learn, track progress & achieve goals.",
                            icon: Icons.school_outlined,
                            onTap: () => _navigate(
                              context,
                              RegistrationScreen(selectedRole: 'Student'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildGlassCard(
                            index: 1,
                            title: "Become a Teacher",
                            subtitle: "Share expertise & inspire minds.",
                            icon: Icons.cast_for_education_rounded,
                            onTap: () => _navigate(
                              context,
                              const TeacherApplicationScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildGlassCard(
                            index: 2,
                            title: "Join as a Sponsor",
                            subtitle: "Empower education through support.",
                            icon: Icons.favorite_border_rounded,
                            onTap: () => _navigate(
                              context,
                              const SponsorApplicationScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildPremiumFooter(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _mainController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _mainController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Text(
                "STUDY MATE • PREMIER",
                style: TextStyle(
                  color: _secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Choose Your\nPath",
              style: TextStyle(
                color: _primaryTextDark,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.8,
                shadows: [
                  Shadow(
                    color: Color(0x40FFFFFF),
                    blurRadius: 14,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Select the role that matches your journey in Study Mate.",
              style: TextStyle(
                color: _secondaryText,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap a role to continue",
              style: TextStyle(
                color: _accentBlue.withOpacity(0.9),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainController,
        _cardShakeController,
        _pulseController,
      ]),
      builder: (context, child) {
        final double slide = Curves.easeOutQuart.transform(
          Interval(0.2 + (index * 0.1), 1.0).transform(_mainController.value),
        );

        final double phase =
            (_pulseController.value * 2 * math.pi) + (index * 0.95);
        final double sway = math.sin(phase) * 2.4;
        final double yWave = math.cos(phase) * 1.1;
        final double shakeSine =
            (1 - _cardShakeController.value) *
            10 *
            (0.5 - (0.5 - _cardShakeController.value).abs());
        final double burst = shakeSine * (index.isEven ? 1 : -1) * 0.7;
        final double phasedShake = sway + burst;

        return Transform.translate(
          offset: Offset(phasedShake, (40 * (1 - slide)) + yWave),
          child: Opacity(opacity: slide, child: child),
        );
      },
      child: SizedBox.expand(
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Stack(
                children: [
                  Positioned(
                    left: -40,
                    top: -60,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentBlue.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -36,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentBlue.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Container(
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.94),
                          const Color(0xFFF3F6FF).withOpacity(0.92),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _accentBlue.withOpacity(0.16),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accentBlue.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _accentBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _accentBlue.withOpacity(0.24),
                            ),
                          ),
                          child: Icon(icon, color: _accentBlue, size: 27),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: _primaryTextDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: _secondaryText,
                                  fontSize: 12.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _accentBlue.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: _accentBlue,
                            size: 18,
                          ),
                        ),
                      ],
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

  Widget _buildPulseCircle({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.1),
            child: Opacity(
              opacity: 0.04 + (_pulseController.value * 0.02),
              child: child,
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF91A7E4).withOpacity(0.36),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(seconds: 6 + (index % 4)),
      builder: (context, double value, child) {
        return Positioned(
          bottom: value * MediaQuery.of(context).size.height,
          left: (index * 40.0) % MediaQuery.of(context).size.width,
          child: Opacity(
            opacity: (1 - value) * 0.3,
            child: const Icon(Icons.circle, size: 4, color: Colors.black12),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        "POWERED BY STUDY MATE",
        style: TextStyle(
          color: _secondaryText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildPremiumFooter() {
    return Column(
      children: [
        _buildFooter(),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            _buildTrustLabel("Secure"),
            _buildTrustDot(),
            _buildTrustLabel("Guided"),
            _buildTrustDot(),
            _buildTrustLabel("Premium"),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _secondaryText.withOpacity(0.9),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.35,
      ),
    );
  }

  Widget _buildTrustDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: _accentBlue, shape: BoxShape.circle),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, PageTransition(child: screen));
  }
}

class RoleDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.03);
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
