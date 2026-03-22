import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../../core/constants/education_constants.dart';
import '../../core/page_transition.dart';
import 'teacher_registration_screen.dart';

class TeacherApplicationScreen extends StatefulWidget {
  const TeacherApplicationScreen({super.key});

  @override
  State<TeacherApplicationScreen> createState() =>
      _TeacherApplicationScreenState();
}

class _TeacherApplicationScreenState extends State<TeacherApplicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? selectedGrade;
  List<String> selectedSubjects = [];
  String? selectedQualification;
  PlatformFile? pickedCV;
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

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isNotEmpty && email.contains('@') && email.contains('.')) {
      _fetchDetailsFromRegistration(email);
    }
  }

  Timer? _debounce;
  void _fetchDetailsFromRegistration(String email) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'Teacher')
            .get();

        if (query.docs.isNotEmpty && mounted) {
          final userData = query.docs.first.data();
          final teacherData = userData['teacherData'] as Map<String, dynamic>?;

          setState(() {
            if (_nameController.text.isEmpty) {
              _nameController.text = userData['fullName'] ?? '';
            }
            if (_phoneController.text.isEmpty) {
              String rawPhone = userData['phone'] ?? '';
              if (rawPhone.startsWith('+94')) {
                _phoneController.text = rawPhone.substring(3).trim();
              } else {
                _phoneController.text = rawPhone;
              }
            }

            if (selectedGrade == null && teacherData != null) {
              selectedGrade = teacherData['teachingGrade'];
              selectedSubjects = List<String>.from(
                teacherData['expertise'] ?? [],
              );
              selectedQualification = teacherData['qualification'];
            }
          });

          _showSnackBar(
            "Details pre-filled from your registration!",
            Colors.green,
          );
        }
      } catch (e) {
        debugPrint("Error fetching pre-fill data: $e");
      }
    });
  }

  final Map<String, List<String>> gradeWiseSubjects =
      EducationConstants.gradeWiseSubjects;

  Future<void> _submitApplication() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _bioController.text.isEmpty ||
        selectedGrade == null ||
        selectedSubjects.isEmpty ||
        selectedQualification == null) {
      _showSnackBar(
        "Please fill all fields to submit your application",
        Colors.orangeAccent,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final String email = _emailController.text.trim().toLowerCase();

      // Check if already applied - Proceed anyway to Registration if exists
      final existingPending = await FirebaseFirestore.instance
          .collection('teacher_applications')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'Pending')
          .get();

      if (existingPending.docs.isEmpty) {
        final String tempDocId = FirebaseFirestore.instance
            .collection('teacher_applications')
            .doc()
            .id;

        await FirebaseFirestore.instance
            .collection('teacher_applications')
            .doc(tempDocId)
            .set({
              'applicationId': tempDocId,
              'fullName': _nameController.text.trim(),
              'email': email,
              'phone': _formatSriLankanPhone(_phoneController.text),
              'teachingGrade': selectedGrade,
              'expertise': selectedSubjects,
              'experience': _expController.text.trim(),
              'qualification': selectedQualification,
              'bio': _bioController.text.trim(),
              'cvName': pickedCV?.name ?? "Not Provided",
              'status': 'Pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      _showSnackBar(
        "Application sent successfully! Redirecting...",
        Colors.green,
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageTransition(child: const TeacherRegistrationScreen()),
        );
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
            _buildPremiumHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          "Personal Details",
                          Icons.badge_outlined,
                        ),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          "Teaching Profile",
                          Icons.auto_stories_outlined,
                        ),
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
                        const SizedBox(height: 15),
                        _buildPremiumField(
                          "Experience (Years)",
                          _expController,
                          Icons.history_edu_rounded,
                          isNumber: true,
                        ),
                        _buildPremiumField(
                          "Bio / Introduction",
                          _bioController,
                          Icons.notes_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          "CV / Professional Proof",
                          Icons.cloud_upload_outlined,
                        ),
                        _buildUploadBox(),
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
          ],
        ),
      ),
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
      onPressed: isLoading ? null : _submitApplication,
      child: isLoading
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

  Widget _buildPremiumHeader() => Container(
    height: 240,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF5C71D1), Color(0xFF485CC7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      boxShadow: [
        BoxShadow(
          color: Color(0x4D5C71D1),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
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
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_ind_rounded,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: const Column(
                    children: [
                      Text(
                        "Teacher Application",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Start your journey as an educator",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 15,
          left: 15,
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
    int maxLines = 1,
    bool isNumber = false,
    String? prefixText,
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
              color: isFilled
                  ? const Color(0xFF5C71D1)
                  : const Color(0xFFEEF2FF),
              width: isFilled ? 1.5 : 1,
            ),
            boxShadow: [
              if (isFilled)
                BoxShadow(
                  color: const Color(0xFF5C71D1).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(
              fontWeight: isFilled ? FontWeight.w700 : FontWeight.w500,
              color: isFilled ? const Color(0xFF2D3B62) : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixText: prefixText,
              prefixIcon: Icon(
                icon,
                color: isFilled ? const Color(0xFF5C71D1) : Colors.grey,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
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
    final isSelected = value != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F2FF) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? const Color(0xFF5C71D1) : const Color(0xFFEEF2FF),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF5C71D1).withOpacity(0.08),
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
            color: isSelected ? const Color(0xFF5C71D1) : Colors.grey,
          ),
          hint: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF5C71D1) : Colors.grey,
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
            color: isSelected ? const Color(0xFF2D3B62) : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildMultiSubjectSelection() {
    final List<String> availableSubjects = selectedGrade != null
        ? gradeWiseSubjects[selectedGrade]!
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            "Select Subject Expertise (1 or more)",
            style: TextStyle(
              fontSize: 14,
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
            border: Border.all(color: const Color(0xFFEEF2FF)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSubjects.isEmpty
                ? [
                    const Text(
                      "Please select a grade level first",
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
                        color: isSelected
                            ? const Color(0xFF5C71D1)
                            : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
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

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickCV,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: pickedCV != null ? const Color(0xFFF0F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: pickedCV != null
                ? const Color(0xFF5C71D1)
                : const Color(0xFFEEF2FF),
            width: pickedCV != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              pickedCV != null
                  ? Icons.check_circle_rounded
                  : Icons.cloud_upload_outlined,
              size: 30,
              color: pickedCV != null ? const Color(0xFF5C71D1) : Colors.grey,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                pickedCV != null
                    ? pickedCV!.name
                    : "Upload CV / Profile Proof (Optional)",
                style: TextStyle(
                  color: pickedCV != null
                      ? const Color(0xFF2D3B62)
                      : const Color(0xFF64748B),
                  fontWeight: pickedCV != null
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (pickedCV != null)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => setState(() => pickedCV = null),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          pickedCV = result.files.first;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }
}
