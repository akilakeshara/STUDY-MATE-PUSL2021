import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  String _extractResetCode(String rawInput) {
    final String trimmed = rawInput.trim();
    if (trimmed.isEmpty) return '';

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('oobCode')) {
      return uri.queryParameters['oobCode']?.trim() ?? '';
    }

    return trimmed;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    String resetCode = _extractResetCode(_codeController.text);
    String newPass = _passController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    if (resetCode.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.orangeAccent);
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar("Passwords do not match!", Colors.redAccent);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'confirmPasswordResetWithCode',
      );
      await callable.call({
        'email': widget.email,
        'code': resetCode,
        'newPassword': newPass,
      });

      await Future.delayed(const Duration(seconds: 1));

      _showSuccessDialog();
    } on FirebaseFunctionsException catch (e) {
      _showSnackBar(e.message ?? "An error occurred", Colors.redAccent);
    } catch (e) {
      _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF4CAF50),
              size: 85,
            ),
            const SizedBox(height: 20),
            const Text(
              "Final Step!",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Password updated successfully for ${widget.email}. Please login with your new password.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1C2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "BACK TO LOGIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _buildCircle(180, const Color(0xFF5C71D1).withOpacity(0.06)),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: _buildCircle(200, const Color(0xFF5C71D1).withOpacity(0.04)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeaderIcon(),
                  const SizedBox(height: 30),
                  const Text(
                    "Secure Account",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1C2E),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Enter the 6-digit reset code from your email and set a new password for\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueGrey[300],
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 50),
                  _buildCodeField(),
                  const SizedBox(height: 18),
                  _buildPasswordField(
                    _passController,
                    "New Password",
                    _isObscureNew,
                    () => setState(() => _isObscureNew = !_isObscureNew),
                  ),
                  const SizedBox(height: 18),
                  _buildPasswordField(
                    _confirmPassController,
                    "Confirm Password",
                    _isObscureConfirm,
                    () =>
                        setState(() => _isObscureConfirm = !_isObscureConfirm),
                  ),
                  const SizedBox(height: 45),
                  _buildPrimaryButton(),
                ],
              ),
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() => Container(
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
    child: const Icon(
      Icons.security_rounded,
      size: 55,
      color: Color(0xFF5C71D1),
    ),
  );

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool isObscure,
    VoidCallback onToggle,
  ) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEEF2FF)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey[100], fontSize: 14),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF5C71D1),
          size: 22,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey[300],
            size: 20,
          ),
          onPressed: onToggle,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    ),
  );

  Widget _buildCodeField() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEEF2FF)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: TextField(
      controller: _codeController,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        hintText: "6-Digit Reset Code",
        hintStyle: TextStyle(color: Colors.blueGrey[100], fontSize: 14),
        prefixIcon: const Icon(
          Icons.pin_outlined,
          color: Color(0xFF5C71D1),
          size: 22,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    ),
  );

  Widget _buildPrimaryButton() => Container(
    width: double.infinity,
    height: 60,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFF5C71D1), Color(0xFF485CC7)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5C71D1).withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleUpdatePassword,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "UPDATE PASSWORD",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    ),
  );

  Widget _buildCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildLoadingOverlay() => Container(
    color: Colors.white.withOpacity(0.7),
    child: const Center(
      child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
    ),
  );
}
