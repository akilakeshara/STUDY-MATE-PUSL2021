import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher_chat_with_student_screen.dart';

class StudentsProgressScreen extends StatefulWidget {
  final String? initialSubject;
  const StudentsProgressScreen({super.key, this.initialSubject});

  @override
  State<StudentsProgressScreen> createState() => _StudentsProgressScreenState();
}

class _StudentsProgressScreenState extends State<StudentsProgressScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final Map<String, Future<_ProgressData>> _progressCache =
      <String, Future<_ProgressData>>{};
  late final Future<_TeacherStudentsData> _teacherStudentsFuture;
  static const int _pageSize = 12;
  static const double _lowProgressThreshold = 40;
  int _visibleStudentCount = _pageSize;
  _ProgressFilter _progressFilter = _ProgressFilter.all;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject;
    _teacherStudentsFuture = _loadTeacherAndStudents();
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _extractGradeKey(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return '';
    final match = RegExp(r'\d+').firstMatch(normalized);
    if (match != null) {
      return match.group(0) ?? normalized;
    }
    return normalized.replaceAll(RegExp(r'[^a-z]'), '');
  }

  bool _isGradeMatch(String studentGrade, String teacherGrade) {
    final sg = _normalize(studentGrade);
    final tg = _normalize(teacherGrade);
    final sgKey = _extractGradeKey(studentGrade);
    final tgKey = _extractGradeKey(teacherGrade);

    if (tg.isEmpty || tg == 'not set') return true;
    if (sg.isEmpty || sg == 'n/a') return false;

    if (sgKey.isNotEmpty && tgKey.isNotEmpty && sgKey == tgKey) {
      return true;
    }

    return sg == tg || sg.contains(tg) || tg.contains(sg);
  }

  double _subjectProgressPercentage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String subject,
  ) {
    final normalizedSubject = _normalize(subject);

    for (final doc in docs) {
      final data = doc.data();
      final docSubject = _normalize((data['subject'] ?? '').toString());
      if (docSubject != normalizedSubject) continue;

      final lastQuizPercentage = (data['lastQuizPercentage'] as num?)
          ?.toDouble();
      if (lastQuizPercentage != null) {
        return lastQuizPercentage.clamp(0, 100).toDouble();
      }

      final overall = (data['overall'] as num?)?.toDouble();
      if (overall != null) {
        return (overall * 100).clamp(0, 100).toDouble();
      }

      final quizScore = (data['quizScore'] as num?)?.toDouble();
      if (quizScore != null) {
        return ((quizScore / 10) * 100).clamp(0, 100).toDouble();
      }
    }

    return 0;
  }

  int _subjectQuizAttempts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String subject,
  ) {
    final normalizedSubject = _normalize(subject);
    for (final doc in docs) {
      final data = doc.data();
      final docSubject = _normalize((data['subject'] ?? '').toString());
      if (docSubject != normalizedSubject) continue;
      return (data['quizAttemptsCount'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>> _loadTeacherData() async {
    if (_currentUser == null) return <String, dynamic>{};

    final teacherSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();

    return teacherSnap.data() ?? <String, dynamic>{};
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _loadStudents(
    String teacherGrade,
  ) async {
    if (_currentUser == null) return [];

    // Fetch all users with role 'Student'
    final studentSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'Student')
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> allStudents = studentSnap.docs;

    final normalizedGrade = _normalize(teacherGrade);
    final bool shouldFilterByGrade =
        normalizedGrade.isNotEmpty && normalizedGrade != 'not set';

    if (!shouldFilterByGrade) return allStudents;

    return allStudents.where((doc) {
      final data = doc.data();
      if (data == null) return false;

      final dynamic studentDataRaw = data['studentData'];
      final Map<String, dynamic>? studentData =
          studentDataRaw is Map<String, dynamic> ? studentDataRaw : null;

      final studentGrade =
          (studentData?['selectedGrade'] ??
                  studentData?['grade'] ??
                  data['selectedGrade'] ??
                  data['grade'] ??
                  '')
              .toString();
      return _isGradeMatch(studentGrade, teacherGrade);
    }).toList();
  }

  Future<_TeacherStudentsData> _loadTeacherAndStudents() async {
    final teacherData = await _loadTeacherData();
    final dynamic teacherMetaRaw = teacherData['teacherData'];
    final Map<String, dynamic>? teacherMeta =
        teacherMetaRaw is Map<String, dynamic> ? teacherMetaRaw : null;

    final rawExpertise = teacherMeta?['expertise'];
    List<String> subjects = [];
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

    final teacherGrade = (teacherMeta?['teachingGrade'] ?? '').toString();
    final students = await _loadStudents(teacherGrade);

    if (_selectedSubject == null && subjects.isNotEmpty) {
      _selectedSubject = subjects.first;
    }

    return _TeacherStudentsData(
      subjects: subjects,
      grade: teacherGrade,
      students: students,
    );
  }

  Future<_ProgressData> _loadStudentProgress(
    String studentId,
    String subject,
  ) async {
    final progressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .collection('progress');

    final progressSnap = await progressRef.get();
    final docs = progressSnap.docs;
    return _ProgressData(
      percentage: _subjectProgressPercentage(docs, subject),
      attempts: _subjectQuizAttempts(docs, subject),
    );
  }

  Future<_ProgressData> _getProgressFuture(String studentId, String subject) {
    final key = '${studentId}_${_normalize(subject)}';
    return _progressCache.putIfAbsent(
      key,
      () => _loadStudentProgress(studentId, subject),
    );
  }

  Future<List<_StudentProgressItem>> _loadStudentsWithProgress(
    List<DocumentSnapshot<Map<String, dynamic>>> students,
    String subject,
  ) async {
    final List<_StudentProgressItem> items = [];

    for (final doc in students) {
      final progress = await _getProgressFuture(doc.id, subject);
      items.add(_StudentProgressItem(studentDoc: doc, progress: progress));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (_currentUser == null)
                      const Center(child: Text('Please login again.'))
                    else
                      FutureBuilder<_TeacherStudentsData>(
                        future: _teacherStudentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF5C71D1),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF1F4FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFF5C71D1,
                                  ).withOpacity(0.08),
                                ),
                              ),
                              child: const Text(
                                'Failed to load student progress. Please try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF616A89)),
                              ),
                            );
                          }

                          final data = snapshot.data;
                          if (data == null) {
                            return const SizedBox.shrink();
                          }

                          final students = data.students;
                          final allSubjects = data.subjects;
                          final teacherGrade = data.grade;
                          final currentSubject = _selectedSubject ?? (allSubjects.isNotEmpty ? allSubjects.first : "General");

                          if (students.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFF1F4FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(
                                    0xFF5C71D1,
                                  ).withOpacity(0.08),
                                ),
                              ),
                              child: const Text(
                                'No students available right now.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF616A89)),
                              ),
                            );
                          }

                          final displayedStudents = students
                              .take(_visibleStudentCount)
                              .toList();
                          final hasMoreStudents =
                              students.length > displayedStudents.length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECT SUBJECT',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 38,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: allSubjects.length,
                                  itemBuilder: (context, index) {
                                    final sub = allSubjects[index];
                                    final isSelected = sub == currentSubject;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedSubject = sub;
                                          _progressCache.clear();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF5C71D1)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF5C71D1)
                                                : const Color(0xFF5C71D1)
                                                    .withOpacity(0.1),
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF5C71D1,
                                                    ).withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          sub,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF5C71D1),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                    icon: Icons.people_alt_rounded,
                                    label: 'Students',
                                    value: students.length.toString(),
                                  ),
                                  _buildInfoChip(
                                    icon: Icons.school_rounded,
                                    label: 'Grade',
                                    value: teacherGrade.isEmpty
                                        ? 'All'
                                        : teacherGrade,
                                  ),
                                  _buildInfoChip(
                                    icon: Icons.menu_book_rounded,
                                    label: 'Current',
                                    value: currentSubject,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildProgressFilterChip(
                                    label: 'All',
                                    selected:
                                        _progressFilter == _ProgressFilter.all,
                                    onTap: () {
                                      if (_progressFilter ==
                                          _ProgressFilter.all) {
                                        return;
                                      }
                                      setState(() {
                                        _progressFilter = _ProgressFilter.all;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildProgressFilterChip(
                                    label:
                                        'Only Low (<${_lowProgressThreshold.toInt()}%)',
                                    selected:
                                        _progressFilter ==
                                        _ProgressFilter.lowOnly,
                                    onTap: () {
                                      if (_progressFilter ==
                                          _ProgressFilter.lowOnly) {
                                        return;
                                      }
                                      setState(() {
                                        _progressFilter =
                                            _ProgressFilter.lowOnly;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<List<_StudentProgressItem>>(
                                future: _loadStudentsWithProgress(
                                  displayedStudents,
                                  currentSubject,
                                ),
                                builder: (context, progressListSnapshot) {
                                  if (progressListSnapshot.connectionState !=
                                      ConnectionState.done) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 24,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF5C71D1),
                                        ),
                                      ),
                                    );
                                  }

                                  final progressItems =
                                      progressListSnapshot.data ?? const [];

                                  final filteredItems =
                                      _progressFilter == _ProgressFilter.lowOnly
                                      ? progressItems.where((item) {
                                          return item.progress.percentage <
                                              _lowProgressThreshold;
                                        }).toList()
                                      : progressItems;

                                  if (filteredItems.isEmpty) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5C71D1,
                                        ).withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        _progressFilter ==
                                                _ProgressFilter.lowOnly
                                            ? 'No low-progress students in the current list.'
                                            : 'No students to display right now.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF616A89),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredItems[index];
                                      final studentDoc = item.studentDoc;
                                      final student = studentDoc.data();
                                      if (student == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final dynamic studentDataRaw =
                                          student['studentData'];
                                      final Map<String, dynamic>? studentData =
                                          studentDataRaw is Map<String, dynamic>
                                          ? studentDataRaw
                                          : null;

                                      return _buildStudentCard(
                                        name:
                                            (student['firstName'] ??
                                                    student['fullName'] ??
                                                    'Student')
                                                .toString(),
                                        studentId:
                                            (studentData?['studentID'] ??
                                                    studentDoc.id)
                                                .toString(),
                                        grade:
                                            (studentData?['selectedGrade'] ??
                                                    studentData?['grade'] ??
                                                    'N/A')
                                                .toString(),
                                        subject: currentSubject,
                                        percentage: item.progress.percentage,
                                        attempts: item.progress.attempts,
                                      );
                                    },
                                  );
                                },
                              ),
                              if (hasMoreStudents)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Center(
                                    child: Material(
                                      color: const Color(
                                        0xFF5C71D1,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          setState(() {
                                            _visibleStudentCount =
                                                (_visibleStudentCount +
                                                        _pageSize)
                                                    .clamp(0, students.length);
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 9,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.expand_more_rounded,
                                                size: 18,
                                                color: Color(0xFF5C71D1),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Show more students (${students.length - displayedStudents.length})',
                                                style: const TextStyle(
                                                  color: Color(0xFF5C71D1),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 172,
      floating: false,
      pinned: true,
      toolbarHeight: 64,
      backgroundColor: const Color(0xFFF8F9FD),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1A1D26),
          size: 20,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          margin: const EdgeInsets.fromLTRB(20, 84, 20, 14),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C71D1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF5C71D1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Insights',
                      style: TextStyle(
                        color: Color(0xFF1A1D26),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track grade-based progress and quiz performance',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF616A89),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        collapseMode: CollapseMode.parallax,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A1D26)),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String studentId,
    required String grade,
    required String subject,
    required double percentage,
    required int attempts,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFEFF3FF),
                child: Icon(Icons.person, color: Color(0xFF5C71D1)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ID : $studentId • Grade: $grade",
                      style: const TextStyle(
                        color: Color(0xFF616A89),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getColor(subject).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    color: _getColor(subject),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildProgressRow(
            subject,
            'Quiz Attempts: $attempts',
            (percentage / 100).clamp(0, 1),
            _getColor(subject),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFE8EDFB), thickness: 1),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: const Color(0xFF5C71D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherChatWithStudentScreen(
                        studentId: studentId,
                        studentName: name,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_rounded,
                        size: 16,
                        color: Color(0xFF5C71D1),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Message Student",
                        style: TextStyle(
                          color: Color(0xFF5C71D1),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    String subject,
    String lesson,
    double progress,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF1A1C2E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lesson,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF616A89),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE8EDFB),
              color: color,
              minHeight: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5C71D1)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF616A89),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1A1D26),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFF5C71D1).withOpacity(0.12)
          : const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF5C71D1).withOpacity(0.3)
                  : const Color(0xFF5C71D1).withOpacity(0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFF5C71D1)
                  : const Color(0xFF616A89),
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(String? subject) {
    switch (subject?.toLowerCase()) {
      case 'biology':
        return Colors.orangeAccent;
      case 'ict':
        return Colors.tealAccent.shade700;
      case 'mathematics':
        return Colors.blueAccent;
      case 'english':
        return Colors.purpleAccent;
      default:
        return const Color(0xFF5C71D1);
    }
  }
}

class _ProgressData {
  final double percentage;
  final int attempts;

  const _ProgressData({this.percentage = 0, this.attempts = 0});
}

enum _ProgressFilter { all, lowOnly }

class _StudentProgressItem {
  final DocumentSnapshot<Map<String, dynamic>> studentDoc;
  final _ProgressData progress;

  const _StudentProgressItem({
    required this.studentDoc,
    required this.progress,
  });
}

class _TeacherStudentsData {
  final List<String> subjects;
  final String grade;
  final List<DocumentSnapshot<Map<String, dynamic>>> students;

  const _TeacherStudentsData({
    required this.subjects,
    required this.grade,
    required this.students,
  });
}
