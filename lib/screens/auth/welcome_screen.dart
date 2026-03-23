import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const Color _bgTop = Color(0xFFF8FAFF);
  static const Color _bgMid = Color(0xFFE8EEFF);
  static const Color _bgBottom = Color(0xFFD7E3FF);
  static const Color _accentGold = Color(0xFF5C71D1);
  static const Color _primaryTextDark = Color(0xFF1F2433);
  static const Color _secondaryText = Color(0xFF4D5F8A);

  late AnimationController _shakeController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..forward();

    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) _shakeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _safeNavigate(Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
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
                  colors: [_accentGold.withOpacity(0.14), Colors.transparent],
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
                  colors: [
                    const Color(0xFF5C71D1).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          _buildPulseCircle(
            top: -screenHeight * 0.05,
            left: -screenWidth * 0.1,
            size: screenWidth * 0.6,
          ),
          _buildPulseCircle(
            bottom: screenHeight * 0.1,
            right: -screenWidth * 0.2,
            size: screenWidth * 0.5,
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isCompact = constraints.maxHeight < 760;
                final double imageHeight = isCompact ? 140 : 210;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isCompact ? 6 : 12),
                      _buildEntranceItem(
                        intervalStart: 0.0,
                        intervalEnd: 0.35,
                        child: _buildWelcomeLabel(),
                      ),
                      const SizedBox(height: 8),
                      _buildEntranceItem(
                        intervalStart: 0.08,
                        intervalEnd: 0.45,
                        child: _buildStylishHeader(constraints.maxWidth),
                      ),
                      const SizedBox(height: 8),
                      _buildEntranceItem(
                        intervalStart: 0.14,
                        intervalEnd: 0.52,
                        child: Text(
                          "Smart learning made simple",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            color: _secondaryText,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildEntranceItem(
                        intervalStart: 0.18,
                        intervalEnd: 0.58,
                        child: Text(
                          "Learn Smarter • Achieve Faster",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 13,
                            color: _accentGold,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _buildEntranceItem(
                        intervalStart: 0.24,
                        intervalEnd: 0.72,
                        child: AnimatedBuilder(
                          animation: _floatingController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                10 *
                                    Curves.easeInOut.transform(
                                      _floatingController.value,
                                    ),
                              ),
                              child: child,
                            );
                          },
                          child: SizedBox(
                            height: imageHeight + 36,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: imageHeight * 0.9,
                                  height: imageHeight * 0.9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accentGold.withOpacity(0.22),
                                        blurRadius: 50,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/welcome.png',
                                  height: imageHeight,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.auto_stories_rounded,
                                        size: 80,
                                        color: Colors.white24,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(height: isCompact ? 16 : 22),
                      _buildEntranceItem(
                        intervalStart: 0.4,
                        intervalEnd: 1.0,
                        child: _buildActionButtons(isCompact),
                      ),
                      SizedBox(height: isCompact ? 10 : 12),
                      _buildEntranceItem(
                        intervalStart: 0.5,
                        intervalEnd: 1.0,
                        child: _buildTrustRow(),
                      ),
                      SizedBox(height: isCompact ? 4 : 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntranceItem({
    required double intervalStart,
    required double intervalEnd,
    required Widget child,
  }) {
    final Animation<double> animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, item) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 18),
            child: item,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildTrustRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        _buildTrustLabel("Secure"),
        _buildTrustDot(),
        _buildTrustLabel("Fast"),
        _buildTrustDot(),
        _buildTrustLabel("Personalized"),
      ],
    );
  }

  Widget _buildTrustLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        color: _secondaryText.withOpacity(0.9),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildTrustDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: _accentGold, shape: BoxShape.circle),
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

  Widget _buildStylishHeader(double screenWidth) {
    return Column(
      children: [
        Text(
          "STUDY MATE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: screenWidth * 0.1,
            fontWeight: FontWeight.w900,
            color: _primaryTextDark,
            letterSpacing: 2.0,
            shadows: const [
              Shadow(
                blurRadius: 15.0,
                color: Colors.white70,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _accentGold,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _accentGold.withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_rounded, color: _accentGold, size: 16),
          SizedBox(width: 8),
          Text(
            "WELCOME TO",
            style: TextStyle(
              fontSize: 12,
              color: _secondaryText,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isCompact) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        children: [
          _buildAnimatedButton(
            child: SizedBox(
              width: double.infinity,
              height: isCompact ? 50 : 54,
              child: FilledButton.icon(
                onPressed: () => _safeNavigate(const RoleSelectionScreen()),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: Text(
                  "GET STARTED",
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF425FCB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: _accentGold.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          SizedBox(
            width: double.infinity,
            height: isCompact ? 50 : 54,
            child: OutlinedButton.icon(
              onPressed: () => _safeNavigate(const LoginScreen()),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                "LOGIN",
                style: TextStyle(
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryTextDark,
                backgroundColor: Colors.white.withOpacity(0.72),
                side: BorderSide(
                  color: _accentGold.withOpacity(0.55),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({required Widget child}) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue =
            (1 - _shakeController.value) *
            8 *
            (0.5 - (0.5 - _shakeController.value).abs());
        return Transform.translate(offset: Offset(sineValue, 0), child: child);
      },
      child: child,
    );
  }
}
