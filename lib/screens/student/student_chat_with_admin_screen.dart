// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class ChatWithAdminScreen extends StatefulWidget {
  const ChatWithAdminScreen({super.key});

  @override
  State<ChatWithAdminScreen> createState() => _ChatWithAdminScreenState();
}

class _ChatWithAdminScreenState extends State<ChatWithAdminScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  
  String? _editingDocId;

  // Reply State
  String? _replyToId;
  String? _replyText;
  String? _replySenderName;

  void _sendMessage() async {
    final user = _currentUser;
    if (_messageController.text.trim().isEmpty || user == null) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    if (_editingDocId != null) {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(user.uid)
          .collection('messages')
          .doc(_editingDocId)
          .update({
        'text': messageText,
        'isEdited': true,
        'lastEdited': FieldValue.serverTimestamp(),
      });
      setState(() {
        _editingDocId = null;
      });
    } else {
      final Map<String, dynamic> docData = {
        'senderId': user.uid,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isAdmin': false,
        'isReadByAdmin': false,
      };

      if (_replyToId != null) {
        docData['replyToId'] = _replyToId;
        docData['replyText'] = _replyText;
        docData['replySenderName'] = _replySenderName;
      }

      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(user.uid)
          .collection('messages')
          .add(docData);

      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(user.uid)
          .set({
        'role': 'Student',
        'hasUnreadForAdmin': true,
        'lastMessageText': messageText,
        'lastMessageIsAdmin': false,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'support_message',
        'title': 'New Student Message',
        'message': messageText,
        'senderUid': user.uid,
        'role': 'Student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _replyToId = null;
        _replyText = null;
        _replySenderName = null;
      });
    }

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _deleteMessage(String docId) async {
    final user = _currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(user.uid)
        .collection('messages')
        .doc(docId)
        .delete();
  }

  void _startEditing(String docId, String text) {
    setState(() {
      _editingDocId = docId;
      _messageController.text = text;
      _replyToId = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingDocId = null;
      _messageController.clear();
    });
  }

  void _startReplying(String docId, String text, String senderName) {
    setState(() {
      _replyToId = docId;
      _replyText = text;
      _replySenderName = senderName;
      _editingDocId = null;
    });
  }

  void _cancelReplying() {
    setState(() {
      _replyToId = null;
      _replyText = null;
      _replySenderName = null;
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Sending...";
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF5C71D1);
    final user = _currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor,
              child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Support Mate",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "Support Team",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(user?.uid)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final docId = messages[index].id;
                    final bool isMe = data['senderId'] == user?.uid;

                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: _buildMessageBubble(data, isMe, theme, docId),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> data,
    bool isMe,
    ThemeData theme,
    String docId,
  ) {
    const primaryColor = Color(0xFF5C71D1);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isMe) _buildMessageActions(docId, data, isMe, theme),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [primaryColor, Color(0xFF7B8CF1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : theme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['replyText'] != null)
                        _buildRepliedMessageHeader(data, isMe, theme),
                      Text(
                        data['text'] ?? "",
                        style: TextStyle(
                          color: isMe ? Colors.white : theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (data['isEdited'] == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          "(edited)",
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey,
                            fontSize: 8,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isMe) _buildMessageActions(docId, data, isMe, theme),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 8, left: 4, right: 4),
            child: Text(
              _formatTimestamp(data['timestamp'] as Timestamp?),
              style: const TextStyle(color: Colors.grey, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliedMessageHeader(Map<String, dynamic> data, bool isMe, ThemeData theme) {
    const primaryColor = Color(0xFF5C71D1);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.black.withOpacity(0.1) : theme.scaffoldBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white70 : primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['replySenderName'] ?? "Support Team",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data['replyText'] ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageActions(String docId, Map<String, dynamic> data, bool isMe, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: Colors.grey.withOpacity(0.6),
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'reply') {
          _startReplying(docId, data['text'] ?? "", isMe ? "Me" : "Support Team");
        } else if (value == 'edit') {
          _startEditing(docId, data['text'] ?? "");
        } else if (value == 'delete') {
          _showDeleteConfirmation(docId);
        }
      },
      itemBuilder: (context) => [
        if (!isMe)
          const PopupMenuItem(
            value: 'reply',
            child: ListTile(
              leading: Icon(Icons.reply_rounded, size: 20),
              title: Text('Reply'),
              dense: true,
            ),
          ),
        if (isMe) ...[
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_rounded, size: 20),
              title: Text('Edit'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
              title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              dense: true,
            ),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(String docId) {
    const primaryColor = Color(0xFF5C71D1);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Message?"),
        content: const Text("Are you sure you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(docId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    const primaryColor = Color(0xFF5C71D1);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToId != null) _buildReplyPreview(primaryColor, theme),
          if (_editingDocId != null) _buildEditPreview(primaryColor, theme),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      const IconButton(
                        icon: Icon(Icons.add_rounded, color: Colors.grey, size: 22),
                        onPressed: null,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const IconButton(
                        icon: Icon(Icons.attach_file_rounded, color: Colors.grey, size: 22),
                        onPressed: null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [primaryColor, Color(0xFF7B8CF1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _editingDocId != null ? Icons.check_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(Color primaryColor, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: primaryColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Replying to $_replySenderName",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyText ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelReplying,
            child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview(Color primaryColor, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            "Editing message",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelEditing,
            child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
