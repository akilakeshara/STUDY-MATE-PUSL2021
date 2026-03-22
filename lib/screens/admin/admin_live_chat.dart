import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLiveChat extends StatefulWidget {
  final String chatId;

  const AdminLiveChat({super.key, required this.chatId});

  @override
  State<AdminLiveChat> createState() => _AdminLiveChatState();
}

class _AdminLiveChatState extends State<AdminLiveChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': messageText,
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'isAdmin': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msgData =
                        messages[index].data() as Map<String, dynamic>;
                    return _buildChatBubble(
                      msgData['text'] ?? "",
                      msgData['isAdmin'] ?? false,
                    );
                  },
                );
              },
            ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF5C71D1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Center(
              child: Text(
                "Admin Live Chat",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String message, bool isAdminSent) {
    return Align(
      alignment: isAdminSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isAdminSent
              ? const Color(0xFF5C71D1)
              : const Color(0xFFF1F3F9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isAdminSent ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a reply...",
                filled: true,
                fillColor: const Color(0xFFF1F3F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 15),
          CircleAvatar(
            backgroundColor: const Color(0xFF5C71D1),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
