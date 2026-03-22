import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sponser_registration_screen.dart';

class SponsorApplicationScreen extends StatefulWidget {
  const SponsorApplicationScreen({super.key});

  @override
  State<SponsorApplicationScreen> createState() =>
      _SponsorApplicationScreenState();
}

class _SponsorApplicationScreenState extends State<SponsorApplicationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();

  String? _selectedMethod = "Monetary Aid";
  bool _isLoading = false;

  Future<void> _handleApplicationSubmit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _selectedMethod == null) {
      _showSnackBar("Please fill all required fields", Colors.orangeAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('sponsor_applications').add({
        'uid': uid,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _formatSriLankanPhone(_phoneController.text),
        'method': _selectedMethod,
        'linkedin': _linkedinController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSnackBar(
        "Application Submitted! Proceeding to Registration...",
        Colors.green,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SponsorRegistrationScreen(),
        ),
      );
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  String _formatSriLankanPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('94')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+94$digits';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFF),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildStandardHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Personal Details", Icons.badge_outlined),
                  _buildPremiumField(
                    "Full Name",
                    _nameController,
                    Icons.person_outline,
                  ),
                  _buildPremiumField(
                    "Email Address",
                    _emailController,
                    Icons.alternate_email_rounded,
                  ),
                  _buildPremiumField(
                    "Phone Number",
                    _phoneController,
                    Icons.phone_android_rounded,
                    isNumber: true,
                    prefixText: '+94 ',
                  ),

                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    "Sponsorship Preference",
                    Icons.volunteer_activism_outlined,
                  ),
                  _buildMethodSelector(),

                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    "Professional Verification",
                    Icons.verified_user_outlined,
                  ),
                  _buildPremiumField(
                    "LinkedIn Profile Link",
                    _linkedinController,
                    Icons.link_rounded,
                  ),

                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardHeader() => Container(
    height: 200,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF5C71D1), Color(0xFF485CC7)]),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: SafeArea(
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_rounded, size: 50, color: Colors.white24),
                SizedBox(height: 10),
                Text(
                  "Sponsor Application",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 15, left: 5),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5C71D1)),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1C2E),
          ),
        ),
      ],
    ),
  );

  Widget _buildPremiumField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFEEF2FF)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF5C71D1).withOpacity(0.6),
            ),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Color(0xFF1A1C2E),
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEEF2FF)),
      ),
      child: Column(
        children: [
          _buildRadioOption("Monetary Aid", Icons.payments_outlined),
          Divider(height: 1, indent: 60, color: Colors.grey[100]),
          _buildRadioOption("Equipment Donation", Icons.devices_other_outlined),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5C71D1).withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      value: label,
      groupValue: _selectedMethod,
      activeColor: const Color(0xFF5C71D1),
      onChanged: (val) => setState(() => _selectedMethod = val),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C71D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: _isLoading ? null : _handleApplicationSubmit,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "SUBMIT APPLICATION",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
    ),
  );
}
