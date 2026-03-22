import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStudentListScreen extends StatefulWidget {
  const AdminStudentListScreen({super.key});

  @override
  State<AdminStudentListScreen> createState() => _AdminStudentListScreenState();
}

class _AdminStudentListScreenState extends State<AdminStudentListScreen> {
  String currentRole = "Student";
  int totalStudents = 0, totalTeachers = 0, totalSponsors = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    FirebaseFirestore.instance.collection('users').snapshots().listen((
      snapshot,
    ) {
      int s = 0, t = 0, sp = 0;
      for (var doc in snapshot.docs) {
        String role = doc['role'] ?? "";
        if (role == "Student") {
          s++;
        } else if (role == "Teacher")
          t++;
        else if (role == "Sponsor")
          sp++;
      }
      if (mounted) {
        setState(() {
          totalStudents = s;
          totalTeachers = t;
          totalSponsors = sp;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  const Text(
                    "Quick Statistics",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      color: Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildInteractiveStatsRow(),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$currentRole Directory",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF1A1D26),
                        ),
                      ),
                      _buildCounterBadge(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildDynamicUserList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF4A5CB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(height: 20),
                Text(
                  "User Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Study Mate Admin Panel",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildClickableMiniCard(
          "Student",
          totalStudents,
          Icons.people_rounded,
          const Color(0xFF9B51E0),
        ),
        _buildClickableMiniCard(
          "Teacher",
          totalTeachers,
          Icons.school_rounded,
          const Color(0xFF5C71D1),
        ),
        _buildClickableMiniCard(
          "Sponsor",
          totalSponsors,
          Icons.card_giftcard_rounded,
          const Color(0xFF27AE60),
        ),
      ],
    );
  }

  Widget _buildClickableMiniCard(
    String role,
    int value,
    IconData icon,
    Color color,
  ) {
    bool isSelected = currentRole == role;
    return GestureDetector(
      onTap: () => setState(() => currentRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 24),
            const SizedBox(height: 8),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : const Color(0xFF1A1D26),
              ),
            ),
            Text(
              role,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterBadge() {
    int count = currentRole == "Student"
        ? totalStudents
        : currentRole == "Teacher"
        ? totalTeachers
        : totalSponsors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5C71D1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "Total: $count",
        style: const TextStyle(
          color: Color(0xFF5C71D1),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDynamicUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: currentRole)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 10),
                Text(
                  "No $currentRole"
                  "s registered yet.",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildUserListItem(data);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildUserAvatar(data['profileImage']),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? "Unknown User",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1A1D26),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['email'] ?? "No email address",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDF1FD),
              foregroundColor: const Color(0xFF5C71D1),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "View",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String? imageUrl) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(15),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? const Icon(Icons.person_outline_rounded, color: Color(0xFF5C71D1))
          : null,
    );
  }
}
