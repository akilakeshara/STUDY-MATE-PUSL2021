import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminCommunityScreen extends StatelessWidget {
  const AdminCommunityScreen({super.key});

  bool _roleMatches(dynamic roleValue, String expectedRole) {
    return roleValue.toString().trim().toLowerCase() ==
        expectedRole.toLowerCase();
  }

  String _resolveUserName(Map<String, dynamic> data) {
    final String fullName = (data['fullName'] ?? data['name'] ?? '')
        .toString()
        .trim();
    if (fullName.isNotEmpty) return fullName;

    final String firstName = (data['firstName'] ?? '').toString().trim();
    final String lastName = (data['lastName'] ?? '').toString().trim();
    final String combinedName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    if (combinedName.isNotEmpty) return combinedName;

    final Map<String, dynamic>? studentData =
        data['studentData'] is Map<String, dynamic>
        ? data['studentData'] as Map<String, dynamic>
        : null;
    if (studentData != null) {
      final String nestedFirst = (studentData['firstName'] ?? '')
          .toString()
          .trim();
      final String nestedLast = (studentData['lastName'] ?? '')
          .toString()
          .trim();
      final String nestedCombined = [
        nestedFirst,
        nestedLast,
      ].where((part) => part.isNotEmpty).join(' ').trim();
      if (nestedCombined.isNotEmpty) return nestedCombined;
    }

    final String email = (data['email'] ?? '').toString().trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Unnamed User';
  }

  String _formatExpertise(dynamic value) {
    if (value == null) return "N/A";
    if (value is List) {
      if (value.isEmpty) return "N/A";
      return value.join(', ');
    }
    return value.toString();
  }

  String _resolveGrade(
    Map<String, dynamic> data,
    Map<String, dynamic>? studentData,
    Map<String, dynamic>? teacherData,
  ) {
    final String rootGrade = (data['grade'] ?? data['selectedGrade'] ?? '')
        .toString()
        .trim();
    if (rootGrade.isNotEmpty) return rootGrade;

    if (studentData != null) {
      final String studentGrade =
          (studentData['selectedGrade'] ?? studentData['grade'] ?? '')
              .toString()
              .trim();
      if (studentGrade.isNotEmpty) return studentGrade;
    }

    if (teacherData != null) {
      final String teacherGrade = (teacherData['teachingGrade'] ?? '')
          .toString()
          .trim();
      if (teacherGrade.isNotEmpty) return teacherGrade;
    }

    return 'N/A';
  }

  String _resolvePoints(
    Map<String, dynamic> data,
    Map<String, dynamic>? studentData,
  ) {
    final dynamic rootPoints = data['points'];
    if (rootPoints != null) return rootPoints.toString();

    final dynamic studentPoints = studentData?['points'];
    if (studentPoints != null) return studentPoints.toString();

    return '0';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneActionRow(
    BuildContext context, {
    required String phone,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phone',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Call',
                onPressed: () => _makePhoneCall(context, phone),
                icon: Icon(Icons.call_rounded, color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final String cleaned = phone.trim();
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'not available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available.')),
      );
      return;
    }

    final Uri uri = Uri(scheme: 'tel', path: cleaned);
    final bool launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open phone dialer.')),
      );
    }
  }

  String _resolveRoleId(
    String role,
    String userDocId,
    Map<String, dynamic> data,
    Map<String, dynamic>? studentData,
    Map<String, dynamic>? teacherData,
    String? sponsorIdFallback,
  ) {
    if (_roleMatches(role, 'Student')) {
      final String studentId =
          (studentData?['studentID'] ?? data['studentID'] ?? '')
              .toString()
              .trim();
      return studentId.isNotEmpty ? studentId : userDocId;
    }

    if (_roleMatches(role, 'Teacher')) {
      final String teacherId =
          (teacherData?['teacherID'] ?? data['teacherID'] ?? '')
              .toString()
              .trim();
      return teacherId.isNotEmpty ? teacherId : userDocId;
    }

    if (_roleMatches(role, 'Sponsor')) {
      final Map<String, dynamic>? sponsorData =
          data['sponsorData'] is Map<String, dynamic>
          ? data['sponsorData'] as Map<String, dynamic>
          : null;
      final String sponsorId =
          (data['sponsorID'] ??
                  data['sponsorId'] ??
                  sponsorData?['sponsorID'] ??
                  sponsorData?['sponsorId'] ??
                  sponsorIdFallback ??
                  '')
              .toString()
              .trim();
      return sponsorId.isNotEmpty ? sponsorId : 'SPN-UNASSIGNED';
    }

    return userDocId;
  }

  String _normalizeLookupKey(String value) => value.trim().toLowerCase();

  Map<String, String> _buildSponsorIdLookup(List<QueryDocumentSnapshot> docs) {
    final Map<String, String> idByLookup = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String sponsorId = (data['sponsorID'] ?? data['sponsorId'] ?? '')
          .toString()
          .trim();
      if (sponsorId.isEmpty) continue;

      final String uid = (data['uid'] ?? '').toString().trim();
      if (uid.isNotEmpty) {
        idByLookup[_normalizeLookupKey(uid)] = sponsorId;
      }

      final String email = (data['email'] ?? '').toString().trim();
      if (email.isNotEmpty) {
        idByLookup[_normalizeLookupKey(email)] = sponsorId;
      }
    }

    return idByLookup;
  }

  String? _lookupSponsorIdFromApplicationMap({
    required String userDocId,
    required Map<String, dynamic> data,
    required Map<String, String> sponsorIdLookup,
  }) {
    final String userKey = _normalizeLookupKey(userDocId);
    final String? byUid = sponsorIdLookup[userKey];
    if (byUid != null && byUid.isNotEmpty) return byUid;

    final String email = (data['email'] ?? '').toString().trim();
    if (email.isNotEmpty) {
      final String? byEmail = sponsorIdLookup[_normalizeLookupKey(email)];
      if (byEmail != null && byEmail.isNotEmpty) return byEmail;
    }

    return null;
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
    Color accent,
    Map<String, String> sponsorIdLookup,
  ) {
    final String name = _resolveUserName(data);
    final String email = (data['email'] ?? 'No email').toString();
    final String phone = (data['phone'] ?? 'Not available').toString();
    final String role = (data['role'] ?? 'Unknown').toString();
    final bool isStudent = _roleMatches(role, 'Student');
    final bool isSponsor = _roleMatches(role, 'Sponsor');

    final Map<String, dynamic>? teacherData =
        data['teacherData'] is Map<String, dynamic>
        ? data['teacherData'] as Map<String, dynamic>
        : null;
    final Map<String, dynamic>? studentData =
        data['studentData'] is Map<String, dynamic>
        ? data['studentData'] as Map<String, dynamic>
        : null;

    final String grade = _resolveGrade(data, studentData, teacherData);
    final String points = _resolvePoints(data, studentData);
    final String roleId = _resolveRoleId(
      role,
      userId,
      data,
      studentData,
      teacherData,
      _lookupSponsorIdFromApplicationMap(
        userDocId: userId,
        data: data,
        sponsorIdLookup: sponsorIdLookup,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        maxChildSize: 0.9,
        minChildSize: 0.45,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withOpacity(0.15),
                    child: Icon(Icons.person, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildDetailRow('Email', email),
              _buildPhoneActionRow(context, phone: phone, accent: accent),
              _buildDetailRow(isSponsor ? 'Sponsor ID' : 'User ID', roleId),
              if (!isSponsor) _buildDetailRow('Grade', grade),
              if (isStudent) _buildDetailRow('Points', points),
              if (teacherData != null) ...[
                _buildDetailRow(
                  'Teaching Grade',
                  (teacherData['teachingGrade'] ?? 'N/A').toString(),
                ),
                _buildDetailRow(
                  'Expertise',
                  _formatExpertise(teacherData['expertise']),
                ),
                _buildDetailRow(
                  'Teacher ID',
                  (teacherData['teacherID'] ?? 'N/A').toString(),
                ),
              ],
              if (studentData != null)
                _buildDetailRow(
                  'Student ID',
                  (studentData['studentID'] ?? 'N/A').toString(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int students,
    required int teachers,
    required int sponsors,
    required int newThisWeek,
  }) {
    Widget countChip(String label, int count, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label: $count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Overview',
            style: TextStyle(
              color: Color(0xFF1A1D26),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Total members: $total',
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (newThisWeek > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+$newThisWeek new',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              countChip('Students', students, const Color(0xFF2E7D32)),
              countChip('Teachers', teachers, const Color(0xFF1565C0)),
              countChip('Sponsors', sponsors, const Color(0xFF6A1B9A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    List<QueryDocumentSnapshot> users,
    String emptyLabel,
    Color accent,
    Map<String, String> sponsorIdLookup,
  ) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, color: Colors.grey[350], size: 48),
            const SizedBox(height: 10),
            Text(
              emptyLabel,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final data = users[index].data() as Map<String, dynamic>;
        final String name = _resolveUserName(data);
        final String role = (data['role'] ?? 'Unknown').toString();
        final bool isStudent = _roleMatches(role, 'Student');
        final bool isSponsor = _roleMatches(role, 'Sponsor');
        final Map<String, dynamic>? teacherData =
            data['teacherData'] is Map<String, dynamic>
            ? data['teacherData'] as Map<String, dynamic>
            : null;
        final Map<String, dynamic>? studentData =
            data['studentData'] is Map<String, dynamic>
            ? data['studentData'] as Map<String, dynamic>
            : null;
        final String grade = _resolveGrade(data, studentData, teacherData);
        final String points = _resolvePoints(data, studentData);
        final String roleId = _resolveRoleId(
          role,
          users[index].id,
          data,
          studentData,
          teacherData,
          _lookupSponsorIdFromApplicationMap(
            userDocId: users[index].id,
            data: data,
            sponsorIdLookup: sponsorIdLookup,
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C71D1).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _showUserDetails(
              context,
              users[index].id,
              data,
              accent,
              sponsorIdLookup,
            ),
            leading: CircleAvatar(
              backgroundColor: accent.withOpacity(0.14),
              child: Icon(Icons.person, color: accent),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildMetaChip(
                    icon: Icons.badge_outlined,
                    text: 'ID: $roleId',
                    color: accent,
                  ),
                  if (!isSponsor)
                    _buildMetaChip(
                      icon: Icons.school_rounded,
                      text: 'Grade: $grade',
                      color: accent,
                    ),
                  if (isStudent)
                    _buildMetaChip(
                      icon: Icons.stars_rounded,
                      text: 'Points: $points',
                      color: Colors.amber.shade800,
                    ),
                ],
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: accent),
          ),
        );
      },
    );
  }

  Widget _buildGrowthChart({
    required int students,
    required int teachers,
    required int sponsors,
    required List<QueryDocumentSnapshot> allDocs,
    required List<int> dailyS,
    required List<int> dailyT,
    required List<int> dailySp,
  }) {
    final safeTotal = allDocs.isEmpty ? 1 : allDocs.length;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final sGrowth = List.filled(7, 0.0);
    final tGrowth = List.filled(7, 0.0);
    final spGrowth = List.filled(7, 0.0);

    double curS = students.toDouble();
    double curT = teachers.toDouble();
    double curSp = sponsors.toDouble();

    for (int i = 6; i >= 0; i--) {
      sGrowth[i] = curS;
      tGrowth[i] = curT;
      spGrowth[i] = curSp;
      curS -= dailyS[i];
      curT -= dailyT[i];
      curSp -= dailySp[i];
    }

    final roles = [
      {'name': 'Students', 'count': students},
      {'name': 'Teachers', 'count': teachers},
      {'name': 'Sponsors', 'count': sponsors},
    ];
    roles.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final String topRole = roles[0]['name'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "User Growth",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C71D1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Top: $topRole",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C71D1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _roleRow('Students', students, safeTotal, const Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          _roleRow('Teachers', teachers, safeTotal, const Color(0xFF1565C0)),
          const SizedBox(height: 12),
          _roleRow('Sponsors', sponsors, safeTotal, const Color(0xFF6A1B9A)),
          const SizedBox(height: 30),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _MultiLineChartPainter(
                [sGrowth, tGrowth, spGrowth],
                [
                  const Color(0xFF2E7D32),
                  const Color(0xFF1565C0),
                  const Color(0xFF6A1B9A),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Daily New Joiners (7 Days)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildDailyUserBars(dailyS, dailyT, dailySp),
        ],
      ),
    );
  }

  Widget _buildDailyUserBars(List<int> ds, List<int> dt, List<int> dsp) {
    List<int> dailyTotals =
        List.generate(7, (i) => ds[i] + dt[i] + dsp[i]);
    final int maxNew = dailyTotals.reduce((a, b) => a > b ? a : b);
    final double safeMax = maxNew == 0 ? 1.0 : maxNew.toDouble();

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final String label = "D${index + 1}";
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _barSegment(dsp[index], safeMax, const Color(0xFF6A1B9A)),
                    _barSegment(dt[index], safeMax, const Color(0xFF1565C0)),
                    _barSegment(ds[index], safeMax, const Color(0xFF2E7D32)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _barSegment(int count, double max, Color color) {
    if (count == 0) return const SizedBox.shrink();
    final double h = (count / max) * 35;
    return Container(
      width: 12,
      height: h < 2 ? 2 : h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _roleRow(String label, int count, int total, Color color) {
    final ratio = count / total;
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "$count",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          title: const Text(
            'Community',
            style: TextStyle(
              color: Color(0xFF1A1D26),
              fontWeight: FontWeight.w900,
            ),
          ),
          backgroundColor: const Color(0xFFF8F9FD),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A1D26),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No users found.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }

            final allDocs = snapshot.data!.docs;

            final students = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _roleMatches(data['role'], 'Student');
            }).toList();

            final teachers = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _roleMatches(data['role'], 'Teacher');
            }).toList();

            final sponsors = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _roleMatches(data['role'], 'Sponsor');
            }).toList();

            final now = DateTime.now();
            final sevenDaysAgo = now.subtract(const Duration(days: 7));
            final dNewStudentsList = List.filled(7, 0);
            final dNewTeachersList = List.filled(7, 0);
            final dNewSponsorsList = List.filled(7, 0);

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final String role =
                  (data['role'] ?? "").toString().trim().toLowerCase();
              final dynamic created = data['createdAt'];
              if (created is Timestamp) {
                final date = created.toDate();
                if (date.isAfter(sevenDaysAgo)) {
                  final daysAgo = now.difference(date).inDays;
                  if (daysAgo >= 0 && daysAgo < 7) {
                    final int idx = 6 - daysAgo;
                    if (role == "student") {
                      dNewStudentsList[idx]++;
                    } else if (role == "teacher") {
                      dNewTeachersList[idx]++;
                    } else if (role == "sponsor") {
                      dNewSponsorsList[idx]++;
                    }
                  }
                }
              }
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sponsor_applications')
                  .snapshots(),
              builder: (context, sponsorAppsSnapshot) {
                final sponsorIdLookup = sponsorAppsSnapshot.hasData
                    ? _buildSponsorIdLookup(sponsorAppsSnapshot.data!.docs)
                    : <String, String>{};

                return Column(
                  children: [
                    _buildSummaryCard(
                      total: allDocs.length,
                      students: students.length,
                      teachers: teachers.length,
                      sponsors: sponsors.length,
                      newThisWeek: dNewStudentsList.reduce((a, b) => a + b) +
                          dNewTeachersList.reduce((a, b) => a + b) +
                          dNewSponsorsList.reduce((a, b) => a + b),
                    ),
                    const SizedBox(height: 20),
                    _buildGrowthChart(
                      students: students.length,
                      teachers: teachers.length,
                      sponsors: sponsors.length,
                      allDocs: allDocs,
                      dailyS: dNewStudentsList,
                      dailyT: dNewTeachersList,
                      dailySp: dNewSponsorsList,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF5C71D1).withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5C71D1).withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TabBar(
                        labelColor: const Color(0xFF5C71D1),
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: const Color(0xFF5C71D1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: [
                          Tab(text: 'Students (${students.length})'),
                          Tab(text: 'Teachers (${teachers.length})'),
                          Tab(text: 'Sponsors (${sponsors.length})'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildUserList(
                            students,
                            'No students available.',
                            const Color(0xFF2E7D32),
                            sponsorIdLookup,
                          ),
                          _buildUserList(
                            teachers,
                            'No teachers available.',
                            const Color(0xFF1565C0),
                            sponsorIdLookup,
                          ),
                          _buildUserList(
                            sponsors,
                            'No sponsors available.',
                            const Color(0xFF6A1B9A),
                            sponsorIdLookup,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MultiLineChartPainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> colors;
  _MultiLineChartPainter(this.series, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series.every((s) => s.isEmpty)) return;
    double maxVal = 1;
    for (var s in series) {
      if (s.isNotEmpty) {
        double m = s.reduce((a, b) => a > b ? a : b);
        if (m > maxVal) maxVal = m;
      }
    }
    final double stepX = size.width / (series[0].length - 1);
    for (int i = 0; i < series.length; i++) {
      final points = series[i];
      final color = colors[i];
      if (points.isEmpty) continue;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (int j = 0; j < points.length; j++) {
        final x = j * stepX;
        final y = size.height - (points[j] / maxVal) * size.height * 0.8;
        if (j == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
