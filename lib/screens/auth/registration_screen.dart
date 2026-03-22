import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String selectedRole;
  const RegistrationScreen({super.key, required this.selectedRole});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const String _googleServerClientId =
      '126481720028-85hr9b4l700tja2pv2d4kkr2tbe5754m.apps.googleusercontent.com';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _fullPhoneNumber = "";
  bool _isGoogleInitialized = false;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _isGoogleInitialized = true;
  }

  String _googleErrorMessage(GoogleSignInException e) {
    if (e.code.name == 'canceled') {
      return "Google sign-up canceled";
    }
    if (e.code.name == 'unknownError') {
      return "Google sign-up setup issue. Check Firebase Android SHA-1 and google-services.json package name.";
    }
    return "Google sign-up failed: ${e.code.name}";
  }

  Future<String> _generateSequentialID() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: widget.selectedRole)
        .get();

    int nextNumber = usersSnapshot.docs.length + 1;
    String prefix = widget.selectedRole == "Teacher"
        ? "TCH"
        : (widget.selectedRole == "Sponsor" ? "SPN" : "STU");
    return "$prefix-${nextNumber.toString().padLeft(4, '0')}";
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
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
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          String generatedID = await _generateSequentialID();
          final String resolvedPhone = _fullPhoneNumber.isNotEmpty
              ? _fullPhoneNumber
              : (user.phoneNumber ?? "");

          Map<String, dynamic> userData = {
            'uid': user.uid,
            'firstName': user.displayName ?? _nameController.text.trim(),
            'email': user.email,
            'phone': resolvedPhone,
            'role': widget.selectedRole,
            'emailVerified': true,
            'profileImage': user.photoURL ?? "",
            'createdAt': FieldValue.serverTimestamp(),
          };

          if (widget.selectedRole == "Student") {
            userData['studentData'] = {
              'studentID': generatedID,
              'points': 0,
              'selectedGrade': null,
              'hasCompletedOnboarding': false,
              'recentLessons': [],
            };
          } else if (widget.selectedRole == "Teacher") {
            userData['teacherData'] = {
              'teacherID': generatedID,
              'isVerified': false,
              'subjects': [],
            };
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData);
        }
        _showSuccessAndRedirect();
      }
    } on GoogleSignInException catch (e) {
      final message = _googleErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Google sign-up failed")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Google sign-up failed")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _recoverExistingAccount({
    required String email,
    required String password,
  }) async {
    try {
      final existingCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final existingUser = existingCredential.user;
      if (existingUser == null) return false;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(existingUser.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        String generatedID = await _generateSequentialID();

        Map<String, dynamic> userData = {
          'uid': existingUser.uid,
          'firstName': _nameController.text.trim(),
          'email': email,
          'phone': _fullPhoneNumber,
          'role': widget.selectedRole,
          'emailVerified': existingUser.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.selectedRole == "Student") {
          userData['studentData'] = {
            'studentID': generatedID,
            'points': 0,
            'selectedGrade': null,
            'hasCompletedOnboarding': false,
            'recentLessons': [],
          };
        } else if (widget.selectedRole == "Teacher") {
          userData['teacherData'] = {
            'teacherID': generatedID,
            'isVerified': false,
            'subjects': [],
          };
        }

        await userRef.set(userData);
      }

      if (!mounted) return true;
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This email is already registered. Use Login or Forgot Password.",
            ),
          ),
        );
        return true;
      }
      if (e.code == 'user-not-found') return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Signup failed. Please try again."),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleSignUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullPhoneNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    final String trimmedEmail = _emailController.text.trim().toLowerCase();
    UserCredential? userCredential;

    try {
      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: _passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;
      String generatedID = await _generateSequentialID();

      Map<String, dynamic> userData = {
        'uid': uid,
        'firstName': _nameController.text.trim(),
        'email': trimmedEmail,
        'phone': _fullPhoneNumber,
        'role': widget.selectedRole,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.selectedRole == "Student") {
        userData['studentData'] = {
          'studentID': generatedID,
          'points': 0,
          'selectedGrade': null,
          'hasCompletedOnboarding': false,
          'recentLessons': [],
        };
      } else if (widget.selectedRole == "Teacher") {
        userData['teacherData'] = {
          'teacherID': generatedID,
          'isVerified': false,
          'subjects': [],
        };
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userData);
      } catch (_) {
        await userCredential.user?.delete();
        rethrow;
      }

      if (!mounted) return;
      _showSuccessAndRedirect();
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        final bool recovered = await _recoverExistingAccount(
          email: trimmedEmail,
          password: _passwordController.text.trim(),
        );
        if (recovered) return;
        message = "This email is already registered. Please login.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email address.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak. Use at least 6 characters.";
      } else {
        message = e.message ?? "Signup failed. Please try again.";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFF),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  _buildMiniLogo(),
                  const SizedBox(height: 25),
                  const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1C2E),
                    ),
                  ),
                  Text(
                    "Create ${widget.selectedRole} profile",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 35),
                  _buildCleanField(
                    _nameController,
                    "Full Name",
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildCleanField(
                    _emailController,
                    "Email Address",
                    Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildPhoneField(),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    _passwordController,
                    "Password",
                    _isPasswordVisible,
                    () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPrimaryButton(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildGoogleButton(),
                  const SizedBox(height: 30),
                  _buildLoginRow(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F4FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntlPhoneField(
        initialCountryCode: 'LK',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        dropdownIconPosition: IconPosition.trailing,
        dropdownIcon: const Icon(
          Icons.arrow_drop_down_rounded,
          color: Color(0xFF5C71D1),
        ),
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        flagsButtonMargin: const EdgeInsets.only(left: 15),
        onChanged: (phone) {
          _fullPhoneNumber = phone.completeNumber;
        },
        decoration: const InputDecoration(
          hintText: 'Phone Number',
          hintStyle: TextStyle(color: Color(0xFFBDC1C6), fontSize: 13),
          border: InputBorder.none,
          counterText: "",
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() => InkWell(
    onTap: _isLoading ? null : _handleGoogleSignUp,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 55,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/google_logo.png',
            height: 22,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.login, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            "Continue with Google",
            style: TextStyle(
              color: Color(0xFF1A1C2E),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  void _showSuccessAndRedirect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration successful. Please login."),
        duration: Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(24, 0, 24, 20),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  Widget _buildMiniLogo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
      ],
    ),
    child: const Icon(Icons.school_rounded, size: 45, color: Color(0xFF5C71D1)),
  );
  Widget _buildCleanField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) => Container(
    height: 55,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F4FF)),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF5C71D1), size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool isVisible,
    VoidCallback onToggle,
  ) => Container(
    height: 55,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F4FF)),
    ),
    child: TextField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF5C71D1),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.grey[350],
            size: 18,
          ),
          onPressed: onToggle,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
  Widget _buildPrimaryButton() => Container(
    width: double.infinity,
    height: 55,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF5C71D1), Color(0xFF485CC7)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5C71D1).withOpacity(0.25),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleSignUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        "CREATE ACCOUNT",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    ),
  );
  Widget _buildDivider() => Row(
    children: [
      Expanded(child: Divider(color: Colors.grey[200])),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          "OR",
          style: TextStyle(
            color: Color(0xFFBDBDBD),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey[200])),
    ],
  );
  Widget _buildLoginRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Already have an account? ",
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
      GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        ),
        child: const Text(
          "Sign In",
          style: TextStyle(
            color: Color(0xFF5C71D1),
            fontWeight: FontWeight.w900,
            fontSize: 14,
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
