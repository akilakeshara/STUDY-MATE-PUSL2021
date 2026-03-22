import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _lessonDuplicateKey(Map<String, dynamic> data) {
    final String lessonId = (data['lessonId'] ?? '').toString().trim();
    if (lessonId.isNotEmpty) return lessonId;

    return "${(data['teacherId'] ?? '').toString().trim()}|${(data['title'] ?? data['lessonName'] ?? '').toString().trim().toLowerCase()}|${(data['videoUrl'] ?? '').toString().trim()}|${(data['chapter'] ?? '').toString().trim()}|${(data['lessonNumber'] ?? '').toString().trim()}";
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _approveLesson(String docId) async {
    try {
      await _firestore.collection('lessons').doc(docId).update({
        'status': 'approved',
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      Navigator.pop(context);
      _showSnackBar(
        'Lesson Approved Successfully!',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _rejectLesson(String docId) async {
    try {
      await _firestore.collection('lessons').doc(docId).delete();
      Navigator.pop(context);
      _showSnackBar(
        'Lesson Rejected & Removed',
        backgroundColor: Colors.orange,
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _cleanupDuplicatePendingLessons() async {
    try {
      final snapshot = await _firestore
          .collection('lessons')
          .where('isApproved', isEqualTo: false)
          .get();

      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> seen = {};
      final batch = _firestore.batch();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        final key = _lessonDuplicateKey(doc.data());
        if (seen.containsKey(key)) {
          batch.delete(doc.reference);
          deletedCount++;
        } else {
          seen[key] = doc;
        }
      }

      if (deletedCount == 0) {
        _showSnackBar('No duplicate pending lessons found.');
        return;
      }

      await batch.commit();
      _showSnackBar(
        'Removed $deletedCount duplicate pending lesson(s).',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _showSnackBar('Cleanup failed: $e');
    }
  }

  Future<void> _confirmCleanupPendingLessons() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Duplicates'),
        content: const Text(
          'This will remove duplicate lesson requests from the pending approvals list. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cleanupDuplicatePendingLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Pending Approvals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cleanup Duplicates',
            onPressed: _confirmCleanupPendingLessons,
            icon: const Icon(Icons.cleaning_services_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('lessons')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 15),
                  const Text(
                    "Error loading pending lessons",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final rawDocs = snapshot.data!.docs;
          final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
          uniqueDocs = {};
          for (final doc in rawDocs) {
            final data = doc.data();
            final String key = _lessonDuplicateKey(data);

            if (!uniqueDocs.containsKey(key)) {
              uniqueDocs[key] = doc;
            }
          }

          final docs = uniqueDocs.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _buildSimpleTeacherCard(data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildSimpleTeacherCard(Map<String, dynamic> data, String docId) {
    return GestureDetector(
      onTap: () => _showLessonDetails(data, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF5C71D1).withValues(alpha: 0.1),
              child: const Icon(Icons.person_outline, color: Color(0xFF5C71D1)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (data['lessonName'] ?? data['title'] ?? 'Untitled Lesson').toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "By Teacher ID: ${data['teacherId']?.toString().substring(0, 8) ?? 'Unknown'}",
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonDetails(Map<String, dynamic> data, String docId) {
    String? videoId = YoutubePlayer.convertUrlToId(data['videoUrl'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['subject'] ?? "General",
                      style: const TextStyle(
                        color: Color(0xFF5C71D1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (data['lessonName'] ?? data['title'] ?? 'Untitled').toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (videoId != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: videoId,
                            flags: const YoutubePlayerFlags(autoPlay: false),
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),
                    const Text(
                      "DESCRIPTION",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['description'] ?? "No description.",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.grade_rounded,
                      "Grade",
                      data['grade'] ?? "N/A",
                    ),
                    _buildDetailRow(
                      Icons.layers_rounded,
                      "Chapter",
                      "Chapter ${data['chapter']}",
                    ),

                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _rejectLesson(docId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(
                                alpha: 0.1,
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Reject",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approveLesson(docId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1C1E),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              "Approve Lesson",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.done_all_rounded, size: 80, color: Colors.black12),
          SizedBox(height: 15),
          Text(
            'All caught up!',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
