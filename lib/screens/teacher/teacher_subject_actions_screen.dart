import 'package:flutter/material.dart';
import 'teacher_make_lesson_screen.dart';
import 'teacher_create_quiz_screen.dart';
import 'students_progress_screen.dart';

class TeacherSubjectActionsScreen extends StatelessWidget {
  final String subjectName;
  final String teacherName;
  final String teacherGrade;

  const TeacherSubjectActionsScreen({
    super.key,
    required this.subjectName,
    required this.teacherName,
    required this.teacherGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        title: Text(
          subjectName,
          style: const TextStyle(
            color: Color(0xFF1A1C2E),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1C2E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 30),
            const Text(
              "AVAILABLE ACTIONS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              context: context,
              title: "Create New Lesson",
              subtitle: "Upload videos, notes and papers",
              icon: Icons.add_circle_outline_rounded,
              color: const Color(0xFF5C71D1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherMakeLessonScreen(
                    initialSubject: subjectName,
                    initialGrade: teacherGrade,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              context: context,
              title: "Create New Quiz",
              subtitle: "Add interactive questions for students",
              icon: Icons.quiz_outlined,
              color: const Color(0xFFF3A31D),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherCreateQuizScreen(
                    teacherName: teacherName,
                    teacherGrade: teacherGrade,
                    teacherSubject: subjectName,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _actionButton(
              context: context,
              title: "View Student Progress",
              subtitle: "Track performance for this subject",
              icon: Icons.insights_rounded,
              color: const Color(0xFF2EBD85),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentsProgressScreen(
                    initialSubject: subjectName,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            subjectName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Grade: $teacherGrade",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1C2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
