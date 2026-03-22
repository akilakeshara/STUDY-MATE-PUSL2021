import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/forgot_password_screen.dart';
import 'teacher_home_screen.dart';
import 'teacher_lessons_list_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;

  String name = 'Loading...';
  String email = '';
  String phone = '';
  String teacherId = '';
  String grade = '';
  String subject = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;

    final DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>?;
      setState(() {
        name = data?['fullName'] ?? 'No Name';
        email = data?['email'] ?? '';
        phone = data?['phone'] ?? 'Not provided';
        teacherId = data?['teacherData']?['teacherID'] ?? 'TCH-0000';
        grade = data?['teacherData']?['teachingGrade'] ?? 'Not Set';
        final rawExpertise = data?['teacherData']?['expertise'];
        if (rawExpertise is List) {
          subject = rawExpertise.join(', ');
        } else {
          subject = (rawExpertise as String?) ?? 'Not Specified';
        }
      });
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _deleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMyAccount();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeacherRelatedData({
    required String uid,
    required String email,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final userRef = firestore.collection('users').doc(uid);

    final lessonsSnapshot = await firestore
        .collection('lessons')
        .where('teacherId', isEqualTo: uid)
        .get();

    final applicationsByUid = await firestore
        .collection('teacher_applications')
        .where('uid', isEqualTo: uid)
        .get();

    final applicationsByEmail = await firestore
        .collection('teacher_applications')
        .where('email', isEqualTo: email)
        .get();

    final Set<String> appIds = {
      ...applicationsByUid.docs.map((doc) => doc.id),
      ...applicationsByEmail.docs.map((doc) => doc.id),
    };

    final batch = firestore.batch();

    for (final lessonDoc in lessonsSnapshot.docs) {
      batch.delete(lessonDoc.reference);
    }

    for (final appId in appIds) {
      batch.delete(firestore.collection('teacher_applications').doc(appId));
    }

    batch.delete(userRef);

    await batch.commit();
  }

  Future<void> _deleteMyAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('No active account found.', Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String userEmail = currentUser.email ?? email;

      await currentUser.delete();
      await _deleteTeacherRelatedData(uid: currentUser.uid, email: userEmail);

      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (e.code == 'requires-recent-login') {
        _showSnackBar(
          'For security, please login again and then delete your account.',
          Colors.orange,
        );
      } else {
        _showSnackBar(e.message ?? 'Account deletion failed.', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showSnackBar('Failed to delete account: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1C2E),
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicySection(
                      'General Policy',
                      'Education built the Educate Live app as a Commercial app. This SERVICE is provided by Education and is intended for use as is. This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.',
                    ),
                    _buildPolicySection(
                      'Cookies',
                      "Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.",
                    ),
                    _buildPolicySection(
                      'Security',
                      'We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.',
                    ),
                    _buildPolicySection(
                      'Children\'s Privacy',
                      'These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do necessary actions.',
                    ),
                    _buildPolicySection(
                      'Contact Us',
                      'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at [App contact information].',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This privacy policy page was created at privacypolicytemplate.net and modified/generated by App Privacy Policy Generator',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'I UNDERSTAND',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C71D1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 30),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              _buildInfoSection(),
              const SizedBox(height: 20),
              _buildActionCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 39,
            backgroundImage: NetworkImage(
              'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          email,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _buildSmallBadge('TEACHER ID: $teacherId', const Color(0xFF5C71D1)),
      ],
    );
  }

  Widget _buildSmallBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactTile(Icons.person_outline_rounded, 'Name', name),
          _buildCompactTile(Icons.alternate_email_rounded, 'Email', email),
          _buildCompactTile(Icons.phone_iphone_rounded, 'Phone Number', phone),
          _buildCompactTile(Icons.school_outlined, 'Teaching Grade', grade),
          _buildCompactTile(
            Icons.psychology_rounded,
            'Subject Expertise',
            subject,
          ),
          _buildCompactTile(
            Icons.lock_reset_rounded,
            'Security',
            'Change Password',
            onTap: _changePassword,
          ),
          _buildCompactTile(
            Icons.privacy_tip_outlined,
            'Legal',
            'Privacy Policy',
            isLast: true,
            onTap: _showPrivacyPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTile(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(25))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5C71D1).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF5C71D1), size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1C2E),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF94A3B8),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            onTap: _showLogoutDialog,
            leading: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.redAccent,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
          const Divider(height: 1, indent: 50),
          ListTile(
            dense: true,
            onTap: _deleteAccountDialog,
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.black38,
              size: 20,
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black26,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
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
          _buildNavItem(Icons.grid_view_rounded, 'Home', 0),
          _buildNavItem(Icons.video_collection_rounded, 'My Lessons', 1),
          _buildNavItem(Icons.person_rounded, 'Profile', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    const int currentIndex = 2;
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const TeacherHomeScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TeacherLessonsListScreen(),
            ),
          );
        }
      },
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
              color: isActive ? const Color(0xFF5C71D1) : const Color(0xFF94A3B8),
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
