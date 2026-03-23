import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/sponsor/sponsor_dashboard.dart';
import 'screens/sponsor/impact_dashboard.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/student/onboarding_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';

// Global Theme Notifier for easy access across the app
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  // Load saved theme preference
  bool isDark = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDarkMode') ?? false;
  } catch (e) {
    // If it fails (e.g., during hot restart on some devices), fallback to light mode
    debugPrint("SharedPreferences error: $e");
  }
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Study Mate App',
          scrollBehavior: const _NoElasticScrollBehavior(),
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            textTheme: GoogleFonts.poppinsTextTheme(),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5C71D1),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F9FD),
            cardColor: Colors.white,
            dividerColor: Colors.grey.withOpacity(0.1),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5C71D1),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF141625),
            cardColor: const Color(0xFF1F213A),
            dividerColor: Colors.white.withOpacity(0.05),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthSessionGate(),
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/role-selection': (context) => const RoleSelectionScreen(),
            '/admin-dashboard': (context) => const AdminDashboard(),
            '/sponsor-dashboard': (context) => const SponsorDashboard(),
            '/impact-dashboard': (context) => const ImpactDashboard(),
          },
        );
      },
    );
  }
}

class _NoElasticScrollBehavior extends MaterialScrollBehavior {
  const _NoElasticScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class AuthSessionGate extends StatefulWidget {
  const AuthSessionGate({super.key});

  @override
  State<AuthSessionGate> createState() => _AuthSessionGateState();
}

class _AuthSessionGateState extends State<AuthSessionGate> {
  bool _showStartupSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      setState(() => _showStartupSplash = false);
    });
  }

  Future<Widget> _resolveStartScreen(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      await FirebaseAuth.instance.signOut();
      return const WelcomeScreen();
    }

    final data = userDoc.data() as Map<String, dynamic>;
    String role = (data['role'] ?? 'Student').toString().trim().toLowerCase();

    if (role != 'teacher' && data['teacherData'] is Map<String, dynamic>) {
      final String status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'approved' || status == 'pending') {
        role = 'teacher';
      }
    }

    if (role == 'admin') {
      return const AdminDashboard();
    }

    if (role == 'teacher') {
      final String status = (data['status'] ?? 'Pending')
          .toString()
          .toLowerCase();
      if (status == 'approved') {
        return const TeacherHomeScreen();
      }
      await FirebaseAuth.instance.signOut();
      return const WelcomeScreen();
    }

    if (role == 'sponsor') {
      final String status = (data['status'] ?? 'Pending')
          .toString()
          .toLowerCase();
      if (status == 'approved') {
        return const SponsorDashboard();
      }
      await FirebaseAuth.instance.signOut();
      return const WelcomeScreen();
    }

    final studentData = data['studentData'] as Map<String, dynamic>?;
    final bool hasCompletedOnboarding =
        studentData?['hasCompletedOnboarding'] == true;
    return hasCompletedOnboarding
        ? const StudentHomeScreen()
        : const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_showStartupSplash) {
      return const _AppLoadingScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AppLoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const WelcomeScreen();
        }

        return FutureBuilder<Widget>(
          future: _resolveStartScreen(user),
          builder: (context, routeSnapshot) {
            if (routeSnapshot.connectionState == ConnectionState.waiting) {
              return const _AppLoadingScreen();
            }

            if (routeSnapshot.hasError || !routeSnapshot.hasData) {
              return const WelcomeScreen();
            }

            return routeSnapshot.data!;
          },
        );
      },
    );
  }
}

class _AppLoadingScreen extends StatefulWidget {
  const _AppLoadingScreen();

  @override
  State<_AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<_AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FAFF),
                  Color(0xFFE8EEFF),
                  Color(0xFFD7E3FF),
                ],
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
                  colors: [
                    const Color(0xFF5C71D1).withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF91A7E4).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF5C71D1).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF5C71D1).withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Color(0xFF5C71D1),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "WELCOME TO",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4D5F8A),
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'STUDY MATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1F2433),
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Preparing your learning space...',
                    style: TextStyle(
                      color: Color(0xFF4D5F8A),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Learn Smarter • Achieve Faster',
                    style: TextStyle(
                      color: Color(0xFF5C71D1),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final double scale = 1 + (_pulseController.value * 0.04);
                      final double opacity =
                          0.84 + (_pulseController.value * 0.16);
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5C71D1,
                                ).withOpacity(0.22),
                                blurRadius: 45,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/welcome.png',
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.black26,
                                size: 90,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF425FCB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Secure • Fast • Personalized',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF4D5F8A),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
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
