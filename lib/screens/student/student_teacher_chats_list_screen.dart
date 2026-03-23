import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'student_chat_with_teacher_screen.dart';

class StudentTeacherChatsListScreen extends StatefulWidget {
  const StudentTeacherChatsListScreen({super.key});

  @override
  State<StudentTeacherChatsListScreen> createState() =>
      _StudentTeacherChatsListScreenState();
}

class _StudentTeacherChatsListScreenState
    extends State<StudentTeacherChatsListScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Map<String, Future<String>> _teacherNameCache = {};

  Future<String> _getTeacherName(String teacherId) {
    if (_teacherNameCache.containsKey(teacherId)) {
      return _teacherNameCache[teacherId]!;
    }

    final future = FirebaseFirestore.instance
        .collection('users')
        .doc(teacherId)
        .get()
        .then((doc) {
          final data = doc.data();
          if (data == null) return 'Teacher';
          return (data['fullName'] ?? data['firstName'] ?? 'Teacher')
              .toString();
        })
        .catchError((_) => 'Teacher');

    _teacherNameCache[teacherId] = future;
    return future;
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    return sameDay
        ? DateFormat('hh:mm a').format(dt)
        : DateFormat('dd MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = _currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Teacher Chats',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Please login to continue.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('teacher_student_chats')
                  .where('studentId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final docs = [...snapshot.data!.docs];
                docs.sort((a, b) {
                  final ta = a.data()['lastMessageAt'] as Timestamp?;
                  final tb = b.data()['lastMessageAt'] as Timestamp?;
                  final ma = ta?.millisecondsSinceEpoch ?? 0;
                  final mb = tb?.millisecondsSinceEpoch ?? 0;
                  return mb.compareTo(ma);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final teacherId = (data['teacherId'] ?? '').toString();
                    final lastMessage =
                        (data['lastMessage'] ?? 'Start chatting with teacher')
                            .toString();
                    final lastMessageAt = data['lastMessageAt'] as Timestamp?;

                    return FutureBuilder<String>(
                      future: _getTeacherName(teacherId),
                      builder: (context, teacherSnapshot) {
                        final teacherName = teacherSnapshot.data ?? 'Teacher';

                        return Material(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              teacherName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              _formatTime(lastMessageAt),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StudentChatWithTeacherScreen(
                                        teacherId: teacherId,
                                        teacherName: teacherName,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'No teacher chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When a teacher replies, your chats will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
