import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import 'student_feedback_screen.dart';
import 'student_chat_with_admin_screen.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/welcome_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isGoogleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_isGoogleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _isGoogleInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User details not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['firstName'] ?? "Student";
          String email = userData['email'] ?? user?.email ?? "No Email";
          String phone = userData['phone'] ?? "Not Provided";

          var studentData = userData['studentData'] as Map<String, dynamic>?;
          String studentID = studentData?['studentID'] ?? "STU-0000";
          String grade = studentData?['selectedGrade'] ?? "Not Selected";
          int points = studentData?['points'] ?? 0;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Settings",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 20),
                  Center(child: _buildProfileHeader(name, email, studentID)),
                  const SizedBox(height: 25),
                  
                  _buildSectionHeader("Account"),
                  _buildSettingsGroup([
                    _buildSettingsTile(Icons.person_outline_rounded, "Name", name, onTap: () => _showEditNameDialog(name)),
                    _buildSettingsTile(Icons.phone_iphone_rounded, "Phone Number", phone, onTap: () => _showEditPhoneDialog(phone)),
                    _buildSettingsTile(Icons.alternate_email_rounded, "Email", email),
                    _buildSettingsTile(Icons.school_outlined, "Current Grade", grade),
                    _buildSettingsTile(Icons.stars_rounded, "Reward Points", "$points pts"),
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader("App Settings"),
                  _buildSettingsGroup([
                    _buildDarkModeToggle(),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionHeader("Support"),
                  _buildSettingsGroup([
                    _buildSettingsTile(Icons.support_agent_rounded, "Admin Support", "Get help from our team", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatWithAdminScreen()))),
                    _buildSettingsTile(Icons.privacy_tip_outlined, "Privacy Policy", "Learn how we protect data", onTap: _showPrivacyPolicy),
                    _buildSettingsTile(Icons.feedback_outlined, "Send Feedback", "Help us improve", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentFeedbackScreen()))),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionHeader("Security"),
                  _buildSettingsGroup([
                    _buildSettingsTile(Icons.lock_reset_rounded, "Change Password", "Secure your account", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()))),
                    _buildSettingsTile(Icons.logout_rounded, "Logout", "Sign out of your account", iconColor: Colors.redAccent, textColor: Colors.redAccent, onTap: _showLogoutDialog),
                    _buildSettingsTile(Icons.delete_outline_rounded, "Delete Account", "Permanently remove data", iconColor: Colors.black38, textColor: Colors.black45, isLast: true, onTap: _showDeleteConfirmationDialog),
                  ]),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String id) {
    return Column(
      children: [
        const SizedBox(height: 5),
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 1),
        Text(
          email,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildSmallBadge(id, const Color(0xFF5C71D1)),
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

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary.withOpacity(0.7), letterSpacing: 1.2),
    ),
  );

  Widget _buildSettingsGroup(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      border: Border.all(color: const Color(0xFF5C71D1).withOpacity(0.05)),
    ),
    child: Column(children: children),
  );

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? iconColor, Color? textColor, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(22)) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (iconColor ?? const Color(0xFF5C71D1)).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor ?? const Color(0xFF5C71D1), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor ?? Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black12, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    final isDark = themeModeNotifier.value == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dark Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 2),
                Text("Enjoy a dark aesthetic", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeColor: const Color(0xFF5C71D1),
            onChanged: (val) async {
              themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }



  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
            Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
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
                      "General Policy",
                      "Education built the Educate Live app as a Commercial app. This SERVICE is provided by Education and is intended for use as is. This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.",
                    ),
                    _buildPolicySection(
                      "Cookies",
                      "Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device's internal memory.",
                    ),
                    _buildPolicySection(
                      "Security",
                      "We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.",
                    ),
                    _buildPolicySection(
                      "Childrenâ€™s Privacy",
                      "These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13. In the case we discover that a child under 13 has provided us with personal information, we immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact us so that we will be able to do necessary actions.",
                    ),
                    _buildPolicySection(
                      "Contact Us",
                      "If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at support@educatelive.com.",
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "This privacy policy page was created at privacypolicytemplate.net and modified/generated by App Privacy Policy Generator",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
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
                    "I UNDERSTAND",
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
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Are you sure you want to logout from your account?",
          style: TextStyle(fontSize: 14, color: Colors.blueGrey),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "NO, STAY",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C71D1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Logged out successfully!"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              "YES, LOGOUT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text(
              "Delete Account",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to permanently delete your account? All your data, including points, grade, and profile information, will be lost and cannot be recovered.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount();
            },
            child: const Text(
              "DELETE NOW",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No active account found."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await currentUser.delete();

      final firestore = FirebaseFirestore.instance;
      final String uid = currentUser.uid;

      final progressSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('progress')
          .get();

      for (final doc in progressSnapshot.docs) {
        await doc.reference.delete();
      }

      final quizAttemptsSnapshot = await firestore
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: uid)
          .get();

      for (final doc in quizAttemptsSnapshot.docs) {
        await doc.reference.delete();
      }

      await firestore.collection('users').doc(uid).delete();

      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account deleted successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (e.code == 'requires-recent-login') {
        final didReauthenticate = await _reauthenticateCurrentUser(currentUser);
        if (didReauthenticate) {
          await _handleDeleteAccount();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Account deletion failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete account: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _promptPasswordForReauthentication() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirm Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("CONFIRM"),
          ),
        ],
      ),
    );
  }

  Future<bool> _reauthenticateCurrentUser(User currentUser) async {
    final providerIds = currentUser.providerData
        .map((provider) => provider.providerId)
        .toSet();

    try {
      if (providerIds.contains('password')) {
        final email = currentUser.email;
        if (email == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Re-authentication failed: email not found."),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }

        final password = await _promptPasswordForReauthentication();
        if (password == null || password.isEmpty) return false;

        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await currentUser.reauthenticateWithCredential(credential);
        return true;
      }

      if (providerIds.contains('google.com')) {
        await _ensureGoogleInitialized();
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-google-token',
            message: 'Google ID token is missing.',
          );
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await currentUser.reauthenticateWithCredential(credential);
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Re-authentication is required. Please logout and login again.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Re-authentication failed.";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Incorrect password. Please try again.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return false;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Re-authentication cancelled."),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
  }

  void _showEditPhoneDialog(String currentPhone) {
    String newFullPhone = currentPhone;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Edit Phone Number", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: IntlPhoneField(
            initialCountryCode: 'LK',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: "Phone Number",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            initialValue: currentPhone.startsWith('+94') ? currentPhone.substring(3) : currentPhone,
            onChanged: (phone) {
              newFullPhone = phone.completeNumber;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newFullPhone.isNotEmpty) {
                _updatePhone(newFullPhone);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePhone(String newPhone) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'phone': newPhone,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Phone number updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update phone number: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text("Edit Name", style: TextStyle(fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "First Name",
            hintText: "Enter your name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _updateName(newName);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateName(String newName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'firstName': newName,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Name updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update name: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
