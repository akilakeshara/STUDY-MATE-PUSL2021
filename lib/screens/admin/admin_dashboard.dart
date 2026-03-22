import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_profile_screen.dart';
import 'admin_teacher_verification_screen.dart';
import 'admin_sponsor_verification_screen.dart';
import 'admin_community_screen.dart';
import 'admin_student_chat.dart';
import 'admin_teacher_chat.dart';
import 'admin_sponsor_chat.dart';
import 'admin_approval_screen.dart';
import 'admin_news_feed_screen.dart';
import 'admin_sponsorship_requests_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  String adminName = "Admin";
  int totalStudents = 0, totalTeachers = 0, totalSponsors = 0, totalUsers = 0;
  int pendingTeacherRequests = 0;
  int pendingSponsorRequests = 0;
  int pendingSponsorshipRequests = 0;
  int pendingApprovalsCount = 0;
  double weeklyRevenue = 0.0;
  double totalRevenue = 0.0;
  List<double> dailyRevenue = List.filled(7, 0.0);
  List<double> studentGrowthPoints = [];
  List<double> teacherGrowthPoints = [];
  List<double> sponsorGrowthPoints = [];
  List<int> dailyNewStudentsList = List.filled(7, 0);
  List<int> dailyNewTeachersList = List.filled(7, 0);
  List<int> dailyNewSponsorsList = List.filled(7, 0);
  int newUsersThisWeek = 0;

  // Subscriptions to cancel on dispose
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
    _fetchUserStats();
    _fetchPendingRequests();
    _fetchRevenueStats();
  }

  Future<void> _fetchAdminData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          adminName = data?['firstName'] ?? data?['name'] ?? "Admin";
        });
      }
    }
  }

  void _fetchPendingRequests() {
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('teacher_applications')
          .where('status', isEqualTo: 'Pending')
          .snapshots()
          .listen((snapshot) {
            if (mounted)
              setState(() => pendingTeacherRequests = snapshot.docs.length);
          }),
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('sponsor_applications')
          .snapshots()
          .listen((snapshot) {
            final pending = snapshot.docs.where((doc) {
              final status = (doc.data()['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              return status == 'applied' || status == 'pending';
            }).length;
            if (mounted) setState(() => pendingSponsorRequests = pending);
          }),
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('sponsorship_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
            if (mounted)
              setState(() => pendingSponsorshipRequests = snapshot.docs.length);
          }),
    );

    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('lessons')
          .where('isApproved', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
            if (mounted)
              setState(() => pendingApprovalsCount = snapshot.docs.length);
          }),
    );
  }

  void _fetchUserStats() {
    _subscriptions.add(
      FirebaseFirestore.instance.collection('users').snapshots().listen((
        snapshot,
      ) {
        int s = 0, t = 0, sp = 0;
        int newThisWeek = 0;
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        // For simplicity, let's map user growth over 7 days
        List<int> dNewStudents = List.filled(7, 0);
        List<int> dNewTeachers = List.filled(7, 0);
        List<int> dNewSponsors = List.filled(7, 0);
        List<int> dailyNewTotal = List.filled(7, 0);

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            final String role = (data['role'] ?? "")
                .toString()
                .trim()
                .toLowerCase();

            if (role == "student") {
              s++;
            } else if (role == "teacher") {
              t++;
            } else if (role == "sponsor") {
              sp++;
            }

            final dynamic created = data['createdAt'];
            if (created is Timestamp) {
              final date = created.toDate();
              if (date.isAfter(sevenDaysAgo)) {
                newThisWeek++;
                final daysAgo = now.difference(date).inDays;
                if (daysAgo >= 0 && daysAgo < 7) {
                  final int idx = 6 - daysAgo;
                  dailyNewTotal[idx]++;
                  if (role == "student") {
                    dNewStudents[idx]++;
                  } else if (role == "teacher") {
                    dNewTeachers[idx]++;
                  } else if (role == "sponsor") {
                    dNewSponsors[idx]++;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error parsing user doc: $e");
          }
        }

        // Convert counts to cumulative growth points for the line chart
        // We calculate backwards from current total to ensure it ends exactly at current total
        List<double> sGrowth = List.filled(7, 0.0);
        List<double> tGrowth = List.filled(7, 0.0);
        List<double> spGrowth = List.filled(7, 0.0);

        double curS = s.toDouble();
        double curT = t.toDouble();
        double curSp = sp.toDouble();

        for (int i = 6; i >= 0; i--) {
          sGrowth[i] = curS;
          tGrowth[i] = curT;
          spGrowth[i] = curSp;
          
          curS -= dNewStudents[i];
          curT -= dNewTeachers[i];
          curSp -= dNewSponsors[i];
        }

        if (mounted) {
          setState(() {
            totalStudents = s;
            totalTeachers = t;
            totalSponsors = sp;
            totalUsers = snapshot.docs.length;
            newUsersThisWeek = newThisWeek;

            studentGrowthPoints = sGrowth;
            teacherGrowthPoints = tGrowth;
            sponsorGrowthPoints = spGrowth;
            dailyNewStudentsList = dNewStudents;
            dailyNewTeachersList = dNewTeachers;
            dailyNewSponsorsList = dNewSponsors;
          });
        }
      }),
    );
  }

  void _fetchRevenueStats() {
    _subscriptions.add(
      FirebaseFirestore.instance
          .collection('sponsor_payments')
          .snapshots()
          .listen((snapshot) {
            double total = 0.0;
            double weekly = 0.0;
            List<double> daily = List.filled(7, 0.0);
            final now = DateTime.now();
            final sevenDaysAgo = now.subtract(const Duration(days: 7));

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final double amount = (data['amount'] ?? 0.0).toDouble();
              total += amount;

              final dynamic timestamp = data['timestamp'] ?? data['createdAt'];
              if (timestamp is Timestamp) {
                final date = timestamp.toDate();
                if (date.isAfter(sevenDaysAgo)) {
                  weekly += amount;
                  final daysAgo = now.difference(date).inDays;
                  if (daysAgo >= 0 && daysAgo < 7) {
                    daily[6 - daysAgo] += amount;
                  }
                }
              }
            }

            if (mounted) {
              setState(() {
                totalRevenue = total;
                weeklyRevenue = weekly;
                dailyRevenue = daily;
              });
            }
          }),
    );
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: _currentIndex == 0
          ? _buildDashboardHome()
          : (_currentIndex == 1
                ? const AdminApprovalScreen()
                : const AdminProfileScreen()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                const Text(
                  "Quick Conversations",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1C2E),
                  ),
                ),
                const SizedBox(height: 15),
                _buildFixedChatRow(),
                const SizedBox(height: 18),
                _buildNewsFeedLaunchCard(),
                const SizedBox(height: 16),
                _buildAdminNotificationsCard(), // Fixed Logic inside
                const SizedBox(height: 30),
                _buildActionIconBar(),
                const SizedBox(height: 30),
                _buildUnifiedGrowthChart(),
                const SizedBox(height: 25),
                _buildWeeklyRevenueBarChart(), // REVENUE RESTORED
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 58, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, $adminName ",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Control your campus ecosystem",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5C71D1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF5C71D1),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // --- Fixed Notifications Card ---
  Widget _buildAdminNotificationsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 18,
                    color: Color(0xFF5C71D1),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Recent Notifications',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                const Text(
                  "Connection issue. Restart app.",
                  style: TextStyle(fontSize: 12, color: Colors.red),
                )
              else if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                const Text(
                  "No new notifications.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Column(
                  children: snapshot.data!.docs
                      .map(
                        (doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5C71D1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  (doc['title'] ?? 'Notification').toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1C2E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- RESTORED Unified Main Box (Dividers included) ---
  Widget _buildActionIconBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionIconButton(
          label: 'Community',
          icon: Icons.groups_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminCommunityScreen(),
            ),
          ),
        ),
        _buildActionIconButton(
          label: 'Teacher Apps',
          icon: Icons.how_to_reg_rounded,
          badge: pendingTeacherRequests,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminTeacherVerificationScreen(),
            ),
          ),
        ),
        _buildActionIconButton(
          label: 'Sponsor Apps',
          icon: Icons.business_center_rounded,
          badge: pendingSponsorRequests,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminSponsorVerificationScreen(),
            ),
          ),
        ),
        _buildActionIconButton(
          label: 'Sponsorship Req',
          icon: Icons.request_page_rounded,
          badge: pendingSponsorshipRequests,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminSponsorshipRequestsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionIconButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C71D1).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF5C71D1), size: 24),
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label.split(' ').first,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedGrowthChart() {
    final int safeTotal = totalUsers == 0 ? 1 : totalUsers;

    // Sort roles by count to find the "Top" one
    final roles = [
      {
        'name': 'Students',
        'count': totalStudents,
        'color': const Color(0xFF22C55E),
      },
      {
        'name': 'Teachers',
        'count': totalTeachers,
        'color': const Color(0xFF3B82F6),
      },
      {
        'name': 'Sponsors',
        'count': totalSponsors,
        'color': const Color(0xFF8B5CF6),
      },
    ];
    roles.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final String topRole = roles[0]['name'] as String;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C71D1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Top: $topRole",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5C71D1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalUsers users',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            "$topRole lead with ${roles[0]['count']} accounts",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          // Horizontal Role Bars
          _roleProgressBar(
            'Students',
            totalStudents,
            safeTotal,
            const Color(0xFF22C55E),
          ),
          const SizedBox(height: 12),
          _roleProgressBar(
            'Teachers',
            totalTeachers,
            safeTotal,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _roleProgressBar(
            'Sponsors',
            totalSponsors,
            safeTotal,
            const Color(0xFF8B5CF6),
          ),

          const SizedBox(height: 24),

          // Legend
          Row(
            children: [
              _legendItem("Students", const Color(0xFF22C55E)),
              const SizedBox(width: 15),
              _legendItem("Teachers", const Color(0xFF3B82F6)),
              const SizedBox(width: 15),
              _legendItem("Sponsors", const Color(0xFF8B5CF6)),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _MultiLineChartPainter(
                [studentGrowthPoints, teacherGrowthPoints, sponsorGrowthPoints],
                [
                  const Color(0xFF22C55E),
                  const Color(0xFF3B82F6),
                  const Color(0xFF8B5CF6),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Daily New Joiners (7 Days)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildDailyUserBars(),
        ],
      ),
    );
  }

  Widget _buildDailyUserBars() {
    List<int> dailyTotals = List.generate(7, (i) => dailyNewStudentsList[i] + dailyNewTeachersList[i] + dailyNewSponsorsList[i]);
    final int maxNew = dailyTotals.reduce((a, b) => a > b ? a : b);
    final double safeMax = maxNew == 0 ? 1.0 : maxNew.toDouble();

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final String label = "D${index + 1}";
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Stacked Bar
              Container(
                width: 14,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _barSegment(dailyNewSponsorsList[index], safeMax, const Color(0xFF8B5CF6)),
                    _barSegment(dailyNewTeachersList[index], safeMax, const Color(0xFF3B82F6)),
                    _barSegment(dailyNewStudentsList[index], safeMax, const Color(0xFF22C55E)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
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
    final double h = (count / max) * 40;
    return Container(
      width: 14,
      height: h < 2 ? 2 : h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _roleProgressBar(String label, int count, int total, Color color) {
    final double ratio = count / total;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 15),
        SizedBox(
          width: 50,
          child: Text(
            "$count (${(ratio * 100).toStringAsFixed(0)}%)",
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // --- UI Helpers ---
  // REMOVED _buildAdminActionCard

  Widget _buildNewsFeedLaunchCard() => GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminNewsFeedScreen()),
    ),
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.newspaper_rounded, color: Colors.white),
          SizedBox(width: 12),
          Text(
            'Post Latest News',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    ),
  );

  Widget _buildFixedChatRow() => Row(
    children: [
      Expanded(
        child: _chatBtn(
          "Student Chat",
          Icons.chat_bubble,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentChatScreen()),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _chatBtn(
          "Teacher Chat",
          Icons.forum,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherChatScreen()),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _chatBtn(
          "Sponsor Chat",
          Icons.handshake,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SponsorChatScreen()),
          ),
        ),
      ),
    ],
  );

  Widget _chatBtn(String label, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF5C71D1),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C71D1).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildWeeklyRevenueBarChart() => Container(
    padding: const EdgeInsets.all(24),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
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
              "Weekly Revenue",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF64748B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Top: -",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'LKR ${weeklyRevenue.toStringAsFixed(2)} this week',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          "Total Amount: LKR ${totalRevenue.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminSponsorshipRequestsScreen(),
              ),
            ),
            icon: const Icon(Icons.payments_rounded, size: 18),
            label: const Text("View Funded Sponsors"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5C71D1),
              side: BorderSide(color: const Color(0xFF5C71D1).withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildBarChart(),
      ],
    ),
  );

  Widget _buildBarChart() {
    final double maxRev = dailyRevenue.reduce((a, b) => a > b ? a : b);
    final double safeMax = maxRev == 0 ? 1.0 : maxRev;

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          // We need to map current day of week to our dailyRevenue list which is [6 days ago ... today]
          // For simplicity, let's just label them D1 to D7 or generic
          final String label = "D${index + 1}";
          final double h = (dailyRevenue[index] / safeMax) * 40;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 14,
                height: h < 4 ? 4 : h,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C71D1).withOpacity(h > 0 ? 0.8 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    height: 68,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
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
        _navItem(Icons.home_filled, "Home", 0),
        _navItem(
          Icons.fact_check_rounded,
          "Approvals",
          1,
          badge: pendingApprovalsCount,
        ),
        _navItem(Icons.person_rounded, "Account", 2),
      ],
    ),
  );

  Widget _navItem(IconData icon, String label, int index, {int badge = 0}) =>
      GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? const Color(0xFF5C71D1).withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: _currentIndex == index
                        ? const Color(0xFF5C71D1)
                        : Colors.blueGrey[400],
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (_currentIndex == index)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF5C71D1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Stream<int> _totalUnreadSupportChatsStream() => FirebaseFirestore.instance
      .collection('support_chats')
      .where('hasUnreadForAdmin', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

class _MultiLineChartPainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> colors;
  _MultiLineChartPainter(this.series, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty || series.every((s) => s.isEmpty)) return;

    // Find max value across all series
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
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);

      // Add gradient under the line
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
