import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TeacherChatWithStudentScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const TeacherChatWithStudentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<TeacherChatWithStudentScreen> createState() =>
      _TeacherChatWithStudentScreenState();
}

class _TeacherChatWithStudentScreenState
    extends State<TeacherChatWithStudentScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _replyingTo;

  String get _chatDocId {
    final teacherId = _currentUser?.uid ?? 'unknown_teacher';
    return '${teacherId}_${widget.studentId}';
  }

  void _onReply(Map<String, dynamic> message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('teacher_student_chats')
        .doc(_chatDocId);

    final batch = FirebaseFirestore.instance.batch();
    final timestamp = FieldValue.serverTimestamp();
    final messageRef = chatRef.collection('messages').doc();

    batch.set(chatRef, {
      'teacherId': _currentUser.uid,
      'studentId': widget.studentId,
      'lastMessage': text,
      'lastMessageAt': timestamp,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    batch.set(messageRef, {
      'senderId': _currentUser.uid,
      'senderRole': 'teacher',
      'text': text,
      'timestamp': timestamp,
      'studentId': widget.studentId,
      'teacherId': _currentUser.uid,
      if (_replyingTo != null) 'replyTo': _replyingTo,
    });

    if (_replyingTo != null) _cancelReply();

    await batch.commit();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatStream = FirebaseFirestore.instance
        .collection('teacher_student_chats')
        .doc(_chatDocId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1D26),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C71D1).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1D26),
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Student Chat',
                  style: TextStyle(
                    color: Color(0xFF5C71D1),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 10),
                        Text(
                          'Something went wrong: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF616A89)),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 22),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF5C71D1).withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C71D1).withOpacity(0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: Color(0xFF5C71D1),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Start conversation with student.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF616A89),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final bool isMe = data['senderId'] == _currentUser?.uid;
                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    return _buildGlassmorphicBubble(
                      messageId: doc.id,
                      text: (data['text'] ?? '').toString(),
                      isMe: isMe,
                      time: ts,
                      replyTo: data['replyTo'] as Map<String, dynamic>?,
                    );
                  },
                );
              },
            ),
          ),
          _buildEnhancedInput(),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicBubble({
    required String messageId,
    required String text,
    required bool isMe,
    required Timestamp? time,
    Map<String, dynamic>? replyTo,
  }) {
    final timeLabel = time != null
        ? DateFormat('hh:mm a').format(time.toDate())
        : '...';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildMessageMenuTrigger(
            isMe: isMe,
            messageId: messageId,
            text: text,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          const Color(0xFFF1F4FF).withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isMe ? 22 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 22),
                ),
                border: Border.all(
                  color: isMe
                      ? Colors.white.withOpacity(0.15)
                      : const Color(0xFF5C71D1).withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? const Color(0xFF5C71D1).withOpacity(0.24)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (replyTo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.black.withOpacity(0.12)
                            : const Color(0xFF5C71D1).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: isMe ? Colors.white70 : const Color(0xFF5C71D1),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        replyTo['text'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.blueGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1A1D26),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 14),
            child: Text(
              timeLabel,
              style: TextStyle(
                color: Colors.blueGrey.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageMenuTrigger({
    required bool isMe,
    required String messageId,
    required String text,
    required Widget child,
  }) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(messageId, text, isMe),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: 0,
            bottom: 0,
            right: isMe ? null : -35,
            left: isMe ? -35 : null,
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: Colors.blueGrey.withOpacity(0.3),
                ),
                onPressed: () => _showMessageOptions(messageId, text, isMe),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(String messageId, String text, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                _onReply({'id': messageId, 'text': text});
              },
            ),
            _buildOptionTile(
              icon: Icons.copy_rounded,
              label: 'Copy Text',
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (isMe) ...[
              _buildOptionTile(
                icon: Icons.edit_rounded,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(messageId, text);
                },
              ),
              _buildOptionTile(
                icon: Icons.delete_sweep_rounded,
                label: 'Delete',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF5C71D1)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color ?? const Color(0xFF1A1D26),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildEnhancedInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null) _buildReplyPreview(),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FF),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5C71D1).withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5C71D1).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFF5C71D1), width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18, color: Color(0xFF5C71D1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5C71D1),
                  ),
                ),
                Text(
                  _replyingTo!['text'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.blueGrey),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  // Edit message function
  Future<void> _editMessage(String messageId, String oldText) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: oldText);
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Edit your message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (newText != null && newText.isNotEmpty && newText != oldText) {
      await FirebaseFirestore.instance
          .collection('teacher_student_chats')
          .doc(_chatDocId)
          .collection('messages')
          .doc(messageId)
          .update({'text': newText});
    }
  }

  // Delete message function
  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('teacher_student_chats')
          .doc(_chatDocId)
          .collection('messages')
          .doc(messageId)
          .delete();
    }
  }
}
