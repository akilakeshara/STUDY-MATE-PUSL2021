import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentQuizListScreen extends StatefulWidget {
  final String selectedGrade;
  final String studentName;

  const StudentQuizListScreen({
    super.key,
    required this.selectedGrade,
    required this.studentName,
  });

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  String _selectedSubject = 'All';

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _groupBySubject(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    grouped = {};

    for (final doc in docs) {
      final data = doc.data();
      final String subject = (data['subject'] ?? 'General').toString().trim();
      final String key = subject.isEmpty ? 'General' : subject;
      grouped.putIfAbsent(key, () => []).add(doc);
    }

    return grouped;
  }

  List<String> _sortedSubjects(
    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped,
  ) {
    final subjects = grouped.keys.toList();
    subjects.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return subjects;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortByAttemptStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> quizzes,
    Set<String> attemptedQuizIds,
  ) {
    final sorted = [...quizzes];
    sorted.sort((a, b) {
      final aAttempted = attemptedQuizIds.contains(a.id);
      final bAttempted = attemptedQuizIds.contains(b.id);

      if (aAttempted != bAttempted) {
        return aAttempted ? 1 : -1;
      }

      final aTitle = (a.data()['title'] ?? '').toString().toLowerCase();
      final bTitle = (b.data()['title'] ?? '').toString().toLowerCase();
      return aTitle.compareTo(bTitle);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('quizzes')
        .where('status', isEqualTo: 'active');

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Available Quizzes',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No quizzes available right now.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          final grouped = _groupBySubject(docs);
          final subjects = _sortedSubjects(grouped);
          final chipItems = ['All', ...subjects];
          final effectiveSelected = subjects.contains(_selectedSubject)
              ? _selectedSubject
              : 'All';
          final visibleSubjects = effectiveSelected == 'All'
              ? subjects
              : [effectiveSelected];

          if (currentUser == null) {
            return const Center(
              child: Text(
                'Please login again to load your quiz status.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('quiz_attempts')
                .where('studentId', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, attemptsSnapshot) {
              final Set<String> attemptedQuizIds =
                  attemptsSnapshot.data?.docs
                      .map((doc) => (doc.data()['quizId'] ?? '').toString())
                      .where((id) => id.isNotEmpty)
                      .toSet() ??
                  <String>{};

              return Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: chipItems.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final subject = chipItems[index];
                        final isSelected = subject == effectiveSelected;

                        return ChoiceChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedSubject = subject),
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.cardColor,
                          side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: visibleSubjects.length,
                      itemBuilder: (context, subjectIndex) {
                        final subject = visibleSubjects[subjectIndex];
                        final subjectQuizzes = _sortByAttemptStatus(
                          grouped[subject] ?? const [],
                          attemptedQuizIds,
                        );

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: subjectIndex == visibleSubjects.length - 1
                                ? 0
                                : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...subjectQuizzes.map((doc) {
                                final data = doc.data();
                                final quizId = doc.id;
                                final isAttempted = attemptedQuizIds.contains(quizId);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Opacity(
                                    opacity: isAttempted ? 0.8 : 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isAttempted
                                            ? theme.cardColor.withOpacity(0.6)
                                            : theme.cardColor,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: theme.dividerColor.withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.07),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        title: Text(
                                          (data['title'] ?? 'Quiz').toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${data['lessonName'] ?? 'Lesson'} • ${data['questionCount'] ?? 0} Questions',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isAttempted ? 'Attempted' : 'Not Attempted',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isAttempted ? Colors.grey : const Color(0xFF2EBD85),
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: isAttempted
                                            ? const Icon(
                                                Icons.check_circle_rounded,
                                                size: 20,
                                                color: Color(0xFF2EBD85),
                                              )
                                            : Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 16,
                                                color: theme.colorScheme.primary,
                                              ),
                                        onTap: isAttempted
                                            ? () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('You have already completed this quiz!'),
                                                    backgroundColor: Color(0xFF2EBD85),
                                                  ),
                                                );
                                              }
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => StudentQuizAttemptScreen(
                                                      quizId: quizId,
                                                      quizTitle: (data['title'] ?? 'Quiz').toString(),
                                                      quizSubject: (data['subject'] ?? 'General').toString(),
                                                      studentName: widget.studentName,
                                                    ),
                                                  ),
                                                );
                                              },
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
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

class StudentQuizAttemptScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final String quizSubject;
  final String studentName;

  const StudentQuizAttemptScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.quizSubject,
    required this.studentName,
  });

  @override
  State<StudentQuizAttemptScreen> createState() =>
      _StudentQuizAttemptScreenState();
}

class _StudentQuizAttemptScreenState extends State<StudentQuizAttemptScreen> {
  final Map<String, String> _answers = {};
  bool _submitting = false;
  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _questionsFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showAttemptSummaryPopup({
    required int correctCount,
    required int totalQuestions,
    required List<_QuizReviewItem> reviewItems,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Summary'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Correct Answers: $correctCount / $totalQuestions',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Right answers',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(reviewItems.length, (index) {
                    final item = reviewItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Q${index + 1}: ${item.correctOption}. ${item.correctAnswerText}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPointsFromMarks({
    required String studentId,
    required int obtainedMarks,
  }) async {
    if (obtainedMarks <= 0) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(studentId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final dynamic studentDataRaw = data['studentData'];
      final Map<String, dynamic> studentData =
          studentDataRaw is Map<String, dynamic>
          ? studentDataRaw
          : <String, dynamic>{};

      final int currentPoints = (studentData['points'] as num?)?.toInt() ?? 0;
      final int previousTotalMarks =
          (studentData['totalQuizMarks'] as num?)?.toInt() ?? 0;
      final int previousPointsFromMarks =
          (studentData['pointsFromQuizMarks'] as num?)?.toInt() ??
          (previousTotalMarks ~/ 10);

      final int newTotalMarks = previousTotalMarks + obtainedMarks;
      final int recalculatedPointsFromMarks = newTotalMarks ~/ 10;
      final int pointsToAdd =
          recalculatedPointsFromMarks - previousPointsFromMarks;

      transaction.set(userRef, {
        'studentData': {
          'totalQuizMarks': newTotalMarks,
          'pointsFromQuizMarks': recalculatedPointsFromMarks,
          'lastQuizMarks': obtainedMarks,
          if (pointsToAdd > 0) 'points': currentPoints + pointsToAdd,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String _subjectDocId(String subject) {
    final id = subject.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return id.isEmpty ? 'general' : id;
  }

  Future<void> _updateProgressFromQuiz({
    required String studentId,
    required double percentage,
  }) async {
    final String subject = widget.quizSubject.trim().isEmpty
        ? 'General'
        : widget.quizSubject.trim();

    final progressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .collection('progress')
        .doc(_subjectDocId(subject));

    final current = await progressRef.get();
    final data = current.data() ?? <String, dynamic>{};

    final int oldAttempts = (data['quizAttemptsCount'] as num?)?.toInt() ?? 0;
    final double oldTotal =
        (data['quizPercentageTotal'] as num?)?.toDouble() ?? 0;
    final int examScore = (data['examScore'] as num?)?.toInt() ?? 0;

    final int newAttempts = oldAttempts + 1;
    final double newTotal = oldTotal + percentage;
    final double avgPercentage = newAttempts == 0
        ? 0
        : (newTotal / newAttempts);

    final int quizScore = ((avgPercentage / 100) * 10).clamp(0, 10).round();
    final double overall = ((quizScore / 10) + (examScore / 100)) / 2;

    await progressRef.set({
      'subject': subject,
      'quizScore': quizScore,
      'examScore': examScore,
      'overall': overall,
      'quizAttemptsCount': newAttempts,
      'quizPercentageTotal': newTotal,
      'lastQuizPercentage': percentage,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadQuestions() async {
    final query = await FirebaseFirestore.instance
        .collection('quiz_questions')
        .where('quizId', isEqualTo: widget.quizId)
        .get();

    final docs = query.docs;
    docs.sort((a, b) {
      final aNo = (a.data()['questionNumber'] ?? 0) as int;
      final bNo = (b.data()['questionNumber'] ?? 0) as int;
      return aNo.compareTo(bNo);
    });

    return docs;
  }

  Future<void> _submitAttempt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> questions,
  ) async {
    if (_submitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_answers.length != questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submit.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      int score = 0;
      int correctCount = 0;
      int wrongCount = 0;
      final List<_QuizReviewItem> reviewItems = [];
      final List<Map<String, dynamic>> evaluatedAnswers = [];
      for (final q in questions) {
        final data = q.data();
        final String questionId = q.id;
        final selected = (_answers[q.id] ?? '').toString();
        final correct = (data['correctOption'] ?? '').toString();
        final options = Map<String, dynamic>.from(
          data['options'] as Map<String, dynamic>? ?? {},
        );
        final questionText = (data['question'] ?? '').toString();

        final String selectedText = selected.isEmpty
            ? 'Not answered'
            : (options[selected] ?? '').toString();
        final String correctText = (options[correct] ?? '').toString();

        final bool isCorrect = selected == correct;

        if (isCorrect) {
          score++;
          correctCount++;
        } else {
          wrongCount++;
        }

        evaluatedAnswers.add({
          'questionId': questionId,
          'question': questionText,
          'selectedOption': selected,
          'selectedAnswerText': selectedText,
          'correctOption': correct,
          'correctAnswerText': correctText,
          'isCorrect': isCorrect,
          'awardedMarks': isCorrect ? 1 : 0,
          'maxMarks': 1,
        });

        reviewItems.add(
          _QuizReviewItem(
            questionText: questionText,
            selectedOption: selected,
            selectedAnswerText: selectedText,
            correctOption: correct,
            correctAnswerText: correctText,
            isCorrect: isCorrect,
          ),
        );
      }

      final int totalMarks = questions.length;
      final int obtainedMarks = score;
      final int earnedPoints = obtainedMarks ~/ 10;
      final double percentage = questions.isEmpty
          ? 0
          : (score / questions.length) * 100;
      final DateTime now = DateTime.now();

      final attemptRef = FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc();
      await attemptRef.set({
        'attemptId': attemptRef.id,
        'quizId': widget.quizId,
        'quizTitle': widget.quizTitle,
        'subject': widget.quizSubject,
        'studentId': user.uid,
        'studentName': widget.studentName,
        'totalQuestions': questions.length,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'score': score,
        'obtainedMarks': obtainedMarks,
        'totalMarks': totalMarks,
        'earnedPoints': earnedPoints,
        'percentage': percentage,
        'answers': _answers,
        'evaluatedAnswers': evaluatedAnswers,
        'gradingVersion': 1,
        'submittedAtClient': Timestamp.fromDate(now),
        'attemptedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quiz_results')
          .doc(widget.quizId)
          .set({
            'quizId': widget.quizId,
            'latestAttemptId': attemptRef.id,
            'quizTitle': widget.quizTitle,
            'subject': widget.quizSubject,
            'studentId': user.uid,
            'studentName': widget.studentName,
            'attemptCount': FieldValue.increment(1),
            'latestScore': score,
            'latestObtainedMarks': obtainedMarks,
            'latestTotalMarks': totalMarks,
            'latestEarnedPoints': earnedPoints,
            'latestPercentage': percentage,
            'latestCorrectCount': correctCount,
            'latestWrongCount': wrongCount,
            'latestAttemptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await _updateProgressFromQuiz(
        studentId: user.uid,
        percentage: percentage,
      );

      await _addPointsFromMarks(
        studentId: user.uid,
        obtainedMarks: obtainedMarks,
      );

      if (!mounted) return;
      await _showAttemptSummaryPopup(
        correctCount: correctCount,
        totalQuestions: questions.length,
        reviewItems: reviewItems,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentQuizResultScreen(
            quizTitle: widget.quizTitle,
            score: score,
            totalQuestions: questions.length,
            reviewItems: reviewItems,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit attempt: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.quizTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No questions found for this quiz.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final questions = snapshot.data!;

          return Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentPage + 1} of ${questions.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${((_currentPage + 1) / questions.length * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / questions.length,
                        backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swiping to force button use
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final doc = questions[index];
                    final data = doc.data();
                    final questionText = (data['question'] ?? '').toString();
                    final options = Map<String, dynamic>.from(
                      data['options'] as Map<String, dynamic>? ?? {},
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              questionText,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 25),
                            ...['A', 'B', 'C', 'D'].map((key) {
                              final optionText = (options[key] ?? '').toString();
                              if (optionText.isEmpty) return const SizedBox.shrink();
                              
                              final isSelected = _answers[doc.id] == key;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _answers[doc.id] = key);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                          : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected 
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).dividerColor.withOpacity(0.1),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isSelected 
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).dividerColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              key,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            optionText,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected 
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.onSurface,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Navigation Buttons
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              'PREVIOUS',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5C71D1),
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _submitting 
                              ? null 
                              : (_currentPage < questions.length - 1 
                                  ? () {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : () => _submitAttempt(questions)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            _submitting 
                                ? 'SUBMITTING...' 
                                : (_currentPage < questions.length - 1 ? 'NEXT QUESTION' : 'SUBMIT ATTEMPT'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StudentQuizResultScreen extends StatelessWidget {
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final List<_QuizReviewItem> reviewItems;

  const StudentQuizResultScreen({
    super.key,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.reviewItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double percentage = totalQuestions == 0
        ? 0
        : (score / totalQuestions) * 100;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quiz Result',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quizTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: $score / $totalQuestions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5C71D1),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Percentage: ${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: reviewItems.length,
              itemBuilder: (context, index) {
                final item = reviewItems[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q${index + 1}. ${item.questionText}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Answer: ${item.selectedOption.isEmpty ? 'Not answered' : item.selectedOption} - ${item.selectedAnswerText}',
                        style: TextStyle(
                          color: item.isCorrect
                              ? const Color(0xFF2EBD85)
                              : Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Correct Answer: ${item.correctOption} - ${item.correctAnswerText}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BACK TO QUIZZES',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizReviewItem {
  final String questionText;
  final String selectedOption;
  final String selectedAnswerText;
  final String correctOption;
  final String correctAnswerText;
  final bool isCorrect;

  const _QuizReviewItem({
    required this.questionText,
    required this.selectedOption,
    required this.selectedAnswerText,
    required this.correctOption,
    required this.correctAnswerText,
    required this.isCorrect,
  });
}
