import 'package:flutter/material.dart';
import 'admin_role_chat_inbox_screen.dart';

class TeacherChatScreen extends StatelessWidget {
  const TeacherChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminRoleChatInboxScreen(
      role: 'Teacher',
      title: 'Teacher Forum',
      accentColor: Color(0xFF7B8FF7),
    );
  }
}
