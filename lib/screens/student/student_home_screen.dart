import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_settings_screen.dart';
import 'student_CourseScreen.dart';
import 'stundet_my_progress_screen.dart';
import 'student_ai_buddy_screen.dart';
import 'student_event_calendar_screen.dart';
import 'student_todo_planner_screen.dart';
import 'student_quiz_list_screen.dart';
import 'student_games_screen.dart';
import 'student_community_chat_screen.dart';
import 'student_mini_jobs_screen.dart';
import '../../core/page_transition.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  // --- YouTube & Thumbnail Helpers ---
  String _extractYouTubeId(String url) {
    final String input = url.trim();
    if (input.isEmpty) return "";
    final String? converted = YoutubePlayer.convertUrlToId(input, trimWhitespaces: true);
    if (converted != null && converted.isNotEmpty) return converted;
    final Uri? uri = Uri.tryParse(input);
    if (uri != null) {
      final List<String> segments = uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();
      if (segments.length >= 2 && (segments.first == 'shorts' || segments.first == 'live')) return segments[1];
    }
    final RegExp idPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idPattern.hasMatch(input)) return input;
    return "";
  }

  String _resolveLessonThumbnail(Map<String, dynamic> lesson) {
    final String thumbnail = (lesson['thumbnailUrl'] ?? lesson['thumbnail'] ?? lesson['imageUrl'] ?? "").toString().trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    final String videoUrl = (lesson['videoUrl'] ?? "").toString();
    final String videoId = _extractYouTubeId(videoUrl);
    if (videoId.isEmpty) return "";
    return "https://img.youtube.com/vi/$videoId/hqdefault.jpg";
  }

  void _openRoadmapLessonPlayer(Map<String, dynamic> lesson) {
    final String videoUrl = (lesson['videoUrl'] ?? "").toString();
    final String videoId = _extractYouTubeId(videoUrl);

    if (videoId.isEmpty) {
      setState(() => _currentIndex = 1);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: YoutubePlayer(
                        controller: YoutubePlayerController(initialVideoId: videoId, flags: const YoutubePlayerFlags(autoPlay: false)),
                        showVideoProgressIndicator: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final String fallbackUrl = videoId.isNotEmpty ? 'https://www.youtube.com/watch?v=$videoId' : '';
                          final String targetUrl = videoUrl.trim().isNotEmpty ? videoUrl.trim() : fallbackUrl;
                          if (targetUrl.isEmpty) return;
                          final bool opened = await launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
                          if (!opened && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open YouTube link.')));
                        },
                        icon: Icon(Icons.open_in_new_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                        label: Text('Open in YouTube', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text((lesson['title'] ?? lesson['lessonName'] ?? "Lesson").toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 10),
                    Text((lesson['description'] ?? "No description provided for this lesson.").toString(), style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
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

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to close the app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), style: TextButton.styleFrom(foregroundColor: const Color(0xFF5C71D1), textStyle: const TextStyle(fontWeight: FontWeight.w700)), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C71D1), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Yes')),
        ],
      ),
    );
    return shouldExit ?? false;
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool shouldExit = await _onWillPop();
        if (shouldExit && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            _buildBackgroundDecorations(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                const curve = Curves.easeOutQuart;
                var slideTween = Tween(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: curve));
                var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
                
                return FadeTransition(
                  opacity: animation.drive(fadeTween),
                  child: SlideTransition(
                    position: animation.drive(slideTween),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentPage(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent(key: const ValueKey(0));
      case 1:
        return const CourseScreen(key: ValueKey(1));
      case 2:
        return const StudentSettingsScreen(key: ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBackgroundDecorations() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: FadeInDown(
            duration: const Duration(seconds: 2),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(isDark ? 0.08 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: FadeInUp(
            duration: const Duration(seconds: 3),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(isDark ? 0.06 : 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent({Key? key}) {
    return StreamBuilder<DocumentSnapshot>(
      key: key,
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));

        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String name = userData?['firstName'] ?? "Student";
        var studentData = userData?['studentData'] as Map<String, dynamic>?;

        String id = studentData?['studentID'] ?? "STU-0000";
        int points = studentData?['points'] ?? 0;
        String grade = (studentData?['selectedGrade'] ?? "N/A").toString();
        List<dynamic> recentLessons = studentData?['recentLessons'] ?? [];
        final DateTime? lastReadAt = (userData?['lastContentNotificationReadAt'] as Timestamp?)?.toDate() ?? (studentData?['lastContentNotificationReadAt'] as Timestamp?)?.toDate();

        return CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            _buildPremiumHeader(name, id, grade, lastReadAt),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInDown(duration: const Duration(milliseconds: 600), child: _buildHomeOverviewStrip(grade: grade, points: points)),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: _buildSectionContainer(
                      title: 'Learning Roadmap', subtitle: 'Continue lessons made for your grade', actionLabel: 'See More', onActionTap: () => setState(() => _currentIndex = 1), child: _buildLearningRoadmapContent(recentLessons, grade),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionContainer(
                      title: 'Quick Actions', subtitle: 'Everything you need to learn and connect', child: _buildQuickActionsGrid(grade: grade, name: name),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: _buildSectionContainer(
                      title: 'News Center', subtitle: 'Latest school and learning updates', actionLabel: 'View All', onActionTap: _openLatestNewsSheet, child: _buildNewsFeedCard(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 400),
                    child: _buildSectionContainer(
                      title: 'Mini Jobs', subtitle: 'Earn points by completing small tasks', actionLabel: 'Explore', onActionTap: () => Navigator.push(context, PageTransition(child: const StudentMiniJobsScreen())), child: _buildMiniJobsPreviewCard(),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  DateTime? _parseDate(Map<String, dynamic> data) {
    final dynamic raw = data['createdAt'] ?? data['timestamp'] ?? data['publishedAt'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  bool _matchesGrade(Map<String, dynamic> data, String grade) {
    if (grade == 'N/A') return true;
    final String itemGrade = (data['grade'] ?? '').toString().trim();
    if (itemGrade.isEmpty) return true;
    return itemGrade.toLowerCase() == grade.toLowerCase();
  }

  Future<void> _markContentNotificationsAsRead() async {
    final String? uid = user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({'lastContentNotificationReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> _fetchUnreadNotifications({required String grade, required DateTime? lastReadAt}) async {
    final QuerySnapshot lessonSnap = await FirebaseFirestore.instance.collection('lessons').where('status', isEqualTo: 'approved').get();
    final QuerySnapshot quizSnap = await FirebaseFirestore.instance.collection('quizzes').where('status', isEqualTo: 'active').get();
    final List<Map<String, dynamic>> notifications = [];

    for (final doc in lessonSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (!_matchesGrade(data, grade)) continue;
      final DateTime? createdAt = _parseDate(data);
      if (lastReadAt == null || (createdAt != null && createdAt.isAfter(lastReadAt))) {
        notifications.add({'type': 'lesson', 'title': (data['title'] ?? data['lessonName'] ?? 'New Lesson').toString(), 'subtitle': (data['subject'] ?? 'General').toString(), 'createdAt': createdAt});
      }
    }
    for (final doc in quizSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (!_matchesGrade(data, grade)) continue;
      final DateTime? createdAt = _parseDate(data);
      if (lastReadAt == null || (createdAt != null && createdAt.isAfter(lastReadAt))) {
        notifications.add({'type': 'quiz', 'title': (data['title'] ?? 'New Quiz').toString(), 'subtitle': (data['subject'] ?? data['lessonName'] ?? 'General').toString(), 'createdAt': createdAt});
      }
    }
    notifications.sort((a, b) {
      final DateTime aDate = (a['createdAt'] as DateTime?) ?? DateTime(1970);
      final DateTime bDate = (b['createdAt'] as DateTime?) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return notifications;
  }

  String _formatSmallDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatHeaderDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _openAiBuddyChat() => Navigator.push(context, PageTransition(child: const StudentAiBuddyScreen()));
  void _openCommunityChat() => Navigator.push(context, PageTransition(child: const StudentCommunityChatScreen()));

  Future<void> _openNotificationPopup({required String grade, required DateTime? lastReadAt, required TapDownDetails details}) async {
    final notifications = await _fetchUnreadNotifications(grade: grade, lastReadAt: lastReadAt);
    if (!mounted || notifications.isEmpty) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    await showMenu<void>(
      context: context, color: Theme.of(context).cardColor, elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 270, maxWidth: 310),
      position: RelativeRect.fromRect(
        Rect.fromLTWH((details.globalPosition.dx - 230).clamp(10.0, overlay.size.width - 320.0), details.globalPosition.dy + 8, 300, 1),
        Offset.zero & overlay.size,
      ),
      items: notifications.take(5).map((item) {
        final bool isQuiz = item['type'] == 'quiz';
        final DateTime? createdAt = item['createdAt'] as DateTime?;
        return PopupMenuItem<void>(
          enabled: false, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(isQuiz ? Icons.quiz_rounded : Icons.play_lesson_rounded, color: const Color(0xFF5C71D1), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(item['subtitle'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600)),
              if (createdAt != null) Text(_formatSmallDate(createdAt), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 9)),
            ])),
          ]),
        );
      }).toList(),
    );
    await _markContentNotificationsAsRead();
  }

  Widget _buildContentNotificationButton({required String grade, required DateTime? lastReadAt}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lessons').where('status', isEqualTo: 'approved').snapshots(),
      builder: (context, lessonSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('quizzes').where('status', isEqualTo: 'active').snapshots(),
          builder: (context, quizSnapshot) {
            int unread = 0;
            for (final doc in [...(lessonSnapshot.data?.docs ?? []), ...(quizSnapshot.data?.docs ?? [])]) {
              final data = doc.data() as Map<String, dynamic>;
              if (!_matchesGrade(data, grade)) continue;
              final DateTime? createdAt = _parseDate(data);
              if (lastReadAt == null || (createdAt != null && createdAt.isAfter(lastReadAt))) unread++;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTapDown: (details) => _openNotificationPopup(grade: grade, lastReadAt: lastReadAt, details: details),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.9)]),
                      shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Icon(Icons.notifications_none_rounded, color: Theme.of(context).colorScheme.primary, size: 21),
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: -3, top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(999), border: Border.all(color: Theme.of(context).cardColor, width: 1.2)),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openLatestNewsSheet() async {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.2), borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 14),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [Icon(Icons.newspaper_rounded, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text('Latest News', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface))])),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('admin_news').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No news yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      final String title = (data['title'] ?? data['headline'] ?? 'News Update').toString();
                      final String content = (data['content'] ?? data['description'] ?? '').toString();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.12))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                          if (content.trim().isNotEmpty) ...[const SizedBox(height: 6), Text(content, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.4))],
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(String name, String id, String grade, DateTime? lastReadAt) => SliverAppBar(
    expandedHeight: 186, backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0, pinned: true,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        margin: const EdgeInsets.fromLTRB(18, 46, 18, 0), padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.9)]),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), blurRadius: 26, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Hi, $name", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.2)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [_buildSmallBadge(id, Theme.of(context).colorScheme.primary), _buildSmallBadge(grade, const Color(0xFF2EBD85))]),
              const SizedBox(height: 8),
              Text("Keep learning daily to improve faster", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 11.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('Today: ${_formatHeaderDate(DateTime.now())}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10.5, fontWeight: FontWeight.w700)),
            ])),
            const SizedBox(width: 10),
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.push(context, PageTransition(child: const StudentEventCalendarScreen())),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.9)]),
                    shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              _buildContentNotificationButton(grade: grade, lastReadAt: lastReadAt),
            ]),
          ],
        ),
      ),
    ),
  );

  Widget _buildSmallBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.25))),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 118), child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800))),
  );





  Widget _buildHomeOverviewStrip({required String grade, required int points}) => Column(
    children: [
      Row(children: [
        Expanded(child: _buildOverviewTile(icon: Icons.school_rounded, label: 'Grade', value: grade, accent: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: 10),
        Expanded(child: _buildOverviewTile(icon: Icons.stars_rounded, label: 'Points', value: '$points', accent: const Color(0xFFF3A31D))),
        const SizedBox(width: 10),
        Expanded(child: _buildOverviewTile(icon: Icons.auto_graph_rounded, label: 'My Progress', value: 'Open', accent: const Color(0xFF2EBD85), onTap: () => Navigator.push(context, PageTransition(child: const MyProgressScreen())))),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => Navigator.push(context, PageTransition(child: const StudentTodoPlannerScreen())),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2F3E8A), Color(0xFF1C2350)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 15),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("My Study Planner", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(height: 2), Text("Manage your daily tasks", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))])),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ]),
        ),
      ),
    ],
  );

  Widget _buildOverviewTile({required IconData icon, required String label, required String value, required Color accent, VoidCallback? onTap}) => Material(
    color: Colors.transparent, borderRadius: BorderRadius.circular(16),
    child: Ink(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withOpacity(0.15)), boxShadow: [BoxShadow(color: accent.withOpacity(0.09), blurRadius: 14, offset: const Offset(0, 6))]),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16), splashColor: accent.withOpacity(0.08), highlightColor: accent.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(height: 5),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    ),
  );

  Widget _buildSectionContainer({required String title, required String subtitle, String? actionLabel, VoidCallback? onActionTap, required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(actionLabel, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
        child,
      ],
    ),
  );

  Widget _buildQuickActionsGrid({required String grade, required String name}) => Column(
    children: [
      Row(
        children: [
          Expanded(child: _buildActionCard("AI Buddy", "Ask & Learn", Icons.smart_toy_rounded, const Color(0xFF5C71D1), _openAiBuddyChat)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionCard("Connect", "Student Community", Icons.people_alt_rounded, const Color(0xFF6A11CB), _openCommunityChat)),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _buildActionCard("Games", "Play & Learn", Icons.videogame_asset_rounded, const Color(0xFFFF9F1C), () => Navigator.push(context, PageTransition(child: const StudentGamesScreen())))),
          const SizedBox(width: 12),
          Expanded(child: _buildActionCard("Quizzes", "Test Knowledge", Icons.quiz_rounded, const Color(0xFF2EBD85), () => Navigator.push(context, PageTransition(child: StudentQuizListScreen(selectedGrade: grade, studentName: name))))),
        ],
      ),
    ],
  );

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) => _buildInteractiveCard(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 9.5, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );



  Widget _buildInteractiveCard({required Widget child, required VoidCallback onTap}) {
    return _PressableScaleWrapper(onTap: onTap, child: child);
  }

  Widget _buildNewsFeedCard() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('admin_news').orderBy('createdAt', descending: true).limit(8).snapshots(),
    builder: (context, snapshot) {
      final docs = snapshot.data?.docs ?? [];
      final bool hasNews = docs.isNotEmpty;
      final Map<String, dynamic>? latestData = hasNews ? docs.first.data() as Map<String, dynamic> : null;
      final String latestTitle = hasNews ? (latestData?['title'] ?? latestData?['headline'] ?? 'News Update').toString() : 'No news published yet';

      return Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.95)]),
            borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.14)),
            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: InkWell(
            onTap: _openLatestNewsSheet, borderRadius: BorderRadius.circular(20), splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.08), highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.rss_feed_rounded, color: Theme.of(context).colorScheme.primary, size: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Latest News & Updates', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(latestTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600))])),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Text(hasNews ? '${docs.length}' : '0', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildMiniJobsPreviewCard() => Material(
    color: Colors.transparent, borderRadius: BorderRadius.circular(20),
    child: Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.95)]),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2EBD85).withOpacity(0.14)),
        boxShadow: [BoxShadow(color: const Color(0xFF2EBD85).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, PageTransition(child: const StudentMiniJobsScreen())), borderRadius: BorderRadius.circular(20), splashColor: const Color(0xFF2EBD85).withOpacity(0.08), highlightColor: const Color(0xFF2EBD85).withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF2EBD85).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.work_history_rounded, color: const Color(0xFF2EBD85), size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Available Tasks', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text('Data Entry, AI Training & more', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600))])),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2EBD85).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Text('NEW', style: TextStyle(color: Color(0xFF2EBD85), fontSize: 11, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildDynamicRecentLearningList(List<dynamic> lessons) => SizedBox(
    height: 190,
    child: ListView.builder(
      scrollDirection: Axis.horizontal, physics: const ClampingScrollPhysics(), itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = Map<String, dynamic>.from(lessons[index] as Map<String, dynamic>);
        return _buildSubjectCard(lesson);
      },
    ),
  );

  Widget _buildLearningRoadmapContent(List<dynamic> recentLessons, String grade) {
    if (recentLessons.isNotEmpty) return _buildDynamicRecentLearningList(recentLessons);

    final lessonsStream = FirebaseFirestore.instance.collection('lessons').where('status', isEqualTo: 'approved').limit(12).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: lessonsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: Padding(padding: const EdgeInsets.all(10), child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyRecentLearning();

        final List<Map<String, dynamic>> fallbackLessons = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'subject': data['subject'] ?? 'General', 'title': data['title'] ?? data['lessonName'] ?? 'Lesson', 'progress': 0.0, 'grade': data['grade'], 'videoUrl': data['videoUrl'], 'description': data['description'], 'thumbnailUrl': data['thumbnailUrl'] ?? data['thumbnail'] ?? data['imageUrl']};
        }).where((lesson) {
          if (grade == 'N/A') return true;
          return (lesson['grade'] ?? '').toString() == grade;
        }).toList();

        if (fallbackLessons.isEmpty) return _buildEmptyRecentLearning();
        return _buildDynamicRecentLearningList(fallbackLessons);
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> lesson) => GestureDetector(
    onTap: () => _openRoadmapLessonPlayer(lesson),
    child: Container(
      width: 200, margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8))]),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (_resolveLessonThumbnail(lesson).isNotEmpty)
                  ? Image.network(_resolveLessonThumbnail(lesson), height: 72, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(height: 72, width: double.infinity, color: Theme.of(context).scaffoldBackgroundColor, alignment: Alignment.center, child: Icon(Icons.play_lesson_rounded, color: Theme.of(context).colorScheme.primary)))
                  : Container(height: 72, width: double.infinity, color: Theme.of(context).scaffoldBackgroundColor, alignment: Alignment.center, child: Icon(Icons.play_lesson_rounded, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(height: 10),
            Text((lesson['subject'] ?? "General").toString().toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
            const SizedBox(height: 5),
            Text((lesson['title'] ?? lesson['lessonName'] ?? "Lesson").toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: ((lesson['progress'] ?? 0.0) as num).toDouble(), minHeight: 4, backgroundColor: Theme.of(context).scaffoldBackgroundColor, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyRecentLearning() => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: const Text("No active courses.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));

  Widget _buildBottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(25, 0, 25, 30), height: 70,
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Theme.of(context).cardColor, Theme.of(context).cardColor.withOpacity(0.95)]),
      borderRadius: BorderRadius.circular(25), border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 12))],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildNavItem(Icons.home_rounded, "Home", 0), _buildNavItem(Icons.menu_book_rounded, "Learn", 1), _buildNavItem(Icons.settings_rounded, "Settings", 2)]),
  );

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(15), boxShadow: isActive ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 5))] : null),
        child: Row(children: [
          Icon(icon, color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 24),
          if (isActive) Padding(padding: const EdgeInsets.only(left: 8), child: Text(label, style: const TextStyle(color: Color(0xFF5C71D1), fontSize: 12, fontWeight: FontWeight.w900))),
        ]),
      ),
    );
  }
}

class _PressableScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScaleWrapper({required this.child, required this.onTap});

  @override
  State<_PressableScaleWrapper> createState() => _PressableScaleWrapperState();
}

class _PressableScaleWrapperState extends State<_PressableScaleWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        child: widget.child,
      ),
    );
  }
}
