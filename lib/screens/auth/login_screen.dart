import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'role_selection_screen.dart';
import 'forgot_password_screen.dart';
import '../student/student_home_screen.dart';
import '../student/onboarding_screen.dart';
import '../sponsor/sponsor_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../teacher/teacher_home_screen.dart';
import '../../core/page_transition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _googleServerClientId =
      '126481720028-85hr9b4l700tja2pv2d4kkr2tbe5754m.apps.googleusercontent.com';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isGoogleInitialized = false;
  bool isPasswordVisible = false;
  bool isLoading = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _isGoogleInitialized = true;
  }

  String _googleErrorMessage(GoogleSignInException e) {
    if (e.code.name == 'canceled') {
      return "Google sign-in canceled";
    }
    if (e.code.name == 'unknownError') {
      return "Google sign-in setup issue. Check Firebase Android SHA-1 and google-services.json package name.";
    }
    return "Google sign-in failed: ${e.code.name}";
  }

  Future<void> _routeUserByRole(
    String dbRole,
    Map<String, dynamic> data,
  ) async {
    print("DEBUG: User Role from DB is -> '$dbRole'");

    Widget nextScreen;
    final String role = dbRole.trim().toLowerCase();

    if (role == "admin") {
      print("DEBUG: Navigating to Admin Dashboard");
      nextScreen = const AdminDashboard();
    } else if (role == "teacher") {
      String status = (data['status'] ?? 'Pending').toString().toLowerCase();
      if (status == 'approved') {
        nextScreen = const TeacherHomeScreen();
      } else {
        await FirebaseAuth.instance.signOut();
        _showErrorSnackBar("Access Denied: Pending Admin Approval");
        return;
      }
    } else if (role == "sponsor") {
      String status = (data['status'] ?? 'Pending').toString().toLowerCase();
      if (status == 'approved') {
        nextScreen = const SponsorDashboard();
      } else {
        await FirebaseAuth.instance.signOut();
        _showErrorSnackBar("Access Denied: Pending Admin Approval");
        return;
      }
    } else {
      var studentData = data['studentData'] as Map<String, dynamic>?;
      bool hasCompletedOnboarding =
          studentData?['hasCompletedOnboarding'] ?? false;
      nextScreen = hasCompletedOnboarding
          ? const StudentHomeScreen()
          : const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageTransition(child: nextScreen),
    );
  }

  Future<String> _resolveEffectiveRole(
    String currentRole,
    String uid,
    Map<String, dynamic> data,
  ) async {
    final String normalizedRole = currentRole.trim().toLowerCase();
    if (normalizedRole == 'teacher') return currentRole;

    final bool hasTeacherData = data['teacherData'] is Map<String, dynamic>;
    if (!hasTeacherData) return currentRole;

    final String status = (data['status'] ?? '').toString().toLowerCase();
    if (status == 'approved' || status == 'pending') {
      final String roleToPersist = 'Teacher';
      if (normalizedRole != 'teacher') {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'role': roleToPersist,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return roleToPersist;
    }

    return currentRole;
  }

  Future<Map<String, dynamic>> _getOrCreateUserProfile(User user) async {
    final DocumentReference userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot userDoc = await userRef.get();
    final existingData = userDoc.data();
    if (existingData is Map<String, dynamic>) {
      return existingData;
    }

    final String normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final String firstName = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : normalizedEmail.split('@').first;

    final Map<String, dynamic> recoveredData = {
      'uid': user.uid,
      'firstName': firstName,
      'email': normalizedEmail,
      'role': 'Student',
      'emailVerified': user.emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'studentData': {
        'points': 0,
        'selectedGrade': null,
        'hasCompletedOnboarding': false,
        'recentLessons': [],
      },
    };

    await userRef.set(recoveredData, SetOptions(merge: true));
    return recoveredData;
  }

  Future<void> _handleLogin() async {
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Please enter your email and password");
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        _showErrorSnackBar("Login failed. Please try again.");
        return;
      }

      await user.reload();
      final User? refreshedUser = FirebaseAuth.instance.currentUser;

      final Map<String, dynamic> data = await _getOrCreateUserProfile(
        refreshedUser ?? user,
      );
      final String effectiveRole = await _resolveEffectiveRole(
        (data['role'] ?? "Student").toString(),
        (refreshedUser ?? user).uid,
        data,
      );
      await _routeUserByRole(effectiveRole, data);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? "Invalid login credentials");
    } catch (e) {
      _showErrorSnackBar("An error occurred during login");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google ID token is missing.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        _showErrorSnackBar("Google Login Failed. Please try again.");
        return;
      }

      final Map<String, dynamic> data = await _getOrCreateUserProfile(user);
      final String effectiveRole = await _resolveEffectiveRole(
        (data['role'] ?? "Student").toString(),
        user.uid,
        data,
      );
      await _routeUserByRole(effectiveRole, data);
    } on GoogleSignInException catch (e) {
      _showErrorSnackBar(_googleErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? "Google Login Failed");
    } catch (e) {
      _showErrorSnackBar("Google Login Failed. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: _buildCircle(250, const Color(0xFF5C71D1).withOpacity(0.05)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildCircle(200, const Color(0xFF5C71D1).withOpacity(0.03)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeaderLogo(),
                  const SizedBox(height: 40),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1C2E),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                    Text(
                      "Sign in to Study Mate",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[300],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 45),
                  _buildTextField(
                    _emailController,
                    "Email Address",
                    Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  _buildPasswordField(),
                  _buildForgotPasswordLink(),
                  const SizedBox(height: 35),
                  _buildPrimaryButton(),
                  const SizedBox(height: 25),
                  _buildDivider(),
                  const SizedBox(height: 25),
                  _buildGoogleButton(),
                  const SizedBox(height: 40),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
  Widget _buildHeaderLogo() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5C71D1).withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: const Icon(Icons.school_rounded, size: 60, color: Color(0xFF5C71D1)),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEEF2FF)),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.blueGrey[200],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF5C71D1), size: 22),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    ),
  );

  Widget _buildPasswordField() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFEEF2FF)),
    ),
    child: TextField(
      controller: _passwordController,
      obscureText: !isPasswordVisible,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: TextStyle(
          color: Colors.blueGrey[200],
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF5C71D1),
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: Colors.blueGrey[200],
            size: 20,
          ),
          onPressed: () =>
              setState(() => isPasswordVisible = !isPasswordVisible),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    ),
  );

  Widget _buildPrimaryButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: isLoading ? null : _handleLogin,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2D3448),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        "SIGN IN",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    ),
  );
  Widget _buildGoogleButton() => InkWell(
    onTap: isLoading ? null : _handleGoogleLogin,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEDF5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.login, size: 24, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          const Text(
            "Continue with Google",
            style: TextStyle(
              color: Color(0xFF1A1C2E),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _buildDivider() => Row(
    children: [
      Expanded(child: Divider(color: Colors.grey[100], thickness: 2)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          "OR",
          style: TextStyle(
            color: Color(0xFFE0E0E0),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey[100], thickness: 2)),
    ],
  );
  Widget _buildForgotPasswordLink() => Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: () => Navigator.push(
        context,
        PageTransition(child: const ForgotPasswordScreen()),
      ),
      child: const Text(
        "Forgot Password?",
        style: TextStyle(
          color: Color(0xFF5C71D1),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    ),
  );
  Widget _buildRegisterLink() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Don't have an account? ",
        style: TextStyle(
          color: Colors.blueGrey[300],
          fontWeight: FontWeight.w600,
        ),
      ),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageTransition(child: const RoleSelectionScreen()),
        ),
        child: const Text(
          "Sign Up",
          style: TextStyle(
            color: Color(0xFF5C71D1),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    ],
  );
  Widget _buildLoadingOverlay() => Container(
    color: Colors.white.withOpacity(0.7),
    child: const Center(
      child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
    ),
  );
}
