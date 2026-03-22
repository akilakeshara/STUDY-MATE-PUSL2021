import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher_home_screen.dart';

class TeacherMakeClassScreen extends StatefulWidget {
  const TeacherMakeClassScreen({super.key});

  @override
  State<TeacherMakeClassScreen> createState() => _TeacherMakeClassScreenState();
}

class _TeacherMakeClassScreenState extends State<TeacherMakeClassScreen> {
  String selectedCategory = "Loading...";
  String? selectedClass;
  String? selectedStudentCount;
  String? selectedDuration;
  final TextEditingController _courseNameController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherExpertise();
  }

  Future<void> _loadTeacherExpertise() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            selectedCategory =
                (data?['expertise'] as String?) ?? "Not Specified";
          });
        }
      } catch (e) {
        debugPrint("Error loading expertise: $e");
      }
    }
  }

  Future<void> _createClass() async {
    if (_courseNameController.text.trim().isEmpty ||
        selectedClass == null ||
        selectedStudentCount == null ||
        selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('classes').add({
        'courseName': _courseNameController.text.trim(),
        'category': selectedCategory,
        'grade': selectedClass,
        'maxStudents': int.parse(selectedStudentCount!),
        'duration': selectedDuration,
        'teacherId': uid,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'enrolledStudents': 0,
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isFirstLogin': false,
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text(
            "Your class has been submitted for Admin approval!",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Go to Dashboard",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFixedCategoryAndClassRow(),
                  const SizedBox(height: 25),
                  _buildSecondRow(),
                  const SizedBox(height: 25),
                  const Text(
                    "Class Title",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCourseNameField(),
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


  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF4A5CB3)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(80),
          bottomRight: Radius.circular(80),
        ),
      ),
      child: const Center(
        child: Text(
          "Set Up Your\nNew Class",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildFixedCategoryAndClassRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "My Expertise",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  selectedCategory,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C71D1),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildLabelledDropdown(
            "Target Grade",
            "Select Grade",
            ['Grade 10', 'Grade 11', 'A/L'],
            selectedClass,
            (v) => setState(() => selectedClass = v),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondRow() {
    return Row(
      children: [
        Expanded(
          child: _buildLabelledDropdown(
            "Limit Students",
            "Max capacity",
            ['10', '20', '40', '100'],
            selectedStudentCount,
            (v) => setState(() => selectedStudentCount = v),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildLabelledDropdown(
            "Course Plan",
            "Select period",
            ['1 Month', '3 Months', '6 Months'],
            selectedDuration,
            (v) => setState(() => selectedDuration = v),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseNameField() {
    return TextField(
      controller: _courseNameController,
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: "e.g., Advanced Physics Group Class",
        filled: true,
        fillColor: const Color(0xFFF3F4F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : _createClass,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "LAUNCH CLASS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildLabelledDropdown(
    String label,
    String hint,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(
                hint,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: value,
              items: items
                  .map(
                    (val) => DropdownMenuItem(
                      value: val,
                      child: Text(
                        val,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
