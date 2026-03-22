import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'teacher_chat_with_admin_screen.dart';

class TeacherMakeLessonScreen extends StatefulWidget {
  final String? initialSubject;
  final String? initialGrade;

  const TeacherMakeLessonScreen({
    super.key,
    this.initialSubject,
    this.initialGrade,
  });

  @override
  State<TeacherMakeLessonScreen> createState() =>
      _TeacherMakeLessonScreenState();
}

class _TeacherMakeLessonScreenState extends State<TeacherMakeLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String selectedChapter = "1";
  String selectedLessonNum = "1";
  String? gradeLevel;
  String? subject;

  PlatformFile? lectureNoteFile;
  PlatformFile? paperFile;

  @override
  void initState() {
    super.initState();
    subject = widget.initialSubject;
    gradeLevel = widget.initialGrade;
    _loadTeacherCourseInfo();
  }

  Future<void> _pickFile(bool isNote) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        if (isNote) {
          lectureNoteFile = result.files.first;
        } else {
          paperFile = result.files.first;
        }
      });
    }
  }

  Future<void> _loadTeacherCourseInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final teacherData = data?['teacherData'] as Map<String, dynamic>?;
        setState(() {
          gradeLevel = (teacherData?['teachingGrade'] as String?) ?? "Not Set";
        });
      }
    }
  }

  Future<void> _uploadLesson() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;

      if (gradeLevel == "Not Set" || subject == "Not Set") {
        _showSnackBar(
          "Your Teacher Profile data is missing! Please update your profile.",
          Colors.red,
        );
        return;
      }

      bool dialogShown = false;

      try {
        setState(() => _isSubmitting = true);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
        dialogShown = true;

        final String title = _nameController.text.trim();
        final String videoUrl = _videoController.text.trim();

        final existingLessons = await FirebaseFirestore.instance
            .collection('lessons')
            .where('teacherId', isEqualTo: user?.uid)
            .get();

        final bool isDuplicate = existingLessons.docs.any((doc) {
          final existing = doc.data();
          final String existingTitle = (existing['title'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final String existingVideo = (existing['videoUrl'] ?? '')
              .toString()
              .trim();
          final String existingChapter = (existing['chapter'] ?? '').toString();
          final String existingLessonNumber = (existing['lessonNumber'] ?? '')
              .toString();

          return existingTitle == title.toLowerCase() &&
              existingVideo == videoUrl &&
              existingChapter == selectedChapter &&
              existingLessonNumber == selectedLessonNum;
        });

        if (isDuplicate) {
          if (dialogShown && Navigator.canPop(context)) Navigator.pop(context);
          _showSnackBar(
            "This lesson already exists. Please edit the existing one instead of uploading again.",
            Colors.orange,
          );
          return;
        }

        final String lessonId = FirebaseFirestore.instance
            .collection('lessons')
            .doc()
            .id;

        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lessonId)
            .set({
              'lessonId': lessonId,
              'teacherId': user?.uid,
              'title': title,
              'videoUrl': videoUrl,
              'description': _descController.text.trim(),
              'chapter': selectedChapter,
              'lessonNumber': selectedLessonNum,

              'grade': gradeLevel,
              'subject': subject,

              'status': 'pending',
              'isApproved': false,
              'createdAt': FieldValue.serverTimestamp(),
              'lectureNoteName': lectureNoteFile?.name ?? "No file selected",
              'paperName': paperFile?.name ?? "No file selected",
            });

        if (dialogShown && Navigator.canPop(context)) {
          Navigator.pop(context);
          dialogShown = false;
        }

        _showSnackBar(
          "Lesson submitted for approval successfully!",
          Colors.green,
        );
        Navigator.pop(context);
      } catch (e) {
        if (dialogShown && Navigator.canPop(context)) Navigator.pop(context);
        _showSnackBar("Error: $e", Colors.red);
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Create New Lesson",
          style: TextStyle(
            color: Color(0xFF1A1C2E),
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C2E)),
        actions: [
          IconButton(
            tooltip: "Chat with Admin",
            icon: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF1A1C2E),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatWithAdminScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTopIntroCard(),
              const SizedBox(height: 16),
              _buildCard([
                _buildLabel("Lesson Name"),
                _buildTextField(_nameController, "Enter lesson name"),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildLabel("Chapter (1-5)")),
                    Expanded(child: _buildLabel("Lesson (1-15)")),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        List.generate(5, (i) => "${i + 1}"),
                        selectedChapter,
                        (val) => setState(() => selectedChapter = val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        List.generate(15, (i) => "${i + 1}"),
                        selectedLessonNum,
                        (val) => setState(() => selectedLessonNum = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoBox("Grade", gradeLevel ?? "Loading..."),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoBox("Subject", subject ?? "Loading..."),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              _buildCard([
                const Text(
                  "Assets & Details",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1C2E),
                  ),
                ),
                const SizedBox(height: 15),
                _buildLabel("YouTube Link"),
                _buildTextField(
                  _videoController,
                  "Paste link here",
                  icon: Icons.link,
                ),
                const SizedBox(height: 15),
                _buildLabel("Description"),
                _buildTextField(
                  _descController,
                  "Type details here...",
                  maxLines: 6,
                ),
                const SizedBox(height: 15),
                const SizedBox(height: 20),
                _buildFilePickerSection(
                  "Lecture Note",
                  lectureNoteFile,
                  () => _pickFile(true),
                ),
                const SizedBox(height: 15),
                _buildFilePickerSection(
                  "Lesson Paper",
                  paperFile,
                  () => _pickFile(false),
                ),
              ]),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5C71D1).withOpacity(0.24),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _uploadLesson,
                    icon: const Icon(
                      Icons.upload_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                    label: Text(
                      _isSubmitting ? "Submitting..." : "Submit for Approval",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerSection(
    String title,
    PlatformFile? file,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(title),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5C71D1).withOpacity(0.16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file, color: Color(0xFF5C71D1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file != null ? file.name : "Tap to select $title (PDF/Doc)",
                    style: TextStyle(
                      color: file != null
                          ? Colors.black87
                          : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: file != null
                          ? FontWeight.w900
                          : FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2EBD85),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF5C71D1).withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Color(0xFF1A1C2E),
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    int maxLines = 1,
    bool isSmall = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF5C71D1))
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF5C71D1).withOpacity(0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF5C71D1).withOpacity(0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5C71D1), width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: isSmall ? 10 : 15,
        ),
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF5C71D1).withOpacity(0.14),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF5C71D1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF5C71D1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF5C71D1),
              size: 28,
            ),
          ),
          SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lesson Builder",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Create lessons and send them for admin approval.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF616A89),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
