import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_home_screen.dart';
import '../../core/page_transition.dart';

class ClassSelectionScreen extends StatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  String? selectedClass;
  bool _isSaving = false;

  void _showComingSoonDialog(String gradeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF5C71D1),
          size: 50,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$gradeName is Coming Soon!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              "We are currently preparing content for this grade. Please stay tuned!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK, I'LL WAIT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C71D1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClassSubmission() async {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your class first")),
      );
      return;
    }

    if (selectedClass == "Grade 6 - 9" ||
        selectedClass == "A/L (Grade 12 - 13)") {
      _showComingSoonDialog(selectedClass!);
      return;
    }

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'role': 'Student',
        'updatedAt': FieldValue.serverTimestamp(),
        'studentData': {
          'selectedGrade': selectedClass,
          'hasCompletedOnboarding': true,
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        ScaleFadeTransition(child: const StudentHomeScreen()),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      final message = e.message ?? e.code;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving data: $message")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving data: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double reservedBottom = 112 + bottomInset;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: reservedBottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Column(
                            children: [
                              _buildSelectionInfoCard(),
                              const SizedBox(height: 16),
                              _buildOptionButton("Grade 6 - 9"),
                              _buildOptionButton("O/L (Grade 10 - 11)"),
                              _buildOptionButton("A/L (Grade 12 - 13)"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + bottomInset,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildFinishButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.36,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(95),
        bottomRight: Radius.circular(95),
      ),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_rounded, color: Colors.white, size: 50),
          SizedBox(height: 10),
          Text(
            "Select Your Class",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Choose your current grade to personalize your learning journey.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSelectionInfoCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFF5C71D1), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            "You can update this later from your profile settings.",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildFinishButton() => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _handleClassSubmission,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5C71D1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Text(
              "FINISH & START",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
    ),
  );

  Widget _buildOptionButton(String title) {
    bool isSelected = selectedClass == title;
    return GestureDetector(
      onTap: () => setState(() => selectedClass = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5C71D1).withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5C71D1)
                : const Color(0xFFEEF2FF),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF5C71D1) : Colors.black87,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF5C71D1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
