import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'student_teacher_chats_list_screen.dart';

class MyProgressScreen extends StatelessWidget {
  const MyProgressScreen({super.key});

  List<String> _gradeSubjects(String grade) {
    final g = grade.toLowerCase();

    if (g.contains('12') || g.contains('13') || g.contains('a/l')) {
      return const ['Combined Mathematics', 'Physics', 'Chemistry', 'Biology'];
    }

    return const ['Mathematics', 'Science', 'English', 'Sinhala'];
  }

  String _normalizeSubject(String subject) => subject.trim().toLowerCase();

  double _quizProgressFromMarks(int quizScore, double? lastQuizPercentage) {
    if (lastQuizPercentage != null && lastQuizPercentage > 0) {
      return (lastQuizPercentage / 100).clamp(0, 1).toDouble();
    }

    return (quizScore.clamp(0, 10) / 10).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async {
        return true;
      },

      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        appBar: AppBar(
          title: Text(
            "Learning Progress",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 21,
            ),
          ),

          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          elevation: 0,

          centerTitle: false,

          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),

        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),

          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

            final studentData =
                userData?['studentData'] as Map<String, dynamic>?;

            final selectedGrade =
                (studentData?['selectedGrade'] ?? 'Grade 10-11').toString();

            final gradeSubjects = _gradeSubjects(selectedGrade);

            return ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(overscroll: false),

              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),

                padding: const EdgeInsets.symmetric(horizontal: 22),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const SizedBox(height: 12),

                    _buildTeacherConnectSection(context, theme),

                    const SizedBox(height: 35),

                    Text(
                      "Subject Analytics • $selectedGrade",

                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 15),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('progress')
                          .snapshots(),

                      builder: (context, progressSnapshot) {
                        if (!progressSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final progressDocs = progressSnapshot.data!.docs;

                        final Map<String, Map<String, dynamic>>
                        progressBySubject = {};

                        for (final doc in progressDocs) {
                          final data = doc.data() as Map<String, dynamic>;

                          final subject = (data['subject'] ?? '').toString();

                          if (subject.trim().isEmpty) continue;

                          progressBySubject[_normalizeSubject(subject)] = data;
                        }

                        final List<String> subjectsToShow = [...gradeSubjects];

                        for (final key in progressBySubject.keys) {
                          final alreadyExists = subjectsToShow.any(
                            (s) => _normalizeSubject(s) == key,
                          );

                          if (!alreadyExists) {
                            final value = progressBySubject[key]?['subject'];

                            if (value is String && value.trim().isNotEmpty) {
                              subjectsToShow.add(value);
                            }
                          }
                        }

                        return ListView.builder(
                          shrinkWrap: true,

                          physics: const NeverScrollableScrollPhysics(),

                          itemCount: subjectsToShow.length,

                          itemBuilder: (context, index) {
                            final subject = subjectsToShow[index];

                            final data =
                                progressBySubject[_normalizeSubject(subject)] ??
                                {};

                            final quizScore =
                                (data['quizScore'] as num?)?.toInt() ?? 0;

                            final quizAttemptsCount =
                                (data['quizAttemptsCount'] as num?)?.toInt() ??
                                0;

                            final overall = _quizProgressFromMarks(
                              quizScore,

                              (data['lastQuizPercentage'] as num?)?.toDouble(),
                            );

                            return _buildProgressCard(
                              context,
                              theme,
                              subject,
                              quizAttemptsCount,
                              overall,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 35),

                    _buildClassmatesSection(context, selectedGrade, user?.uid),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTeacherConnectSection(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Academic Help",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Struggling with a lesson? Ask our expert teachers and get instant support.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const StudentTeacherChatsListScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "CONNECT WITH TEACHER",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, ThemeData theme, String subject, int quizAttempts, double overall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                subject,

                style: const TextStyle(
                  fontWeight: FontWeight.w900,

                  fontSize: 17,
                ),
              ),

              Text(
                "${(overall * 100).toInt()}%",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: overall,

              minHeight: 8,

              backgroundColor: theme.dividerColor.withOpacity(0.1),
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
                _buildStatItem(
                  context,
                  theme,
                  "Quiz Marks",
                  "${(overall * 100).toInt()}%",
                  Icons.bar_chart_rounded,
                ),

                _buildStatItem(
                  context,
                  theme,
                  "Quizzes Done",
                  "$quizAttempts",
                  Icons.quiz_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassmatesSection(BuildContext context, String grade, String? currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Classroom Leaderboard",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  "See how you compare with $grade peers",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            Icon(Icons.emoji_events_rounded, color: Colors.amber[700], size: 28),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Student')
              .where('studentData.selectedGrade', isEqualTo: grade)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            
            // Client-side sorting as composite index might be missing
            final List<Map<String, dynamic>> students = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['uid'] = doc.id;
              return data;
            }).toList();

            students.sort((a, b) {
              final aPts = (a['studentData']?['points'] as num?)?.toInt() ?? 0;
              final bPts = (b['studentData']?['points'] as num?)?.toInt() ?? 0;
              return bPts.compareTo(aPts);
            });

            if (students.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No classmates found yet.")),
              );
            }

            return SizedBox(
              height: 145,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final bool isMe = student['uid'] == currentUserId;
                  final String name = student['firstName'] ?? "Student";
                  final int pts = (student['studentData']?['points'] as num?)?.toInt() ?? 0;

                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF5C71D1).withOpacity(0.08) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isMe ? const Color(0xFF5C71D1).withOpacity(0.3) : Theme.of(context).dividerColor.withOpacity(0.05),
                        width: isMe ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: isMe ? const Color(0xFF5C71D1) : Colors.grey[200],
                              child: Text(
                                name.isNotEmpty ? name[0] : "S",
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            if (index < 3)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: index == 0 ? Colors.amber : (index == 1 ? Colors.grey[300] : Colors.orange[300]),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isMe ? "You" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isMe ? const Color(0xFF5C71D1) : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars_rounded, size: 12, color: Colors.orange[400]),
                            const SizedBox(width: 4),
                            Text(
                              "$pts",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, ThemeData theme, String label, String val, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(7),

          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        Text(
          val,

          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
