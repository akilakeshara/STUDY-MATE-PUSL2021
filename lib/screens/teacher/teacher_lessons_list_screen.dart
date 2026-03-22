import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'teacher_home_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherLessonsListScreen extends StatefulWidget {
  const TeacherLessonsListScreen({super.key});

  @override
  State<TeacherLessonsListScreen> createState() =>
      _TeacherLessonsListScreenState();
}

class _TeacherLessonsListScreenState extends State<TeacherLessonsListScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  int _selectedIndex = 1;

  Future<bool> _onWillPop() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
      (route) => false,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please Login Again")));
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            "My Approved Content",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
              color: Color(0xFF0F172A),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lessons')
              .where('teacherId', isEqualTo: uid)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
              );
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Error syncing data..."));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildModernLessonCard(data);
              },
            );
          },
        ),
        bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 25, 30),
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFF)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_rounded, "Home", 0),
          _buildNavItem(Icons.video_collection_rounded, "My Lessons", 1),
          _buildNavItem(Icons.person_rounded, "Profile", 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);

        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TeacherProfileScreen(),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF5C71D1).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF5C71D1).withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF5C71D1) : const Color(0xFF94A3B8),
              size: 24,
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF5C71D1),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLessonCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildLessonThumbnail(data),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? data['lessonName'] ?? "Untitled Lesson",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                   Text(
                    "${data['subject'] ?? 'General'} • ${data['grade'] ?? 'All Grades'}",
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: data['status'] == 'approved'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['status']?.toUpperCase() ?? "PENDING",
                      style: TextStyle(
                        color: data['status'] == 'approved'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFF5C71D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF5C71D1).withOpacity(0.15),
                  ),
                ),
                child: InkWell(
                  onTap: () => _showEnhancedDetailsSheet(data),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: const Text(
                      "VIEW",
                      style: TextStyle(
                        color: Color(0xFF5C71D1),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonThumbnail(Map<String, dynamic> data) {
    final String thumbnailUrl =
        (data['thumbnailUrl'] ??
                data['thumbUrl'] ??
                data['imageUrl'] ??
                data['coverImageUrl'] ??
                '')
            .toString()
            .trim();
    final String videoUrl = (data['videoUrl'] ?? '').toString().trim();
    final String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

    final String resolvedUrl = thumbnailUrl.isNotEmpty
        ? thumbnailUrl
        : (videoId != null
              ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
              : '');

    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF8E99F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: resolvedUrl.isEmpty
            ? const Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white,
                size: 35,
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5C71D1), Color(0xFF8E99F3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
      ),
    );
  }

  void _showEnhancedDetailsSheet(Map<String, dynamic> data) {
    String? videoId = YoutubePlayer.convertUrlToId(data['videoUrl'] ?? "");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 45,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (videoId != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: YoutubePlayer(
                            controller: YoutubePlayerController(
                              initialVideoId: videoId,
                              flags: const YoutubePlayerFlags(
                                autoPlay: false,
                                mute: false,
                              ),
                            ),
                            showVideoProgressIndicator: true,
                          ),
                        ),
                      )
                    else
                      _buildVideoPlaceholder(),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _buildBadge(
                          Icons.verified_user_rounded,
                          "APPROVED",
                          Colors.green,
                        ),
                        const SizedBox(width: 10),
                        _buildBadge(
                          Icons.school_rounded,
                          data['grade'] ?? "N/A",
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      data['title'] ?? data['lessonName'] ?? "Untitled Lesson",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Subject: ${data['subject'] ?? 'General'}",
                      style: const TextStyle(
                        color: Color(0xFF5C71D1),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
                    ),
                    const Text(
                      "DESCRIPTION",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['description'] ?? "No description available.",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blueGrey[800],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C71D1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "CLOSE PREVIEW",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
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

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(Icons.video_library_rounded, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C71D1).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_rounded,
              size: 70,
              color: const Color(0xFF5C71D1).withOpacity(0.18),
            ),
            const SizedBox(height: 14),
            const Text(
              "No Approved Content",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF1A1C2E),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Approved lessons will appear here.",
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
