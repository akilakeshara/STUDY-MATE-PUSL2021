import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherCreateGameScreen extends StatefulWidget {
  const TeacherCreateGameScreen({super.key});

  @override
  State<TeacherCreateGameScreen> createState() =>
      _TeacherCreateGameScreenState();
}

class _TeacherCreateGameScreenState extends State<TeacherCreateGameScreen> {
  String _teacherSubject = "Loading...";
  String _selectedFormat = 'Multiple Choice Quiz'; // Default format
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  final List<Map<String, TextEditingController>> _controllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getTeacherExpertise();
    _addNewQuestionField();
  }

  Future<void> _getTeacherExpertise() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _teacherSubject =
            (doc.data()?['teacherData']?['expertise'] ?? "General");
      });
    }
  }

  void _addNewQuestionField() {
    setState(() {
      if (_selectedFormat == 'Multiple Choice Quiz') {
        _controllers.add({
          'question': TextEditingController(),
          'option1': TextEditingController(),
          'option2': TextEditingController(),
          'option3': TextEditingController(),
          'option4': TextEditingController(),
          'answer': TextEditingController(),
        });
      } else {
        _controllers.add({
          'question': TextEditingController(),
          'answer': TextEditingController(),
        });
      }
    });
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _publishGame() async {
    if (_controllers.any((c) => c['question']!.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all questions!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    List<Map<String, dynamic>> gameContent = _controllers.map((c) {
      Map<String, dynamic> data = {
        'question': c['question']!.text.trim(),
        'answer': c['answer']!.text.trim(),
      };
      if (_selectedFormat == 'Multiple Choice Quiz') {
        data['options'] = [
          c['option1']!.text.trim(),
          c['option2']!.text.trim(),
          c['option3']!.text.trim(),
          c['option4']!.text.trim(),
        ];
      }
      return data;
    }).toList();

    await FirebaseFirestore.instance.collection('puzzles').add({
      'teacherId': user?.uid,
      'subject': _teacherSubject,
      'gameFormat': _selectedFormat,
      'deadline': Timestamp.fromDate(_deadline),
      'questions': gameContent,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    setState(() => _isLoading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Activity Published Successfully! ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Create Activity 🎮",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Info
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF5C71D1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.subject, color: Color(0xFF5C71D1)),
                  const SizedBox(width: 10),
                  Text(
                    "Your Subject: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _teacherSubject,
                    style: const TextStyle(
                      color: Color(0xFF5C71D1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              "1. Select Game Format",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildFormatSelector(),

            const SizedBox(height: 25),
            const Text(
              "2. Set Deadline",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                "Valid Until: ${_deadline.toLocal()}".split(' ')[0],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF5C71D1),
              ),
              onTap: _selectDeadline,
            ),

            const SizedBox(height: 25),
            const Text(
              "3. Add Questions & Answers",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ..._controllers.asMap().entries.map(
              (entry) => _buildQuestionCard(entry.key, entry.value),
            ),

            const SizedBox(height: 15),
            Center(
              child: TextButton.icon(
                onPressed: _addNewQuestionField,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  "Add Another Question",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C71D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _publishGame,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Publish to Students",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      children: [
        _formatRadioTile('Multiple Choice Quiz', Icons.quiz_outlined),
        _formatRadioTile('Drag & Drop Puzzle', Icons.extension_outlined),
        _formatRadioTile('Code Breaker', Icons.terminal_outlined),
      ],
    );
  }

  Widget _formatRadioTile(String title, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      value: title,
      groupValue: _selectedFormat,
      onChanged: (val) {
        setState(() {
          _selectedFormat = val!;
          _controllers.clear();
          _addNewQuestionField();
        });
      },
    );
  }

  Widget _buildQuestionCard(int index, Map<String, TextEditingController> c) {
    return Card(
      margin: const EdgeInsets.only(top: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: c['question'],
              decoration: InputDecoration(
                labelText: "Question / Hint ${index + 1}",
                border: const UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: c['answer'],
              decoration: const InputDecoration(
                labelText: "Correct Answer",
                labelStyle: TextStyle(color: Color(0xFF2EBD85)),
              ),
            ),
            if (_selectedFormat == 'Multiple Choice Quiz') ...[
              const SizedBox(height: 15),
              const Text(
                "Wrong Options:",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              TextField(
                controller: c['option1'],
                decoration: const InputDecoration(labelText: "Option 1"),
              ),
              TextField(
                controller: c['option2'],
                decoration: const InputDecoration(labelText: "Option 2"),
              ),
              TextField(
                controller: c['option3'],
                decoration: const InputDecoration(labelText: "Option 3"),
              ),
              TextField(
                controller: c['option4'],
                decoration: const InputDecoration(labelText: "Option 4"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
