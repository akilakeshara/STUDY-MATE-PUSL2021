import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/constants/education_constants.dart';
import 'dart:async';

class TeacherRegistrationScreen extends StatefulWidget {
  const TeacherRegistrationScreen({super.key});

  @override
  State<TeacherRegistrationScreen> createState() =>
      _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? selectedGrade;
  List<String> selectedSubjects = [];
  String? selectedQualification;
  bool isLoading = false;

  final List<String> qualificationList = [
    "Bachelor's Degree",
    "Master's Degree",
    "PhD / Doctorate",
    "Diploma",
    "Higher Diploma",
    "Undergraduate Student",
    "Professional Qualification",
    "Other",
  ];
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isNotEmpty && email.contains('@') && email.contains('.')) {
      _fetchDetailsFromApplication(email);
    }
  }

  Timer? _debounce;
  void _fetchDetailsFromApplication(String email) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final query = await FirebaseFirestore.instance
            .collection('teacher_applications')
            .where('email', isEqualTo: email)
            .get();

        if (query.docs.isNotEmpty && mounted) {
          final appData = query.docs.first.data();

          setState(() {
            if (_fullNameController.text.isEmpty) {
              _fullNameController.text = appData['fullName'] ?? '';
            }
            if (_phoneController.text.isEmpty) {
              String rawPhone = appData['phone'] ?? '';
              if (rawPhone.startsWith('+94')) {
                _phoneController.text = rawPhone.substring(3).trim();
              } else {
                _phoneController.text = rawPhone;
              }
            }
            
            if (selectedGrade == null) {
              selectedGrade = appData['teachingGrade'];
              selectedSubjects = List<String>.from(appData['expertise'] ?? []);
              selectedQualification = appData['qualification'];
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Details pre-filled from your application!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error fetching application data: $e");
      }
    });
  }

  final Map<String, List<String>> gradeWiseSubjects =
      EducationConstants.gradeWiseSubjects;

  Future<String> _generateSequentialID() async {
    QuerySnapshot applicationsSnapshot = await FirebaseFirestore.instance
        .collection('teacher_applications')
        .get();

    return "TCH-${(applicationsSnapshot.docs.length + 1).toString().padLeft(4, '0')}";
  }

  void _showPendingApprovalPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 80,
                color: Color(0xFF5C71D1),
              ),
              const SizedBox(height: 20),
              const Text(
                "Registration Pending!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                "Your details have been sent to Admin. Please wait for approval to login.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 10),
              const Text(
                "Redirecting to Welcome Screen...",
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _handleFullRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (selectedGrade == null ||
          selectedSubjects.isEmpty ||
          selectedQualification == null) {
        _showSnackBar(
          "Please select Grade, Subject and Qualification",
          Colors.orangeAccent,
        );
        return;
      }

      setState(() => isLoading = true);
      UserCredential? userCredential;

      try {
        final String trimmedEmail = _emailController.text.trim().toLowerCase();
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: trimmedEmail,
              password: _passwordController.text.trim(),
            );

        String uid = userCredential.user!.uid;
        String generatedID = await _generateSequentialID();

        String fullPhoneNumber = "+94${_phoneController.text.trim()}";

        Map<String, dynamic> userData = {
          'uid': uid,
          'fullName': _fullNameController.text.trim(),
          'email': trimmedEmail,
          'phone': fullPhoneNumber,
          'role': 'Teacher',
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
          'teacherData': {
            'teacherID': generatedID,
            'teachingGrade': selectedGrade,
            'expertise': selectedSubjects, // Now a list
            'qualification': selectedQualification,
            'isVerified': false,
            'rating': 5.0,
          },
        };

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set(userData);
        } catch (_) {
          await userCredential.user?.delete();
          rethrow;
        }

        final existingPending = await FirebaseFirestore.instance
            .collection('teacher_applications')
            .where('email', isEqualTo: trimmedEmail)
            .where('status', isEqualTo: 'Pending')
            .limit(1)
            .get();

        final Map<String, dynamic> applicationPayload = {
          'uid': uid,
          'fullName': _fullNameController.text.trim(),
          'teacherID': generatedID,
          'email': trimmedEmail,
          'phone': fullPhoneNumber,
          'teachingGrade': selectedGrade,
          'expertise': selectedSubjects, // Now a list
          'qualification': selectedQualification,
          'status': 'Pending',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (existingPending.docs.isNotEmpty) {
          await existingPending.docs.first.reference.set(
            applicationPayload,
            SetOptions(merge: true),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('teacher_applications')
              .doc(uid)
              .set({
                ...applicationPayload,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }

        setState(() => isLoading = false);
        _showPendingApprovalPopup();
      } on FirebaseAuthException catch (e) {
        setState(() => isLoading = false);
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
      } catch (e) {
        setState(() => isLoading = false);
        _showSnackBar("Error: $e", Colors.redAccent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          _buildStyledField(
                            "Full Name",
                            _fullNameController,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 15),
                          _buildStyledField(
                            "Personal Email",
                            _emailController,
                            isEmail: true,
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 15),
                          _buildPhoneField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: [
                          _buildSelectionField(
                            hint: "Select Grade Level",
                            icon: Icons.layers_outlined,
                            value: selectedGrade,
                            items: gradeWiseSubjects.keys.toList(),
                            onChanged: (val) => setState(() {
                              selectedGrade = val;
                              selectedSubjects = [];
                            }),
                          ),
                          const SizedBox(height: 15),
                          _buildMultiSubjectSelection(),
                          const SizedBox(height: 15),
                          _buildSelectionField(
                            hint: "Select Qualification",
                            icon: Icons.workspace_premium_outlined,
                            value: selectedQualification,
                            items: qualificationList,
                            onChanged: (val) =>
                                setState(() => selectedQualification = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        children: [
                          _buildPasswordField("Password", _passwordController),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 600),
                      child: _buildSubmitButton(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF485CC7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D5C71D1),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.how_to_reg_rounded,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: const Text(
                      "Welcome to\nRegistration",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledField(
    String hint,
    TextEditingController controller, {
    bool isEmail = false,
    IconData? icon,
  }) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final isFilled = value.text.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: isFilled ? const Color(0xFFF0F2FF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isFilled ? const Color(0xFF5C71D1) : const Color(0xFFEEF2FF),
              width: isFilled ? 1.5 : 1,
            ),
            boxShadow: [
              if (isFilled)
                BoxShadow(
                  color: const Color(0xFF5C71D1).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
            style: TextStyle(
              fontWeight: isFilled ? FontWeight.w800 : FontWeight.w600,
              color: isFilled ? const Color(0xFF2D3B62) : Colors.black87,
            ),
            validator: (v) => v!.isEmpty ? "Required" : null,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isFilled ? const Color(0xFF5C71D1) : Colors.grey,
                      size: 20,
                    )
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
      },
    );
  }

  Widget _buildSelectionField({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final isFilled = value != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isFilled ? const Color(0xFFF0F2FF) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isFilled ? const Color(0xFF5C71D1) : const Color(0xFFEEF2FF),
          width: isFilled ? 1.5 : 1,
        ),
        boxShadow: [
          if (isFilled)
            BoxShadow(
              color: const Color(0xFF5C71D1).withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
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
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isFilled ? const Color(0xFF5C71D1) : Colors.grey,
          ),
          hint: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isFilled ? const Color(0xFF5C71D1) : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text(
                hint,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          style: TextStyle(
            color: isFilled ? const Color(0xFF2D3B62) : Colors.black87,
            fontSize: 14,
            fontWeight: isFilled ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'Inter',
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3B62),
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return ValueListenableBuilder(
      valueListenable: _phoneController,
      builder: (context, value, child) {
        final isFilled = value.text.length == 9;
        return Container(
          decoration: BoxDecoration(
            color: isFilled ? const Color(0xFFF0F2FF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isFilled ? const Color(0xFF5C71D1) : const Color(0xFFEEF2FF),
              width: isFilled ? 1.5 : 1,
            ),
            boxShadow: [
              if (isFilled)
                BoxShadow(
                  color: const Color(0xFF5C71D1).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.number,
            maxLength: 9,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontWeight: isFilled ? FontWeight.w800 : FontWeight.w600,
              color: isFilled ? const Color(0xFF2D3B62) : Colors.black87,
            ),
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
                    color: isFilled ? const Color(0xFF5C71D1) : Colors.grey.shade700,
                  ),
                ),
              ),
              counterText: "",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(String hint, TextEditingController controller) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, child) {
        final isFilled = value.text.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isFilled ? const Color(0xFFF0F2FF) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isFilled ? const Color(0xFF5C71D1) : const Color(0xFFEEF2FF),
              width: isFilled ? 1.5 : 1,
            ),
            boxShadow: [
              if (isFilled)
                BoxShadow(
                  color: const Color(0xFF5C71D1).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !_isPasswordVisible,
            style: TextStyle(
              fontWeight: isFilled ? FontWeight.w800 : FontWeight.w600,
              color: isFilled ? const Color(0xFF2D3B62) : Colors.black87,
            ),
            validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isFilled ? const Color(0xFF5C71D1) : Colors.grey,
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
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleFullRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C71D1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMultiSubjectSelection() {
    final List<String> availableSubjects =
        selectedGrade != null ? gradeWiseSubjects[selectedGrade]! : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            "Select Subject Expertise (1 or more)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4D5F8A),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
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
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSubjects.isEmpty
                ? [
                    const Text(
                      "Please select a grade first",
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ]
                : availableSubjects.map((sub) {
                    final isSelected = selectedSubjects.contains(sub);
                    return FilterChip(
                      label: Text(sub),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            selectedSubjects.add(sub);
                          } else {
                            selectedSubjects.remove(sub);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF5C71D1).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF5C71D1),
                      labelStyle: TextStyle(
                        color:
                            isSelected ? const Color(0xFF5C71D1) : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 12,
                      ),
                       backgroundColor: Colors.white,
                       elevation: isSelected ? 4 : 0,
                       shadowColor: const Color(0xFF5C71D1).withOpacity(0.3),
                       shape: StadiumBorder(
                         side: BorderSide(
                           color: isSelected
                               ? const Color(0xFF5C71D1)
                               : Colors.grey.withOpacity(0.2),
                           width: isSelected ? 1.5 : 1,
                         ),
                       ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}
