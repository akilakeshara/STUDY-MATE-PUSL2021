import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class StudentLessonsScreen extends StatefulWidget {
  final String subjectName;

  const StudentLessonsScreen({super.key, required this.subjectName});

  @override
  State<StudentLessonsScreen> createState() => _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends State<StudentLessonsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.subjectName,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .where('subject', isEqualTo: widget.subjectName)
            .where('status', isEqualTo: 'approved')
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

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildApprovedLessonCard(data, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovedLessonCard(Map<String, dynamic> data, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 35,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                data['title'] ?? data['lessonName'] ?? "Untitled Lesson",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            "Taught by ${data['teacherName'] ?? 'Verified Instructor'}",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        onTap: () => _openVideoPlayer(data, theme),
      ),
    );
  }

  void _openVideoPlayer(Map<String, dynamic> data, ThemeData theme) {
    String? videoId = YoutubePlayer.convertUrlToId(data['videoUrl'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (videoId != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: videoId,
                            flags: const YoutubePlayerFlags(autoPlay: false),
                          ),
                          showVideoProgressIndicator: true,
                        ),
                      ),
                    const SizedBox(height: 25),
                    Text(
                      data['title'] ?? "Untitled Lesson",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildAdminTag(theme),
                    const Divider(height: 40),
                    Text(
                      "DESCRIPTION",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['description'] ??
                          "No description provided for this approved content.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          "BACK TO LESSONS",
                          style: TextStyle(
                            color: theme.scaffoldBackgroundColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTag(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
          const SizedBox(width: 5),
          Text(
            "ADMIN APPROVED",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: theme.dividerColor.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            "No approved lessons yet!",
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
