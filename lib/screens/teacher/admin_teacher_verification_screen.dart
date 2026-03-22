import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminTeacherVerificationScreen extends StatelessWidget {
  const AdminTeacherVerificationScreen({super.key});

  String _applicationDuplicateKey(
    Map<String, dynamic> data,
    String fallbackDocId,
  ) {
    final String uid = (data['uid'] ?? '').toString().trim();
    final String email = (data['email'] ?? '').toString().trim().toLowerCase();
    if (email.isNotEmpty) return email;
    if (uid.isNotEmpty) return uid;
    return fallbackDocId;
  }

  String _formatExpertise(dynamic value) {
    if (value == null) return "Subject N/A";
    if (value is List) {
      if (value.isEmpty) return "Subject N/A";
      return value.join(', ');
    }
    return value.toString();
  }

  Future<void> _cleanupDuplicatePendingApplications(
    BuildContext context,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teacher_applications')
          .where('status', isEqualTo: 'Pending')
          .get();

      final Map<String, QueryDocumentSnapshot> seen = {};
      final batch = FirebaseFirestore.instance.batch();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = _applicationDuplicateKey(data, doc.id);
        if (seen.containsKey(key)) {
          batch.delete(doc.reference);
          deletedCount++;
        } else {
          seen[key] = doc;
        }
      }

      if (deletedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No duplicate pending applications found.'),
          ),
        );
        return;
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Removed $deletedCount duplicate pending application(s).',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cleanup failed: $e')));
    }
  }

  Future<void> _confirmCleanupPendingApplications(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Duplicates'),
        content: const Text(
          'This will remove duplicate teacher requests from the pending verification list. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cleanupDuplicatePendingApplications(context);
    }
  }

  Future<void> _sendEmailNotification({
    required String teacherEmail,
    required String teacherName,
    required String status,
  }) async {
    const String serviceId = 'service_xxxxxx';
    const String templateId = 'template_xxxxxx';
    const String userId = 'user_xxxxxxxxxxxx';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_name': teacherName,
            'to_email': teacherEmail,
            'status': status,
            'message': status == 'Approved'
                ? 'Congratulations! Your teacher account has been approved. You can now login to the Study Mate system.'
                : 'We regret to inform you that your teacher application has been declined after a review of your details.',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Email Notification sent successfully!');
      } else {
        print('Failed to send email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "Teacher Verifications",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF5C71D1),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cleanup Duplicates',
            onPressed: () => _confirmCleanupPendingApplications(context),
            icon: const Icon(Icons.cleaning_services_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teacher_applications')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 15),
                  const Text(
                    "Error loading applications",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final rawDocs = snapshot.data!.docs;
          final Map<String, QueryDocumentSnapshot> uniqueDocs = {};
          for (final doc in rawDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final String key = _applicationDuplicateKey(data, doc.id);

            if (!uniqueDocs.containsKey(key)) {
              uniqueDocs[key] = doc;
            }
          }

          final docs = uniqueDocs.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF5C71D1).withOpacity(0.1),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: Color(0xFF5C71D1),
                    ),
                  ),
                  title: Text(
                    (data['fullName'] ?? "New Applicant").toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatExpertise(data['expertise']),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  onTap: () => _showApplicationDetails(context, data, docId),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.fact_check_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 15),
        const Text(
          "All clear!",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF4B5563),
          ),
        ),
        const Text(
          "No pending applications to review.",
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  void _showApplicationDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 25),
              const Text(
                "Teacher Profile Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInfoCard("Full Name", data['fullName'], Icons.person),
                    _buildInfoCard("Email Address", data['email'], Icons.email),
                    _buildInfoCard(
                      "Contact Number",
                      data['phone'],
                      Icons.phone,
                    ),
                    _buildInfoCard(
                      "Grade Level",
                      data['teachingGrade'],
                      Icons.layers,
                    ),
                    _buildInfoCard(
                      "Subject Expertise",
                      _formatExpertise(data['expertise']),
                      Icons.book,
                    ),
                    _buildInfoCard(
                      "Experience",
                      "${data['experience']} Years",
                      Icons.history_edu,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Support Documents",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    _buildFileButton(data['fileUrl'], data['fileName']),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      "Decline",
                      Colors.red,
                      Icons.close,
                      () => _processApplication(
                        context,
                        docId,
                        'Declined',
                        data['email'],
                        data['fullName'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionButton(
                      "Approve",
                      Colors.green,
                      Icons.check,
                      () => _processApplication(
                        context,
                        docId,
                        'Approved',
                        data['email'],
                        data['fullName'],
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

  Widget _buildInfoCard(String label, dynamic value, IconData icon) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFEEF2FF)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF5C71D1)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value?.toString() ?? "N/A",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C2E),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildFileButton(String? url, String? name) => InkWell(
    onTap: () async {
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    },
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.file_present_rounded, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name ?? "View Attachment",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18, color: Colors.white),
    label: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );

  Future<void> _processApplication(
    BuildContext context,
    String docId,
    String status,
    String? email,
    String? name,
  ) async {
    try {
      final String role = status == 'Approved' ? 'Teacher' : 'Student';

      await FirebaseFirestore.instance
          .collection('teacher_applications')
          .doc(docId)
          .update({
            'status': status,
            'role': role,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      String? resolvedUid;
      final appSnap = await FirebaseFirestore.instance
          .collection('teacher_applications')
          .doc(docId)
          .get();
      if (appSnap.exists) {
        final appData = appSnap.data();
        resolvedUid = appData?['uid']?.toString();
      }

      if ((resolvedUid == null || resolvedUid.isEmpty) &&
          email != null &&
          email.isNotEmpty) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
        if (userQuery.docs.isNotEmpty) {
          resolvedUid = userQuery.docs.first.id;
        }
      }

      if (resolvedUid != null && resolvedUid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(resolvedUid)
            .update({
              'status': status,
              'role': role,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (email != null && email.isNotEmpty) {
        await _sendEmailNotification(
          teacherEmail: email,
          teacherName: name ?? 'Teacher',
          status: status,
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Teacher has been $status successfully!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
