import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'teacher_chat_with_student_screen.dart';

class TeacherStudentChatListScreen extends StatelessWidget {
  const TeacherStudentChatListScreen({super.key});

  DateTime _extractMessageTime(Map<String, dynamic> data) {
    final dynamic raw = data['lastMessageAt'] ?? data['updatedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime(1970);
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final String? teacherUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          'Student Inbox',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1D26),
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: teacherUid == null
          ? const Center(child: Text('Please login again.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('teacher_student_chats')
                  .where('teacherId', isEqualTo: teacherUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No student messages yet.',
                      style: TextStyle(color: Color(0xFF616A89)),
                    ),
                  );
                }

                final chats = snapshot.data!.docs.toList();

                chats.sort((a, b) {
                  final aTime = _extractMessageTime(a.data());
                  final bTime = _extractMessageTime(b.data());
                  return bTime.compareTo(aTime);
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: chats.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final chatDoc = chats[index];
                    final data = chatDoc.data();
                    final String chatId = chatDoc.id;
                    final String studentId = (data['studentId'] ?? '')
                        .toString()
                        .trim();
                    final String rootLastMessage = (data['lastMessage'] ?? '')
                        .toString();
                    final DateTime rootMessageTime = _extractMessageTime(data);

                    return FutureBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(studentId)
                          .get(),
                      builder: (context, studentSnapshot) {
                        final studentData = studentSnapshot.data?.data();
                        final String studentName =
                            (studentData?['firstName'] ??
                                    studentData?['fullName'] ??
                                    studentData?['name'] ??
                                    'Student')
                                .toString();

                        return StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>
                        >(
                          stream: FirebaseFirestore.instance
                              .collection('teacher_student_chats')
                              .doc(chatId)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, messageSnapshot) {
                            String displayMessage = rootLastMessage.trim();
                            DateTime displayTime = rootMessageTime;

                            if (messageSnapshot.hasData &&
                                messageSnapshot.data!.docs.isNotEmpty) {
                              final latest = messageSnapshot.data!.docs.first
                                  .data();
                              final latestText = (latest['text'] ?? '')
                                  .toString()
                                  .trim();
                              final latestTime = latest['timestamp'];

                              if (latestText.isNotEmpty) {
                                displayMessage = latestText;
                              }
                              if (latestTime is Timestamp) {
                                displayTime = latestTime.toDate();
                              }
                            }

                            if (displayMessage.isEmpty) {
                              displayMessage = 'Tap to open chat';
                            }

                            return Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF1F4FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF5C71D1,
                                  ).withOpacity(0.08),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF5C71D1,
                                    ).withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TeacherChatWithStudentScreen(
                                          studentId: studentId,
                                          studentName: studentName,
                                        ),
                                  ),
                                ),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFEFF3FF),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF5C71D1),
                                  ),
                                ),
                                title: Text(
                                  studentName,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1D26),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  displayMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF616A89),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  displayTime.year == 1970
                                      ? ''
                                      : _formatTime(displayTime),
                                  style: const TextStyle(
                                    color: Color(0xFF8B93AF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
