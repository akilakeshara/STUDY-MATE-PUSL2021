import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Screens
import 'teacher_chat_with_admin_screen.dart';
import 'students_progress_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_lessons_list_screen.dart';
import 'teacher_student_chat_list_screen.dart';
import 'teacher_subject_actions_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  String teacherName = "";
  String teacherID = "";
  String teacherGrade = "";
  List<String> subjects = [];
  int _selectedIndex = 0;

  Map<String, dynamic> stats = {
    "courses": "0",
    "audience": "0",
    "messages": "0",
  };

  StreamSubscription? _userSub;
  final List<StreamSubscription> _statsSubs = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    for (var sub in _statsSubs) {
      sub.cancel();
    }
    super.dispose();
  }


  void _fetchTeacherData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fallback name from FirebaseAuth to show something immediately
      teacherName = user.displayName ?? "Teacher";

      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          final loadedGrade =
              (data?['teacherData']?['teachingGrade'] as String?) ?? "Not Set";

          setState(() {
            teacherName = (data?['fullName'] ?? user.displayName ?? "Teacher");
            teacherID =
                (data?['teacherData']?['teacherID'] as String?) ?? "TCH-0001";
            teacherGrade = loadedGrade;
            final rawExpertise = data?['teacherData']?['expertise'];
            if (rawExpertise is List) {
              subjects = List<String>.from(rawExpertise);
            } else if (rawExpertise is String) {
              subjects = rawExpertise
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
            if (subjects.isEmpty) subjects = ["General"];
          });
          _fetchStatistics(user.uid, loadedGrade);
        }
      });
    }
  }

  String _lastFetchedGrade = "";

  void _fetchStatistics(String teacherUid, String teacherGrade) {
    if (teacherGrade == _lastFetchedGrade && _statsSubs.isNotEmpty) return;
    _lastFetchedGrade = teacherGrade;

    // Clear old stats subscriptions
    for (var sub in _statsSubs) {
      sub.cancel();
    }
    _statsSubs.clear();

    _statsSubs.add(
      FirebaseFirestore.instance
          .collection('lessons')
          .where('teacherId', isEqualTo: teacherUid)
          .snapshots()
          .listen((snap) {
        if (mounted)
          setState(() => stats["courses"] = snap.docs.length.toString());
      }),
    );

    _statsSubs.add(
      FirebaseFirestore.instance
          .collection('teacher_student_chats')
          .where('teacherId', isEqualTo: teacherUid)
          .snapshots()
          .listen((snap) {
        if (mounted) {
          setState(() => stats["audience"] = snap.docs.length.toString());
        }
      }),
    );

    _statsSubs.add(
      FirebaseFirestore.instance
          .collection('teacher_student_chats')
          .where('teacherId', isEqualTo: teacherUid)
          .snapshots()
          .listen((snap) {
        if (mounted)
          setState(() => stats["messages"] = snap.docs.length.toString());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldExit = await _showExitDialog();
        if (shouldExit && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                _buildModernHeader(),
                const SizedBox(height: 25),
                _buildSubjectHub(),
                const SizedBox(height: 25),
                _buildActionGrid(),
                const SizedBox(height: 35),
                _buildSectionTitle(
                  "Recent Lessons",
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherLessonsListScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _buildDynamicLessonList(),
                const SizedBox(height: 35),
                _buildSectionTitle("Performance Insights", showSeeAll: false),
                const SizedBox(height: 15),
                _buildModernStatsGrid(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  void _showLessonPreview(Map<String, dynamic> data) {
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
                      Container(
                        height: 210,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.video_library_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _badge(
                          data['status']?.toUpperCase() ?? "PENDING",
                          data['status'] == 'approved'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        _badge(
                          data['grade'] ?? "N/A",
                          const Color(0xFF5C71D1),
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
                        color: const Color(0xFF64748B),
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

  Widget _buildActionGrid() {
    return Column(
      children: [
        Row(
          children: [
            _actionCard(
              "Student Progress",
              Icons.insights_rounded,
              const Color(0xFF2EBD85),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentsProgressScreen(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _actionCard(
              "Student Inbox",
              Icons.chat_bubble_outline_rounded,
              const Color(0xFFF3A31D),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherStudentChatListScreen(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionCard(
              "Admin Chat",
              Icons.support_agent_rounded,
              const Color(0xFF5C71D1),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatWithAdminScreen(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _actionCard(
              "Management",
              Icons.settings_suggest_rounded,
              const Color(0xFF64748B),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeacherProfileScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header, Stats, List Components ---
  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName.isEmpty ? "Welcome back" : teacherName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (teacherID.isNotEmpty || teacherGrade.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (teacherID.isNotEmpty)
                        _badge(teacherID, const Color(0xFF5C71D1)),
                      if (teacherGrade.isNotEmpty)
                        _badge(teacherGrade, const Color(0xFFF3A31D)),
                      for (var sub in subjects)
                        _badge(sub, const Color(0xFF5C71D1)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No new notifications")),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10),
    ),
  );

  Widget _buildModernStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 2.5,
        children: [
          _statTile(
            stats['courses'],
            "Lessons",
            Icons.book_rounded,
            Colors.orange,
          ),
          _statTile(
            stats['audience'],
            "Students",
            Icons.people_rounded,
            Colors.blue,
          ),
          _statTile("0h", "Watch Time", Icons.timer_rounded, Colors.purple),
          _statTile(
            stats['messages'],
            "Messages",
            Icons.chat_rounded,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _statTile(String val, String label, IconData icon, Color color) => Row(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildSubjectHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 15),
          child: Text(
            "MY SUBJECTS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherSubjectActionsScreen(
                      subjectName: subject,
                      teacherName: teacherName,
                      teacherGrade: teacherGrade,
                    ),
                  ),
                ),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5C71D1),
                        const Color(0xFF4354B0).withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5C71D1).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        subject,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Tap for actions",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
  }

  Widget _buildDynamicLessonList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .where('teacherId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No lessons yet.",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          );
        }
        var docs = snapshot.data!.docs;
        return SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var lesson = docs[index].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () => _showLessonPreview(lesson),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFF94A3B8),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          lesson['title'] ?? lesson['lessonName'] ?? "Lesson",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title, {
    VoidCallback? onSeeAll,
    bool showSeeAll = true,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: Color(0xFF0F172A),
        ),
      ),
      if (showSeeAll)
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            "See All",
            style: TextStyle(
              color: const Color(0xFF5C71D1),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
    ],
  );

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, 0),
          _navItem(Icons.video_collection_rounded, 1),
          _navItem(Icons.person_rounded, 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) => IconButton(
    icon: Icon(
      icon,
      color: _selectedIndex == index
          ? const Color(0xFF5C71D1)
          : const Color(0xFF94A3B8),
      size: 26,
    ),
    onPressed: () {
      setState(() => _selectedIndex = index);
      if (index == 1)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherLessonsListScreen(),
          ),
        );
      if (index == 2)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TeacherProfileScreen()),
        );
    },
  );

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "Exit App",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text("Are you sure you want to exit?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "No",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Yes",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5C71D1),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
