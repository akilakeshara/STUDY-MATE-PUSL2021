import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentFeedbackScreen extends StatefulWidget {
  const StudentFeedbackScreen({super.key});

  @override
  State<StudentFeedbackScreen> createState() => _StudentFeedbackScreenState();
}

class _StudentFeedbackScreenState extends State<StudentFeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your feedback first!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      String studentName = userData.data()?['firstName'] ?? "Unknown Student";
      String studentGrade = (userData.data()?['studentData']?['selectedGrade'] ?? "N/A").toString();

      await FirebaseFirestore.instance.collection('admin_feedbacks').add({
        'studentId': user?.uid,
        'studentName': studentName,
        'grade': studentGrade,
        'message': _feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _feedbackController.clear();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Thank You! ❤️", textAlign: TextAlign.center),
            content: const Text("Your feedback has been sent to the Admin successfully."),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C71D1)),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back home
                  },
                  child: const Text("Done", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Send Feedback 📣", style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5C71D1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We'd love to hear from you!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              "Share your suggestions, issues, or what you love about Study Mate.",
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
            ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Write your feedback here...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C71D1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submitFeedback,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
