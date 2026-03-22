import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSponsorVerificationScreen extends StatelessWidget {
  const AdminSponsorVerificationScreen({super.key});

  String _normalizedStatus(Map<String, dynamic> data) {
    return (data['status'] ?? '').toString().trim().toLowerCase();
  }

  bool _isPendingStatus(String status) {
    return status == 'applied' || status == 'pending';
  }

  Future<String?> _resolveUserId({
    required String docId,
    required String? uid,
    required String? email,
  }) async {
    final String cleanedUid = (uid ?? '').trim();
    if (cleanedUid.isNotEmpty) return cleanedUid;

    final String cleanedEmail = (email ?? '').trim().toLowerCase();
    if (cleanedEmail.isNotEmpty) {
      final userByEmail = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: cleanedEmail)
          .limit(1)
          .get();
      if (userByEmail.docs.isNotEmpty) {
        return userByEmail.docs.first.id;
      }
    }

    final userByDocId = await FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .get();
    if (userByDocId.exists) return userByDocId.id;

    return null;
  }

  Future<void> _processApplication({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
    required String nextStatus,
  }) async {
    final String normalizedStatus = nextStatus.trim().toLowerCase();
    try {
      await FirebaseFirestore.instance
          .collection('sponsor_applications')
          .doc(docId)
          .update({
            'status': normalizedStatus,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      final String? userId = await _resolveUserId(
        docId: docId,
        uid: data['uid']?.toString(),
        email: data['email']?.toString(),
      );

      if (userId != null && userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'uid': userId,
          'email': (data['email'] ?? '').toString().trim().toLowerCase(),
          'firstName': (data['fullName'] ?? '').toString().trim(),
          'phone': (data['phone'] ?? '').toString().trim(),
          'organizationType': (data['organizationType'] ?? '')
              .toString()
              .trim(),
          'sponsorID': (data['sponsorID'] ?? '').toString().trim(),
          'linkedin': (data['linkedin'] ?? '').toString().trim(),
          'role': 'Sponsor',
          'status': normalizedStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sponsor application ${normalizedStatus.toUpperCase()}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showApplicationDetails(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(22),
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
              const SizedBox(height: 20),
              const Text(
                'Sponsor Application Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildInfoCard('Full Name', data['fullName'], Icons.person),
                    _buildInfoCard(
                      'Email',
                      data['email'],
                      Icons.email_outlined,
                    ),
                    _buildInfoCard(
                      'Phone',
                      data['phone'],
                      Icons.phone_outlined,
                    ),
                    _buildInfoCard(
                      'Sponsorship Method',
                      data['method'],
                      Icons.volunteer_activism_rounded,
                    ),
                    _buildInfoCard(
                      'LinkedIn',
                      data['linkedin'],
                      Icons.link_rounded,
                    ),
                    _buildInfoCard(
                      'Applied On',
                      _formatTimestamp(data['timestamp']),
                      Icons.schedule_rounded,
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Decline',
                      color: Colors.red,
                      icon: Icons.close,
                      onTap: () => _processApplication(
                        context: context,
                        docId: docId,
                        data: data,
                        nextStatus: 'Declined',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Approve',
                      color: Colors.green,
                      icon: Icons.check,
                      onTap: () => _processApplication(
                        context: context,
                        docId: docId,
                        data: data,
                        nextStatus: 'Approved',
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

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
    return 'N/A';
  }

  Widget _buildInfoCard(String label, dynamic value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF2FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5C71D1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value?.toString().trim().isNotEmpty == true
                      ? value.toString().trim()
                      : 'N/A',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'All clear!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const Text(
            'No pending sponsor applications.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5C71D1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Color(0xFF5C71D1),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Sponsor Reviews',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review and approve sponsor requests',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5B6475)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF5C71D1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$pendingCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF5C71D1)),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
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
      appBar: AppBar(
        title: const Text(
          'Sponsor Applications',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF5C71D1),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sponsor_applications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _isPendingStatus(_normalizedStatus(data));
          }).toList();

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            child: Column(
              children: [
                _buildSummaryCard(docs.length),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;
                      final String method = (data['method'] ?? 'Sponsorship')
                          .toString()
                          .trim();
                      final String email = (data['email'] ?? 'No email')
                          .toString()
                          .trim();
                      final String appliedOn = _formatTimestamp(
                        data['timestamp'],
                      );

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
                            backgroundColor: const Color(
                              0xFF5C71D1,
                            ).withOpacity(0.1),
                            child: const Icon(
                              Icons.business_center_rounded,
                              color: Color(0xFF5C71D1),
                            ),
                          ),
                          title: Text(
                            (data['fullName'] ?? 'Sponsor Applicant')
                                .toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildMetaChip(
                                      Icons.volunteer_activism_rounded,
                                      method,
                                    ),
                                    _buildMetaChip(
                                      Icons.schedule_rounded,
                                      appliedOn,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () =>
                              _showApplicationDetails(context, docId, data),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
