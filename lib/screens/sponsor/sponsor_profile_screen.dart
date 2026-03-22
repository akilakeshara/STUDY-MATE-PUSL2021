import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/forgot_password_screen.dart';

class SponsorProfileScreen extends StatefulWidget {
  const SponsorProfileScreen({super.key});

  @override
  State<SponsorProfileScreen> createState() => _SponsorProfileScreenState();
}

class _SponsorProfileScreenState extends State<SponsorProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isDeleting = false;

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editNameDialog(String currentName) async {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'firstName': newName,
      'fullName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSnackBar('Name updated successfully.', Colors.green);
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
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
                      'This app provides sponsorship services and features. By using the app, you agree that your account and profile data may be used to manage sponsorship activities and improve service quality.',
                    ),
                    _buildPolicySection(
                      'Data Usage',
                      'We collect basic profile information such as name, email, contact number, and sponsorship details to operate the platform. We do not sell your personal data to third parties.',
                    ),
                    _buildPolicySection(
                      'Security',
                      'We use standard security measures to protect your information. However, no method over the internet is 100% secure.',
                    ),
                    _buildPolicySection(
                      'Contact Us',
                      'If you have any questions about this Privacy Policy, please contact the app support team.',
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
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                (route) => false,
              );
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

  void _deleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action is permanent and cannot be undone. All your sponsorship data will be deleted.',
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

  Future<void> _deleteSponsorRelatedData({
    required String uid,
    required String email,
  }) async {
    final firestore = FirebaseFirestore.instance;

    final QuerySnapshot appsByUid = await firestore
        .collection('sponsor_applications')
        .where('uid', isEqualTo: uid)
        .get();

    final QuerySnapshot appsByEmail = await firestore
        .collection('sponsor_applications')
        .where('email', isEqualTo: email)
        .get();

    final Set<String> appIds = {
      ...appsByUid.docs.map((doc) => doc.id),
      ...appsByEmail.docs.map((doc) => doc.id),
    };

    final batch = firestore.batch();
    for (final appId in appIds) {
      batch.delete(firestore.collection('sponsor_applications').doc(appId));
    }

    batch.delete(firestore.collection('users').doc(uid));
    await batch.commit();
  }

  Future<void> _deleteMyAccount() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('No active account found.', Colors.redAccent);
      return;
    }

    setState(() => _isDeleting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final String userEmail = currentUser.email ?? '';
      await _deleteSponsorRelatedData(uid: currentUser.uid, email: userEmail);
      await currentUser.delete();

      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
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
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User details not found'));
          }

          final Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          final String name =
              (data['firstName'] ?? data['fullName'] ?? 'Sponsor').toString();
          final String email = (data['email'] ?? user?.email ?? 'No Email')
              .toString();
          final String phone = (data['phone'] ?? 'Not provided').toString();
          final String sponsorId =
              (data['sponsorID'] ??
                      data['sponsorData']?['sponsorID'] ??
                      'SPN-0000')
                  .toString();
          final String organizationType = (data['organizationType'] ?? 'N/A')
              .toString();
          final String linkedin = (data['linkedin'] ?? 'N/A').toString();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              child: Column(
                children: [
                  _buildProfileHeader(name, email, sponsorId),
                  const SizedBox(height: 20),
                  _buildInfoSection(
                    name: name,
                    email: email,
                    phone: phone,
                    sponsorId: sponsorId,
                    organizationType: organizationType,
                    linkedin: linkedin,
                  ),
                  const SizedBox(height: 20),
                  _buildActionCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String sponsorId) {
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1C2E),
          ),
        ),
        Text(
          email,
          style: const TextStyle(
            color: Colors.blueGrey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildSmallBadge('SPONSOR ID: $sponsorId', const Color(0xFF5C71D1)),
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

  Widget _buildInfoSection({
    required String name,
    required String email,
    required String phone,
    required String sponsorId,
    required String organizationType,
    required String linkedin,
  }) {
    return Container(
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
          _buildCompactTile(
            Icons.person_outline_rounded,
            'Name',
            name,
            onTap: () => _editNameDialog(name),
          ),
          _buildCompactTile(Icons.alternate_email_rounded, 'Email', email),
          _buildCompactTile(Icons.badge_outlined, 'Sponsor ID', sponsorId),
          _buildCompactTile(Icons.phone_iphone_rounded, 'Phone Number', phone),
          _buildCompactTile(
            Icons.apartment_rounded,
            'Organization Type',
            organizationType,
          ),
          _buildCompactTile(Icons.link_rounded, 'LinkedIn', linkedin),
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
                      color: Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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
                color: Colors.grey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
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
            enabled: !_isDeleting,
            onTap: _isDeleting ? null : _deleteAccountDialog,
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.black38,
              size: 20,
            ),
            title: Text(
              _isDeleting ? 'Deleting...' : 'Delete Account',
              style: const TextStyle(
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
}
