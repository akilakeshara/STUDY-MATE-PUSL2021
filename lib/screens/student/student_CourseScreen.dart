import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/education_constants.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _searchQuery = "";
  String _selectedSubject = "All";

  String _normalizeGrade(String grade) {
    final trimmed = grade.trim();
    if (trimmed == "O/L (Grade 10-11)") return "O/L (Grade 10 - 11)";
    if (trimmed == "A/L (Grade 12-13)") return "A/L (Grade 12 - 13)";
    if (trimmed == "Grade 6-9") return "Grade 6 - 9";
    return trimmed;
  }

  String _extractYouTubeId(String url) {
    final String input = url.trim();
    if (input.isEmpty) return "";

    final String? converted = YoutubePlayer.convertUrlToId(
      input,
      trimWhitespaces: true,
    );
    if (converted != null && converted.isNotEmpty) {
      return converted;
    }

    final Uri? uri = Uri.tryParse(input);
    if (uri != null) {
      final List<String> segments = uri.pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .toList();

      if (segments.length >= 2 &&
          (segments.first == 'shorts' || segments.first == 'live')) {
        return segments[1];
      }
    }

    final RegExp idPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    if (idPattern.hasMatch(input)) {
      return input;
    }

    return "";
  }

  String _resolveThumbnail(Map<String, dynamic> lesson) {
    final String thumbnail = (lesson['thumbnail'] ?? "").toString().trim();
    if (thumbnail.isNotEmpty) return thumbnail;

    final String videoUrl = (lesson['videoUrl'] ?? "").toString();
    final String videoId = _extractYouTubeId(videoUrl);
    if (videoId.isEmpty) return "";

    return "https://img.youtube.com/vi/$videoId/hqdefault.jpg";
  }

  String _lessonUniqueKey(Map<String, dynamic> lesson) {
    final String lessonId = (lesson['lessonId'] ?? '').toString().trim();
    if (lessonId.isNotEmpty) return lessonId;

    final String teacherId = (lesson['teacherId'] ?? '').toString().trim();
    final String title = (lesson['title'] ?? lesson['lessonName'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final String videoUrl = (lesson['videoUrl'] ?? '').toString().trim();
    final String chapter = (lesson['chapter'] ?? '').toString().trim();
    final String lessonNumber = (lesson['lessonNumber'] ?? '')
        .toString()
        .trim();

    return '$teacherId|$title|$videoUrl|$chapter|$lessonNumber';
  }

  bool _matchesSearchQuery(Map<String, dynamic> data) {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final String title = (data['title'] ?? '').toString().toLowerCase();
    final String lessonName = (data['lessonName'] ?? '')
        .toString()
        .toLowerCase();
    final String subject = (data['subject'] ?? '').toString().toLowerCase();
    final String chapter = (data['chapter'] ?? '').toString().toLowerCase();

    return title.contains(query) ||
        lessonName.contains(query) ||
        subject.contains(query) ||
        chapter.contains(query);
  }

  void _openCourseDetails(Map<String, dynamic> lesson) {
    final String videoUrl = (lesson['videoUrl'] ?? '').toString();
    final String videoId = _extractYouTubeId(videoUrl);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentCourseDetailScreen(
          lesson: lesson,
          thumbnail: _resolveThumbnail(lesson),
          videoId: videoId,
        ),
      ),
    );
  }

  final List<String> _subjects = EducationConstants.studentCourseSubjects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          var studentData = userData?['studentData'] as Map<String, dynamic>?;
          String studentGrade = _normalizeGrade(
            (studentData?['selectedGrade'] ?? "O/L (Grade 10 - 11)").toString(),
          );

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(theme),
              SliverToBoxAdapter(child: _buildSubjectFilter(theme)),
              StreamBuilder<QuerySnapshot>(
                stream: _buildLessonQuery(studentGrade),
                builder: (context, lessonSnapshot) {
                  if (lessonSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!lessonSnapshot.hasData ||
                      lessonSnapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState(theme));
                  }

                  final filteredLessons = lessonSnapshot.data!.docs.where((
                    doc,
                  ) {
                    var data = doc.data() as Map<String, dynamic>;
                    return _matchesSearchQuery(data);
                  }).toList();

                  final Map<String, QueryDocumentSnapshot> uniqueLessons = {};
                  for (final doc in filteredLessons) {
                    final data = doc.data() as Map<String, dynamic>;
                    final key = _lessonUniqueKey(data);
                    uniqueLessons[key] = doc;
                  }

                  final lessons = uniqueLessons.values.toList();

                  if (lessons.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState(theme));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        var lessonData =
                            lessons[index].data() as Map<String, dynamic>;
                        return _buildCourseCard(lessonData, theme);
                      }, childCount: lessons.length),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) => SliverAppBar(
    floating: true,
    pinned: true,
    expandedHeight: 142,
    backgroundColor: theme.scaffoldBackgroundColor,
    elevation: 0,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        margin: EdgeInsets.fromLTRB(18, 46, 18, 0),
        padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withOpacity(0.8),
            ],
          ),
          border: Border.all(color: Color(0xFF5C71D1).withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF5C71D1).withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Courses",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(height: 12),
            _buildSearchBar(theme),
          ],
        ),
      ),
    ),
  );

  Widget _buildSearchBar(ThemeData theme) => Container(
    height: 50,
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Search your lessons...",
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );

  Widget _buildSubjectFilter(ThemeData theme) => Container(
    height: 60,
    margin: const EdgeInsets.symmetric(vertical: 15),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        bool isSelected = _selectedSubject == _subjects[index];
        return GestureDetector(
          onTap: () => setState(() => _selectedSubject = _subjects[index]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : theme.cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : theme.dividerColor.withOpacity(0.1),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              _subjects[index],
              style: TextStyle(
                color: isSelected ? theme.cardColor : Colors.blueGrey,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    ),
  );

  Stream<QuerySnapshot> _buildLessonQuery(String studentGrade) {
    Query query = FirebaseFirestore.instance.collection('lessons');

    query = query
        .where('grade', isEqualTo: studentGrade)
        .where('status', isEqualTo: 'approved');

    if (_selectedSubject != "All") {
      query = query.where('subject', isEqualTo: _selectedSubject);
    }

    return query.snapshots();
  }

  Widget _buildCourseCard(Map<String, dynamic> lesson, ThemeData theme) {
    final String title =
        (lesson['title'] ?? lesson['lessonName'] ?? "Untitled Lesson")
            .toString();
    final String subject = (lesson['subject'] ?? "General").toString();
    final String thumbnail = _resolveThumbnail(lesson);
    final int? completedChapters = int.tryParse(
      (lesson['completedChapters'] ?? '').toString(),
    );
    final int? totalChapters = int.tryParse(
      (lesson['totalChapters'] ?? '').toString(),
    );
    final bool hasChapterData =
        completedChapters != null && totalChapters != null && totalChapters > 0;
    final double progress = hasChapterData
        ? (completedChapters / totalChapters).clamp(0.0, 1.0)
        : 0.0;
    final bool hasDuration = false;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool compactLayout = screenWidth < 390;
    final double thumbnailWidth = compactLayout ? 132 : 160;
    final double thumbnailHeight = compactLayout ? 92 : 104;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5C71D1).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: compactLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseThumbnail(
                    thumbnail: thumbnail,
                    subject: subject,
                    width: double.infinity,
                    height: thumbnailHeight,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                  _buildCourseCardDetails(
                    lesson: lesson,
                    title: title,
                    hasChapterData: hasChapterData,
                    progress: progress,
                    completedChapters: completedChapters,
                    totalChapters: totalChapters,
                    hasDuration: hasDuration,
                    theme: theme,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseThumbnail(
                    thumbnail: thumbnail,
                    subject: subject,
                    width: thumbnailWidth,
                    height: thumbnailHeight,
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCourseCardDetails(
                      lesson: lesson,
                      title: title,
                      hasChapterData: hasChapterData,
                      progress: progress,
                      completedChapters: completedChapters,
                      totalChapters: totalChapters,
                      hasDuration: hasDuration,
                      theme: theme,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCourseThumbnail({
    required String thumbnail,
    required String subject,
    required double width,
    required double height,
    required ThemeData theme,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: height,
            width: width,
            color: theme.dividerColor.withOpacity(0.05),
            child: thumbnail.isNotEmpty
                ? Image.network(
                    thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.play_circle_fill_rounded,
                        color: theme.colorScheme.primary,
                        size: 40,
                      );
                    },
                  )
                : Icon(
                    Icons.play_circle_fill_rounded,
                    color: theme.colorScheme.primary,
                    size: 40,
                  ),
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subject,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCardDetails({
    required Map<String, dynamic> lesson,
    required String title,
    required bool hasChapterData,
    required double progress,
    required int? completedChapters,
    required int? totalChapters,
    required bool hasDuration,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasChapterData) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: theme.dividerColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$completedChapters/$totalChapters Chapter",
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            height: 34,
            width: 82,
            child: OutlinedButton(
              onPressed: () => _openCourseDetails(lesson),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text("View"),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          SizedBox(height: 15),
          Text(
            "No courses found!",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StudentCourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final String thumbnail;
  final String videoId;

  const _StudentCourseDetailScreen({
    required this.lesson,
    required this.thumbnail,
    required this.videoId,
  });

  @override
  State<_StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState
    extends State<_StudentCourseDetailScreen> {
  YoutubePlayerController? _controller;

  Future<void> _openVideoExternally() async {
    final String rawUrl = (widget.lesson['videoUrl'] ?? '').toString().trim();
    final String fallbackUrl = widget.videoId.isNotEmpty
        ? 'https://www.youtube.com/watch?v=${widget.videoId}'
        : '';
    final String targetUrl = rawUrl.isNotEmpty ? rawUrl : fallbackUrl;
    if (targetUrl.isEmpty) return;

    final Uri uri = Uri.parse(targetUrl);
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open YouTube link.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = widget.lesson;
    final String title =
        (lesson['title'] ?? lesson['lessonName'] ?? 'Untitled Lesson')
            .toString();
    final String subject = (lesson['subject'] ?? 'General').toString();
    final String description =
        (lesson['description'] ?? 'No description available.').toString();
    final String chapter = (lesson['chapter'] ?? '-').toString();
    final String lessonNumber = (lesson['lessonNumber'] ?? '-').toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: _controller != null
                      ? YoutubePlayer(
                          controller: _controller!,
                          showVideoProgressIndicator: true,
                        )
                      : (widget.thumbnail.isNotEmpty
                            ? Image.network(
                                widget.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: theme.dividerColor.withOpacity(0.05),
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 60,
                                  ),
                                ),
                              )
                            : Container(
                                color: theme.dividerColor.withOpacity(0.05),
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 60,
                                ),
                              )),
                ),
                if (_controller != null || widget.videoId.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Material(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _openVideoExternally,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                color: Theme.of(context).cardColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Open in YouTube',
                                style: TextStyle(
                                  color: Theme.of(context).cardColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).cardColor,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              subject,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lesson $lessonNumber â€¢ Chapter $chapter',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C71D1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Back To Lessons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
