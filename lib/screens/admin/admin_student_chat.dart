import 'package:flutter/material.dart';
import 'admin_role_chat_inbox_screen.dart';

class StudentChatScreen extends StatelessWidget {
  const StudentChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminRoleChatInboxScreen(
      role: 'Student',
      title: 'Student Live Support',
      accentColor: Color(0xFF5C71D1),
    );
  }
}
