import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminRoleChatInboxScreen extends StatelessWidget {
  final String role;
  final String title;
  final Color accentColor;

  const AdminRoleChatInboxScreen({
    super.key,
    required this.role,
    required this.title,
    required this.accentColor,
  });

  String _resolveName(Map<String, dynamic> data) {
    final String fullName = (data['fullName'] ?? data['name'] ?? '')
        .toString()
        .trim();
    if (fullName.isNotEmpty) return fullName;

    final String firstName = (data['firstName'] ?? '').toString().trim();
    final String lastName = (data['lastName'] ?? '').toString().trim();
    final String combined = [
      firstName,
      lastName,
    ].where((e) => e.isNotEmpty).join(' ').trim();
    if (combined.isNotEmpty) return combined;

    final String email = (data['email'] ?? '').toString();
    if (email.contains('@')) return email.split('@').first;
    return 'Unknown User';
  }

  Future<List<_ChatPreview>> _loadChatPreviews(
    List<QueryDocumentSnapshot> users,
  ) async {
    final List<_ChatPreview> previews = [];

    for (final userDoc in users) {
      final data = userDoc.data() as Map<String, dynamic>;
      final String uid = userDoc.id;
      final String name = _resolveName(data);

      final latestSnap = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(uid)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (latestSnap.docs.isEmpty) {
        continue;
      }

      final latest = latestSnap.docs.first.data();
      final String text = (latest['text'] ?? '').toString();
      final Timestamp? timestamp = latest['timestamp'] as Timestamp?;

      previews.add(
        _ChatPreview(
          userId: uid,
          userName: name,
          latestText: text,
          timestamp: timestamp,
          hasUnread:
              latest['isAdmin'] == false && latest['isReadByAdmin'] != true,
        ),
      );
    }

    previews.sort((a, b) {
      final DateTime aTime = a.timestamp?.toDate() ?? DateTime(1970);
      final DateTime bTime = b.timestamp?.toDate() ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return previews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: role)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No $role users found.'));
          }

          final users = snapshot.data!.docs;

          return FutureBuilder<List<_ChatPreview>>(
            future: _loadChatPreviews(users),
            builder: (context, previewSnap) {
              if (previewSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final previews = previewSnap.data ?? [];

              if (previews.isEmpty) {
                return Center(child: Text('No incoming $role messages yet.'));
              }

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Chats: ${previews.length}',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: previews.length,
                      itemBuilder: (context, index) {
                        final preview = previews[index];
                        final String trailingText = preview.timestamp != null
                            ? DateFormat(
                                'hh:mm a',
                              ).format(preview.timestamp!.toDate())
                            : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withOpacity(0.16),
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _AdminConversationScreen(
                                    userId: preview.userId,
                                    userName: preview.userName,
                                    role: role,
                                    accentColor: accentColor,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: accentColor.withOpacity(0.15),
                              child: Icon(Icons.person, color: accentColor),
                            ),
                            title: Text(
                              preview.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              preview.latestText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (trailingText.isNotEmpty)
                                  Text(
                                    trailingText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  const Icon(Icons.chevron_right_rounded),
                                if (preview.hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatPreview {
  final String userId;
  final String userName;
  final String latestText;
  final Timestamp? timestamp;
  final bool hasUnread;

  const _ChatPreview({
    required this.userId,
    required this.userName,
    required this.latestText,
    required this.timestamp,
    required this.hasUnread,
  });
}

class _AdminConversationScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String role;
  final Color accentColor;

  const _AdminConversationScreen({
    required this.userId,
    required this.userName,
    required this.role,
    required this.accentColor,
  });

  @override
  State<_AdminConversationScreen> createState() =>
      _AdminConversationScreenState();
}

class _AdminConversationScreenState extends State<_AdminConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String? _adminUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final QuerySnapshot recentSnapshot = await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .get();

    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (final doc in recentSnapshot.docs) {
      final dynamic raw = doc.data();
      final Map<String, dynamic> data = raw is Map<String, dynamic>
          ? raw
          : <String, dynamic>{};
      final bool isFromAdmin = data['isAdmin'] == true;
      final bool isReadByAdmin = data['isReadByAdmin'] == true;
      if (isFromAdmin || isReadByAdmin) continue;

      batch.set(doc.reference, {
        'isReadByAdmin': true,
        'readByAdminAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();

    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .set({
          'hasUnreadForAdmin': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _markMessagesAsRead();

    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
          'senderId': _adminUid,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
          'isAdmin': true,
          'isReadByAdmin': true,
        });

    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .set({
          'hasUnreadForAdmin': false,
          'lastMessageText': text,
          'lastMessageIsAdmin': true,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FD),
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation.'),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data() as Map<String, dynamic>;
                    final bool isAdminMessage = (msg['isAdmin'] == true);
                    final Timestamp? ts = msg['timestamp'] as Timestamp?;
                    final String time = ts != null
                        ? DateFormat('hh:mm a').format(ts.toDate())
                        : '';

                    return Align(
                      alignment: isAdminMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isAdminMessage
                              ? widget.accentColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (msg['text'] ?? '').toString(),
                              style: TextStyle(
                                color: isAdminMessage
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            if (time.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  color: isAdminMessage
                                      ? Colors.white70
                                      : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a reply...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F4FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: widget.accentColor,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
