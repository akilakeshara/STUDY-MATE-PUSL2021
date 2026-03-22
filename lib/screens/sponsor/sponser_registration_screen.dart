import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorRegistrationScreen extends StatefulWidget {
  const SponsorRegistrationScreen({super.key});

  @override
  State<SponsorRegistrationScreen> createState() =>
      _SponsorRegistrationScreenState();
}

class _SponsorRegistrationScreenState extends State<SponsorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  String? _organizationType = 'Individual';
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<String> _generateSequentialSponsorID() async {
    final QuerySnapshot applicationsSnapshot = await FirebaseFirestore.instance
        .collection('sponsor_applications')
        .get()
        .timeout(const Duration(seconds: 20));

    return "SPN-${(applicationsSnapshot.docs.length + 1).toString().padLeft(4, '0')}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _showSuccessAndGoWelcome() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Registration submitted successfully! Please wait for admin approval.",
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
  }

  String _formatSriLankanPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('94')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+94$digits';
  }

  Future<void> _upsertSponsorApplication({
    required String uid,
    required String email,
    required String fullPhoneNumber,
    required String organizationType,
    required String sponsorID,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final payload = {
      'uid': uid,
      'fullName': _nameController.text.trim(),
      'email': normalizedEmail,
      'phone': fullPhoneNumber,
      'organizationType': organizationType,
      'sponsorID': sponsorID,
      'linkedin': _linkedinController.text.trim(),
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
      'method': 'Monetary Aid',
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    final existingApplication = await FirebaseFirestore.instance
        .collection('sponsor_applications')
        .where('email', isEqualTo: normalizedEmail)
        .where('status', whereIn: ['pending', 'applied', 'Pending', 'Applied'])
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 20));

    if (existingApplication.docs.isNotEmpty) {
      await existingApplication.docs.first.reference
          .set(payload, SetOptions(merge: true))
          .timeout(const Duration(seconds: 20));
      return;
    }

    await FirebaseFirestore.instance
        .collection('sponsor_applications')
        .doc(uid)
        .set(payload, SetOptions(merge: true))
        .timeout(const Duration(seconds: 20));
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_organizationType == null || _organizationType!.isEmpty) {
      _showSnackBar("Please select organization type", Colors.orangeAccent);
      return;
    }

    if (_phoneController.text.trim().length < 9) {
      _showSnackBar("Enter valid 9 digits", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);
    final String trimmedEmail = _emailController.text.trim().toLowerCase();
    UserCredential? userCredential;

    try {
      final String username = trimmedEmail.split('@').first;
      String fullPhoneNumber = _formatSriLankanPhone(_phoneController.text);
      final String orgType = _organizationType!;

      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: _passwordController.text.trim(),
          )
          .timeout(const Duration(seconds: 20));

      final String sponsorID = await _generateSequentialSponsorID();

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'firstName': _nameController.text.trim(),
              'username': username,
              'email': trimmedEmail,
              'phone': fullPhoneNumber,
              'organizationType': orgType,
              'sponsorID': sponsorID,
              'linkedin': _linkedinController.text.trim(),
              'role': 'Sponsor',
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 20));

        await _upsertSponsorApplication(
          uid: userCredential.user!.uid,
          email: trimmedEmail,
          fullPhoneNumber: fullPhoneNumber,
          organizationType: orgType,
          sponsorID: sponsorID,
        );
      } catch (_) {
        await userCredential.user?.delete();
        rethrow;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      await _showSuccessAndGoWelcome();
      return;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message =
            "This email is already registered. Please login or use another email.";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email address.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak. Use at least 6 characters.";
      } else {
        message = e.message ?? "Registration failed. Please try again.";
      }
      _showSnackBar(message, Colors.redAccent);
    } on TimeoutException {
      _showSnackBar(
        "Request timed out. Please check your internet and try again.",
        Colors.redAccent,
      );
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildStyledField(
                      "Organization / Full Name",
                      _nameController,
                      icon: Icons.business_rounded,
                    ),
                    const SizedBox(height: 15),
                    _buildDropdownField(
                      hint: "Organization Type",
                      icon: Icons.apartment_rounded,
                      value: _organizationType,
                      items: const ["Individual", "Company", "NGO"],
                      onChanged: (val) =>
                          setState(() => _organizationType = val),
                    ),
                    const SizedBox(height: 15),
                    _buildStyledField(
                      "Business Email",
                      _emailController,
                      isEmail: true,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 15),
                    _buildPhoneField(),
                    const SizedBox(height: 15),
                    _buildStyledField(
                      "LinkedIn Profile URL",
                      _linkedinController,
                      icon: Icons.link_rounded,
                      isRequired: false,
                    ),
                    const SizedBox(height: 15),
                    _buildPasswordField("Password", _passwordController),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF5C71D1)),
              const SizedBox(width: 10),
              Text(
                hint,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF5C71D1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: const Center(
        child: Text(
          "Sponsor\nRegistration",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStyledField(
    String hint,
    TextEditingController controller, {
    bool isEmail = false,
    IconData? icon,
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        validator: (v) {
          if (!isRequired) return null;
          return v!.isEmpty ? "Required" : null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF5C71D1), size: 20)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _phoneController,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        keyboardType: TextInputType.number,
        maxLength: 9,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) => v!.length < 9 ? "Enter valid 9 digits" : null,
        decoration: InputDecoration(
          hintText: "7x xxx xxxx",
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Text(
              "🇱🇰 +94",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          counterText: "",
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        obscureText: !_isPasswordVisible,
        validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C71D1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SUBMIT & REGISTER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
