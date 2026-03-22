import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sponsor_chat_with_admin_screen.dart';
import 'sponsor_profile_screen.dart';
import 'study_mate_funding_screen.dart';

class SponsorDashboard extends StatefulWidget {
  const SponsorDashboard({super.key});

  @override
  State<SponsorDashboard> createState() => _SponsorDashboardState();
}

class _SponsorDashboardState extends State<SponsorDashboard> {
  int _currentIndex = 0;
  String _pointsFilter = 'all';

  Future<bool> _onWillPop(BuildContext context) async {
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  String _todayLabel() => DateFormat('dd/MM/yyyy').format(DateTime.now());

  void _openAdminChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SponsorChatWithAdminScreen(),
      ),
    );
  }

  void _openFundingGateway() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudyMateFundingScreen()),
    );
  }

  void _contactStudent(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening contact options for $name'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _callStudent(String phone) async {
    final String cleaned = phone.trim();
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'n/a') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: cleaned);
    final bool launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open phone dialer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _emailStudent(String email) async {
    final String cleaned = email.trim();
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'n/a') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Uri uri = Uri(scheme: 'mailto', path: cleaned);
    final bool launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open email app.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitSponsorshipRequest(Map<String, dynamic> student) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String studentUid = (student['uid'] ?? '').toString();
    if (studentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student info is invalid.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final String studentName = (student['name'] ?? 'Student').toString();
    final String docId = '${currentUser.uid}_$studentUid';
    final DocumentReference lockRef = FirebaseFirestore.instance
        .collection('sponsorship_student_locks')
        .doc(studentUid);

    final DocumentSnapshot lockSnapshot = await lockRef.get();
    if (lockSnapshot.exists) {
      final dynamic raw = lockSnapshot.data();
      final Map<String, dynamic> lockData = raw is Map<String, dynamic>
          ? raw
          : <String, dynamic>{};
      final String lockedSponsorUid = (lockData['sponsorUid'] ?? '')
          .toString()
          .trim();

      if (lockedSponsorUid.isNotEmpty && lockedSponsorUid != currentUser.uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This student is already assigned to another sponsor.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final DocumentReference requestRef = FirebaseFirestore.instance
        .collection('sponsorship_requests')
        .doc(docId);

    final requestSnapshot = await requestRef.get();
    final bool existed = requestSnapshot.exists;

    await requestRef.set({
      'sponsorUid': currentUser.uid,
      'studentUid': studentUid,
      'studentName': studentName,
      'studentGrade': (student['grade'] ?? 'N/A').toString(),
      'studentPoints': int.tryParse((student['points'] ?? '0').toString()) ?? 0,
      'status': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existed) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('admin_notifications').add({
      'type': 'sponsorship_request',
      'title': 'New Sponsorship Request',
      'message': '$studentName request needs admin review.',
      'sponsorUid': currentUser.uid,
      'studentUid': studentUid,
      'requestId': docId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existed
              ? '$studentName request resubmitted for admin approval.'
              : '$studentName request sent for admin approval.',
        ),
        backgroundColor: const Color(0xFF5C71D1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _mapEligibleStudents(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> students = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dynamic studentDataRaw = data['studentData'];
      final Map<String, dynamic>? studentData =
          studentDataRaw is Map<String, dynamic> ? studentDataRaw : null;

      final String role = (data['role'] ?? '').toString().trim().toLowerCase();
      if (role != 'student') continue;

      final int points =
          (studentData?['points'] as num?)?.toInt() ??
          (data['points'] as num?)?.toInt() ??
          0;

      final String name =
          ((data['firstName'] ??
                      data['fullName'] ??
                      data['name'] ??
                      studentData?['firstName'] ??
                      studentData?['fullName'] ??
                      'Student')
                  as String)
              .trim();

      final String grade =
          (studentData?['selectedGrade'] ??
                  studentData?['grade'] ??
                  data['selectedGrade'] ??
                  data['grade'] ??
                  'N/A')
              .toString();

      final String email = (data['email'] ?? '').toString().trim();
      final String phone = (data['phone'] ?? studentData?['phone'] ?? '')
          .toString()
          .trim();
      final String studentId =
          (studentData?['studentID'] ?? data['studentID'] ?? '')
              .toString()
              .trim();

      final bool isVerified =
          data['isVerified'] == true ||
          studentData?['isVerified'] == true ||
          (data['status'] ?? '').toString().toLowerCase() == 'approved';

      students.add({
        'uid': doc.id,
        'name': name.isEmpty ? 'Student' : name,
        'points': points.toString(),
        'grade': grade,
        'email': email,
        'phone': phone,
        'studentId': studentId,
        'isVerified': isVerified,
      });
    }

    students.sort((a, b) {
      final int pointsA = int.tryParse(a['points'].toString()) ?? 0;
      final int pointsB = int.tryParse(b['points'].toString()) ?? 0;
      return pointsB.compareTo(pointsA);
    });

    return students;
  }

  List<Map<String, dynamic>> _mapSponsoredStudents(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> students = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      students.add({
        'uid': (data['studentUid'] ?? '').toString(),
        'name': (data['studentName'] ?? 'Student').toString(),
        'points': (data['studentPoints'] ?? data['studentScore'] ?? 0)
            .toString(),
        'grade': (data['studentGrade'] ?? 'N/A').toString(),
        'district': (data['studentDistrict'] ?? 'N/A').toString(),
      });
    }

    students.sort((a, b) {
      final int pointsA = int.tryParse(a['points'].toString()) ?? 0;
      final int pointsB = int.tryParse(b['points'].toString()) ?? 0;
      return pointsB.compareTo(pointsA);
    });

    return students;
  }

  List<Map<String, dynamic>> _attachSponsoredStudentContacts({
    required List<Map<String, dynamic>> sponsoredStudents,
    required QuerySnapshot usersSnapshot,
  }) {
    final Map<String, Map<String, dynamic>> usersById = {
      for (final doc in usersSnapshot.docs)
        doc.id: doc.data() as Map<String, dynamic>,
    };

    return sponsoredStudents.map((student) {
      final String uid = (student['uid'] ?? '').toString();
      final Map<String, dynamic>? userData = usersById[uid];

      final String email = (userData?['email'] ?? 'N/A').toString();
      final String phone =
          (userData?['phone'] ?? userData?['studentData']?['phone'] ?? 'N/A')
              .toString();

      return {...student, 'email': email, 'phone': phone};
    }).toList();
  }

  List<Map<String, dynamic>> _mapSponsorshipRequests(QuerySnapshot snapshot) {
    final List<Map<String, dynamic>> requests = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      requests.add({
        'id': doc.id,
        'studentUid': (data['studentUid'] ?? '').toString(),
        'studentName': (data['studentName'] ?? 'Student').toString(),
        'studentGrade': (data['studentGrade'] ?? 'N/A').toString(),
        'studentDistrict': (data['studentDistrict'] ?? 'N/A').toString(),
        'studentPoints': (data['studentPoints'] ?? 0).toString(),
        'status': (data['status'] ?? 'pending').toString().trim().toLowerCase(),
        'updatedAt': data['updatedAt'],
      });
    }

    requests.sort((a, b) {
      final Timestamp? aTs = a['updatedAt'] as Timestamp?;
      final Timestamp? bTs = b['updatedAt'] as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });

    return requests;
  }

  Map<String, String> _extractSponsorMeta({
    required QuerySnapshot usersSnapshot,
    required String uid,
  }) {
    for (final doc in usersSnapshot.docs) {
      if (doc.id != uid) continue;
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final String name = (data['firstName'] ?? data['fullName'] ?? 'Sponsor')
          .toString();
      final String sponsorId =
          (data['sponsorID'] ?? data['sponsorData']?['sponsorID'] ?? 'SPN-0000')
              .toString();
      return {'name': name, 'sponsorId': sponsorId};
    }

    return {'name': 'Sponsor', 'sponsorId': 'SPN-0000'};
  }

  List<Map<String, dynamic>> _applyPointsFilter(
    List<Map<String, dynamic>> students,
  ) {
    final filtered = List<Map<String, dynamic>>.from(students);
    if (_pointsFilter == 'highest') {
      filtered.sort((a, b) {
        final int pointsA = int.tryParse(a['points'].toString()) ?? 0;
        final int pointsB = int.tryParse(b['points'].toString()) ?? 0;
        return pointsB.compareTo(pointsA);
      });
      return filtered;
    }

    if (_pointsFilter == 'lowest') {
      filtered.sort((a, b) {
        final int pointsA = int.tryParse(a['points'].toString()) ?? 0;
        final int pointsB = int.tryParse(b['points'].toString()) ?? 0;
        return pointsA.compareTo(pointsB);
      });
      return filtered;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildImpactTab(),
      const SponsorProfileScreen(),
    ];

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: pages[_currentIndex],
        bottomNavigationBar: _buildBottomNav(),
        extendBody: true,
      ),
    );
  }

  Widget _buildHomeTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please login again.'));
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sponsorships')
            .where('sponsorUid', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, sponsoredSnapshot) {
          final List<Map<String, dynamic>> sponsoredStudents =
              sponsoredSnapshot.hasData
              ? _mapSponsoredStudents(sponsoredSnapshot.data!)
              : const [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sponsorship_requests')
                .where('sponsorUid', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, requestsSnapshot) {
              final List<Map<String, dynamic>> sponsorshipRequests =
                  requestsSnapshot.hasData
                  ? _mapSponsorshipRequests(requestsSnapshot.data!)
                  : const [];

              final Map<String, String> requestStatusByStudent = {
                for (final request in sponsorshipRequests)
                  (request['studentUid'] ?? '').toString():
                      (request['status'] ?? 'pending').toString(),
              };

              final int approvedCount = sponsorshipRequests.where((request) {
                final status = (request['status'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
                return status == 'approved';
              }).length;

              final int pendingCount = sponsorshipRequests.where((request) {
                final status = (request['status'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
                return status == 'pending';
              }).length;

              final int rejectedCount = sponsorshipRequests.where((request) {
                final status = (request['status'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();
                return status == 'rejected';
              }).length;

              final Set<String> sponsoredStudentIds = sponsoredStudents
                  .map((student) => (student['uid'] ?? '').toString())
                  .where((uid) => uid.isNotEmpty)
                  .toSet();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, eligibleSnapshot) {
                  final List<Map<String, dynamic>> eligibleStudents =
                      eligibleSnapshot.hasData
                      ? _mapEligibleStudents(eligibleSnapshot.data!)
                      : const [];
                  final List<Map<String, dynamic>> filteredEligibleStudents =
                      _applyPointsFilter(eligibleStudents);

                  final Map<String, String> sponsorMeta =
                      eligibleSnapshot.hasData
                      ? _extractSponsorMeta(
                          usersSnapshot: eligibleSnapshot.data!,
                          uid: currentUser.uid,
                        )
                      : {'name': 'Sponsor', 'sponsorId': 'SPN-0000'};

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernHeader(
                          displayName: sponsorMeta['name'] ?? 'Sponsor',
                          sponsorId: sponsorMeta['sponsorId'] ?? 'SPN-0000',
                        ),
                        const SizedBox(height: 22),
                        _buildAdminChatButton(),
                        const SizedBox(height: 12),
                        _buildFundingGatewayCard(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildMiniStat(
                              icon: Icons.person_add_alt_1_rounded,
                              label: 'Students',
                              value: eligibleStudents.length.toString(),
                            ),
                            const SizedBox(width: 10),
                            _buildMiniStat(
                              icon: Icons.verified_rounded,
                              label: 'Approved Students',
                              value: approvedCount.toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildHomeStatusSummary(
                          total: sponsorshipRequests.length,
                          pending: pendingCount,
                          approved: approvedCount,
                          rejected: rejectedCount,
                        ),
                        const SizedBox(height: 12),
                        _buildHomeNextSteps(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required int count}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1C2E),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5C71D1),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: child,
    );
  }

  Widget _buildHomeStatusSummary({
    required int total,
    required int pending,
    required int approved,
    required int rejected,
  }) {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sponsorship Request Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1C2E),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip('Total', total, const Color(0xFF5C71D1)),
              _buildStatusChip('Pending', pending, const Color(0xFFF59E0B)),
              _buildStatusChip('Approved', approved, const Color(0xFF16A34A)),
              _buildStatusChip('Rejected', rejected, const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHomeNextSteps() {
    return _buildSectionContainer(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Overview',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1C2E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Review students from the Students tab and send sponsorship requests.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use Chat with Admin when requests stay pending for longer.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use Fund Study Mate to submit and track your platform support.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsFilterBar() {
    return Row(
      children: [
        _buildFilterChip(label: 'All', value: 'all'),
        const SizedBox(width: 8),
        _buildFilterChip(label: 'Highest Points', value: 'highest'),
        const SizedBox(width: 8),
        _buildFilterChip(label: 'Lowest Points', value: 'lowest'),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final bool isSelected = _pointsFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _pointsFilter = value),
      selectedColor: const Color(0xFF5C71D1).withOpacity(0.15),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF5C71D1) : const Color(0xFFE9EEFF),
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5C71D1) : const Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInlineEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImpactTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please login again.'));
    }

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sponsorships')
            .where('sponsorUid', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, sponsoredSnapshot) {
          final List<Map<String, dynamic>> sponsoredStudents =
              sponsoredSnapshot.hasData
              ? _mapSponsoredStudents(sponsoredSnapshot.data!)
              : const [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sponsorship_requests')
                .where('sponsorUid', isEqualTo: currentUser.uid)
                .snapshots(),
            builder: (context, requestsSnapshot) {
              final List<Map<String, dynamic>> sponsorshipRequests =
                  requestsSnapshot.hasData
                  ? _mapSponsorshipRequests(requestsSnapshot.data!)
                  : const [];

              final Map<String, String> requestStatusByStudent = {
                for (final request in sponsorshipRequests)
                  (request['studentUid'] ?? '').toString():
                      (request['status'] ?? 'pending').toString(),
              };

              final Set<String> sponsoredStudentIds = sponsoredStudents
                  .map((student) => (student['uid'] ?? '').toString())
                  .where((uid) => uid.isNotEmpty)
                  .toSet();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sponsorship_requests')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, approvedSnapshot) {
                  final Set<String> globallyApprovedStudentIds =
                      approvedSnapshot.hasData
                      ? approvedSnapshot.data!.docs
                            .map((doc) {
                              final dynamic data = doc.data();
                              if (data is! Map<String, dynamic>) {
                                return '';
                              }
                              return (data['studentUid'] ?? '').toString();
                            })
                            .where((studentUid) => studentUid.isNotEmpty)
                            .toSet()
                      : const <String>{};

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, eligibleSnapshot) {
                      final List<Map<String, dynamic>> eligibleStudents =
                          eligibleSnapshot.hasData
                          ? _mapEligibleStudents(eligibleSnapshot.data!)
                          : const [];
                      final List<Map<String, dynamic>>
                      filteredEligibleStudents = _applyPointsFilter(
                        eligibleStudents,
                      );

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImpactHeader(),
                            const SizedBox(height: 20),
                            _buildSectionTitle(
                              'Registered Students',
                              count: eligibleStudents.length,
                            ),
                            const SizedBox(height: 8),
                            _buildPointsFilterBar(),
                            const SizedBox(height: 10),
                            _buildSectionContainer(
                              child:
                                  eligibleSnapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 22,
                                        ),
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF5C71D1),
                                        ),
                                      ),
                                    )
                                  : filteredEligibleStudents.isEmpty
                                  ? _buildInlineEmpty(
                                      'No registered students found.',
                                    )
                                  : Column(
                                      children: filteredEligibleStudents.map((
                                        student,
                                      ) {
                                        final String studentUid =
                                            (student['uid'] ?? '').toString();
                                        final String statusForCurrentSponsor =
                                            (requestStatusByStudent[studentUid] ??
                                                    '')
                                                .toString()
                                                .toLowerCase();
                                        final bool isAlreadySponsoredByCurrent =
                                            sponsoredStudentIds.contains(
                                              studentUid,
                                            );
                                        final bool isSupportedByAnotherSponsor =
                                            globallyApprovedStudentIds.contains(
                                              studentUid,
                                            ) &&
                                            !isAlreadySponsoredByCurrent &&
                                            statusForCurrentSponsor !=
                                                'approved';

                                        return _buildStudentCard(
                                          uid: studentUid,
                                          name: student['name'] as String,
                                          points: student['points'] as String,
                                          grade: student['grade'] as String,
                                          email: (student['email'] ?? 'N/A')
                                              .toString(),
                                          phone: (student['phone'] ?? 'N/A')
                                              .toString(),
                                          studentId:
                                              (student['studentId'] ?? 'N/A')
                                                  .toString(),
                                          isVerified:
                                              student['isVerified'] as bool,
                                          isAlreadySponsored:
                                              isAlreadySponsoredByCurrent,
                                          isSupportedByAnotherSponsor:
                                              isSupportedByAnotherSponsor,
                                          requestStatus:
                                              requestStatusByStudent[studentUid],
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login again.'));
    }

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }

          final Map<String, dynamic>? data =
              snapshot.data?.data() as Map<String, dynamic>?;

          final String name =
              (data?['firstName'] ?? data?['fullName'] ?? 'Sponsor').toString();
          final String email = (data?['email'] ?? 'N/A').toString();
          final String phone = (data?['phone'] ?? 'N/A').toString();
          final String orgType = (data?['organizationType'] ?? 'N/A')
              .toString();
          final String sponsorID =
              (data?['sponsorID'] ??
                      data?['sponsorData']?['sponsorID'] ??
                      'SPN-0000')
                  .toString();
          final String linkedin = (data?['linkedin'] ?? 'N/A').toString();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE9EEFF)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(
                          0xFF5C71D1,
                        ).withOpacity(0.12),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: Color(0xFF5C71D1),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1D26),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildProfileTile(Icons.badge_rounded, 'Sponsor ID', sponsorID),
                _buildProfileTile(Icons.phone_rounded, 'Phone', phone),
                _buildProfileTile(
                  Icons.business_rounded,
                  'Organization Type',
                  orgType,
                ),
                _buildProfileTile(Icons.link_rounded, 'LinkedIn', linkedin),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/welcome',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3448),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'LOGOUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader({
    required String displayName,
    required String sponsorId,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1D26),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _buildHeaderBadge('ID: $sponsorId'),
                const SizedBox(height: 9),
                Text(
                  'Verified students directory • ${_todayLabel()}',
                  style: const TextStyle(
                    color: Color(0xFF616A89),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF5C71D1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Color(0xFF5C71D1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5C71D1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights_rounded, color: Color(0xFF5C71D1)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Directory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Browse and manage registered students',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5C71D1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5C71D1),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAdminChatButton() {
    return InkWell(
      onTap: _openAdminChat,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EEFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5C71D1).withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF5C71D1),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat with Admin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1C2E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Need support with sponsorship?',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundingGatewayCard() {
    return InkWell(
      onTap: _openFundingGateway,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C71D1).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.payments_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fund Study Mate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Open payment gateway and support the platform',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9EEFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF5C71D1).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF5C71D1)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1C2E),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard({
    required String uid,
    required String name,
    required String points,
    required String grade,
    required String email,
    required String phone,
    required String studentId,
    required bool isVerified,
    required bool isAlreadySponsored,
    required bool isSupportedByAnotherSponsor,
    required String? requestStatus,
  }) {
    final String normalizedStatus = (requestStatus ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final bool isPending = normalizedStatus == 'pending';
    final bool canViewProfile =
        isAlreadySponsored || normalizedStatus == 'approved';
    final bool canRequest =
        !isAlreadySponsored && !isPending && !isSupportedByAnotherSponsor;
    final String actionLabel = isAlreadySponsored
        ? 'Sponsored'
        : isSupportedByAnotherSponsor
        ? 'Assigned'
        : isPending
        ? 'Pending'
        : normalizedStatus == 'rejected'
        ? 'Re-request'
        : 'Request';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1C2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(0xFF22C55E),
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Grade: $grade',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'ID: ${studentId.isEmpty ? 'N/A' : studentId}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                if (isVerified)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFF5C71D1),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Admin Verified Record',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5C71D1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (normalizedStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildRequestStatusChip(normalizedStatus),
                  ),
                if (isSupportedByAnotherSponsor)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Admin approved sponsor already supporting',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3448),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      points,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Points',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: canRequest
                    ? () => _submitSponsorshipRequest({
                        'uid': uid,
                        'name': name,
                        'points': points,
                        'grade': grade,
                      })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAlreadySponsored
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF5C71D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(84, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              if (canViewProfile) ...[
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => _showApprovedStudentProfile(
                    name: name,
                    studentId: studentId,
                    grade: grade,
                    points: points,
                    email: email,
                    phone: phone,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(84, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: Color(0xFF5C71D1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Color(0xFF5C71D1),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showApprovedStudentProfile({
    required String name,
    required String studentId,
    required String grade,
    required String points,
    required String email,
    required String phone,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.45,
        maxChildSize: 0.88,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1C2E),
                ),
              ),
              const SizedBox(height: 14),
              _buildProfileInfoRow(
                'Student ID',
                studentId.isEmpty ? 'N/A' : studentId,
              ),
              _buildProfileInfoRow('Email', email.isEmpty ? 'N/A' : email),
              _buildProfileInfoRow('Contact', phone.isEmpty ? 'N/A' : phone),
              _buildProfileInfoRow('Grade', grade),
              _buildProfileInfoRow('Points', points),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callStudent(phone),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call Student'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFFBBF7D0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _emailStudent(email),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Email Student'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5C71D1),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1C2E),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusChip(String status) {
    final bool isRejected = status == 'rejected';
    final bool isApproved = status == 'approved';
    final Color bg = isRejected
        ? const Color(0xFFFEE2E2)
        : isApproved
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFE0E7FF);
    final Color fg = isRejected
        ? const Color(0xFFDC2626)
        : isApproved
        ? const Color(0xFF15803D)
        : const Color(0xFF3730A3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Request: ${status[0].toUpperCase()}${status.substring(1)}',
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildPendingRequestCard({
    required String name,
    required String points,
    required String grade,
    required String district,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFF5C71D1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1C2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grade: $grade • District: $district',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$points pts',
              style: const TextStyle(
                color: Color(0xFF3730A3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredStudentCard({
    required String name,
    required String points,
    required String grade,
    required String district,
    required String email,
    required String phone,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF22C55E),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1C2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grade: $grade • District: $district',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Contact: $phone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _callStudent(phone),
                        icon: const Icon(Icons.call_rounded, size: 14),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16A34A),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _emailStudent(email),
                        icon: const Icon(Icons.email_outlined, size: 14),
                        label: const Text('Email'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5C71D1),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3448),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              points,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStatCard(String value, String label, bool dark) {
    final Color bg = dark ? const Color(0xFF2D3448) : Colors.white;
    final Color fg = dark ? Colors.white : const Color(0xFF1A1D26);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: dark ? null : Border.all(color: const Color(0xFFE9EEFF)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: fg.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5C71D1), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1D26),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.school_outlined, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 10),
          Text(
            'No eligible students yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Registered students from database will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
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
          _buildNavItem(Icons.home_rounded, 'Home', 0),
          _buildNavItem(Icons.groups_rounded, 'Students', 1),
          _buildNavItem(Icons.person_rounded, 'Me', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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
              color: isActive ? const Color(0xFF5C71D1) : Colors.blueGrey[200],
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
}
