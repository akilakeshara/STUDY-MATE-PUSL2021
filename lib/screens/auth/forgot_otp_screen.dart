import 'package:flutter/material.dart';
import 'reset_password_screen.dart';

class ForgotOtpScreen extends StatefulWidget {
  final String email;
  final String correctOTP;

  const ForgotOtpScreen({
    super.key,
    required this.email,
    required this.correctOTP,
  });

  @override
  State<ForgotOtpScreen> createState() => _ForgotOtpScreenState();
}

class _ForgotOtpScreenState extends State<ForgotOtpScreen> {
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  bool _isError = false;

  void _verifyOtp() {
    final enteredOtp = _otpControllers.map((c) => c.text).join();

    if (enteredOtp.length < 4) {
      _showSnackBar(
        "Please enter the complete 4-digit code",
        Colors.orangeAccent,
      );
      return;
    }

    if (enteredOtp == widget.correctOTP) {
      setState(() => _isError = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      setState(() => _isError = true);
      _showSnackBar("Invalid OTP! Please check again.", Colors.redAccent);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHeaderIcon(),
            const SizedBox(height: 30),
            const Text(
              "Verification",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1C2E),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Enter the 4-digit code sent to",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.blueGrey[300]),
            ),
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5C71D1),
              ),
            ),
            const SizedBox(height: 50),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => _buildOtpBox(index)),
            ),

            const SizedBox(height: 60),
            _buildPrimaryButton(),
          ],
        ),
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
      Icons.mark_email_unread_rounded,
      size: 55,
      color: Color(0xFF5C71D1),
    ),
  );

  Widget _buildOtpBox(int index) {
    return Container(
      width: 60,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isError ? Colors.redAccent : const Color(0xFFEEF2FF),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() => _isError = false);
            if (index < 3) _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 3 && value.isNotEmpty) _verifyOtp();
        },
      ),
    );
  }

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
      onPressed: _verifyOtp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "VERIFY CODE",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
