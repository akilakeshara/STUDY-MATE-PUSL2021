import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminViewFeedbackScreen extends StatelessWidget {
  const AdminViewFeedbackScreen({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown Date';
    DateTime date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Student Feedbacks",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1C2E), fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5C71D1), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedbacks').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF5C71D1)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 15),
                  const Text("No Feedbacks Yet!", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final feedbackDocs = snapshot.data!.docs;

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: feedbackDocs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final data = feedbackDocs[index].data() as Map<String, dynamic>;
              
              final studentName = data['studentName'] ?? 'Unknown Student';
              final feedbackText = data['feedbackText'] ?? 'No Message';
              final createdAt = data['timestamp'] as Timestamp?;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF5C71D1).withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF5C71D1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1C2E))),
                              const SizedBox(height: 3),
                              Text(_formatDate(createdAt), style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFEEF2FF), thickness: 1.5)),
                    Text(feedbackText, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
