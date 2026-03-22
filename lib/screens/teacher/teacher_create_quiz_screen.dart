import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherCreateQuizScreen extends StatefulWidget {
  final String teacherName;
  final String teacherGrade;
  final String teacherSubject;

  const TeacherCreateQuizScreen({
    super.key,
    required this.teacherName,
    required this.teacherGrade,
    required this.teacherSubject,
  });

  @override
  State<TeacherCreateQuizScreen> createState() =>
      _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState extends State<TeacherCreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quizTitleController = TextEditingController();
  final TextEditingController _lessonNameController = TextEditingController();
  final List<_QuestionFormData> _questions = [_QuestionFormData()];
  bool _isSaving = false;

  @override
  void dispose() {
    _quizTitleController.dispose();
    _lessonNameController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _submitQuiz() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final String title = _quizTitleController.text.trim();
      final String lessonName = _lessonNameController.text.trim();
      final quizRef = FirebaseFirestore.instance.collection('quizzes').doc();

      await quizRef.set({
        'teacherId': user.uid,
        'teacherName': widget.teacherName,
        'title': title,
        'lessonName': lessonName,
        'subject': widget.teacherSubject,
        'grade': widget.teacherGrade,
        'questionCount': _questions.length,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (int index = 0; index < _questions.length; index++) {
        final q = _questions[index];
        final String optionA = q.optionAController.text.trim();
        final String optionB = q.optionBController.text.trim();
        final String optionC = q.optionCController.text.trim();
        final String optionD = q.optionDController.text.trim();

        final Map<String, String> options = {
          'A': optionA,
          'B': optionB,
          'C': optionC,
          'D': optionD,
        };

        final String correctAnswer = options[q.correctOption] ?? '';

        final questionRef = FirebaseFirestore.instance
            .collection('quiz_questions')
            .doc();

        batch.set(questionRef, {
          'quizId': quizRef.id,
          'teacherId': user.uid,
          'teacherName': widget.teacherName,
          'quizTitle': title,
          'lessonName': lessonName,
          'subject': widget.teacherSubject,
          'grade': widget.teacherGrade,
          'questionNumber': index + 1,
          'question': q.questionController.text.trim(),
          'options': options,
          'correctOption': q.correctOption,
          'answer': correctAnswer,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz created successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create quiz: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionFormData()));
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        title: const Text(
          'Create Quiz',
          style: TextStyle(
            color: Color(0xFF1A1C2E),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1C2E)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopIntroCard(),
                const SizedBox(height: 16),
                _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrimaryField(
                        controller: _quizTitleController,
                        label: 'Quiz Title',
                      ),
                      const SizedBox(height: 12),
                      _buildPrimaryField(
                        controller: _lessonNameController,
                        label: 'Lesson Name',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Grade: ${widget.teacherGrade}   |   Subject: ${widget.teacherSubject}',
                        style: const TextStyle(
                          color: Color(0xFF616A89),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (int index = 0; index < _questions.length; index++)
                  _buildQuestionCard(index),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add, color: Color(0xFF5C71D1)),
                    label: const Text(
                      'Add Another Question',
                      style: TextStyle(
                        color: Color(0xFF5C71D1),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFF5C71D1).withOpacity(0.4),
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      onPressed: _isSaving ? null : _submitQuiz,
                      icon: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _isSaving ? 'Publishing...' : 'Publish Quiz',
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
      ),
    );
  }

  Widget _buildPrimaryField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      validator: _requiredValidator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF5C71D1).withOpacity(0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF5C71D1).withOpacity(0.14),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF5C71D1), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = _questions[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D26),
                ),
              ),
              const Spacer(),
              if (_questions.length > 1)
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: q.questionController,
            validator: _requiredValidator,
            maxLines: 2,
            decoration: _questionInputDecoration('Question text'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: q.optionAController,
            validator: _requiredValidator,
            decoration: _questionInputDecoration('Option A'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: q.optionBController,
            validator: _requiredValidator,
            decoration: _questionInputDecoration('Option B'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: q.optionCController,
            validator: _requiredValidator,
            decoration: _questionInputDecoration('Option C'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: q.optionDController,
            validator: _requiredValidator,
            decoration: _questionInputDecoration('Option D'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: q.correctOption,
            decoration: _questionInputDecoration('Correct Option'),
            items: const [
              DropdownMenuItem(value: 'A', child: Text('Correct: Option A')),
              DropdownMenuItem(value: 'B', child: Text('Correct: Option B')),
              DropdownMenuItem(value: 'C', child: Text('Correct: Option C')),
              DropdownMenuItem(value: 'D', child: Text('Correct: Option D')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => q.correctOption = value);
            },
          ),
        ],
      ),
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
              Icons.quiz_rounded,
              color: Color(0xFF5C71D1),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Builder',
                  style: TextStyle(
                    color: Color(0xFF1A1D26),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create question sets for your current grade and subject.',
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

  InputDecoration _questionInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C71D1).withOpacity(0.14),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: const Color(0xFF5C71D1).withOpacity(0.14),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF5C71D1), width: 1.2),
      ),
    );
  }
}

class _QuestionFormData {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  String correctOption = 'A';

  void dispose() {
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
  }
}
