import 'package:flutter/material.dart';
import 'admin_role_chat_inbox_screen.dart';

class SponsorChatScreen extends StatelessWidget {
  const SponsorChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminRoleChatInboxScreen(
      role: 'Sponsor',
      title: 'Sponsor Portal',
      accentColor: Color(0xFF4A5CB3),
    );
  }
}
