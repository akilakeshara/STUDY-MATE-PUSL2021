import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSponsorshipRequestsScreen extends StatelessWidget {
  const AdminSponsorshipRequestsScreen({super.key});

  Future<void> _updateRequestStatus({
    required BuildContext context,
    required String requestId,
    required Map<String, dynamic> data,
    required String nextStatus,
  }) async {
    final String normalizedStatus = nextStatus.trim().toLowerCase();

    try {
      final requestRef = FirebaseFirestore.instance
          .collection('sponsorship_requests')
          .doc(requestId);

      final String sponsorUid = (data['sponsorUid'] ?? '').toString().trim();
      final String studentUid = (data['studentUid'] ?? '').toString().trim();
      final DocumentReference lockRef = FirebaseFirestore.instance
          .collection('sponsorship_student_locks')
          .doc(studentUid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (normalizedStatus == 'approved' &&
            sponsorUid.isNotEmpty &&
            studentUid.isNotEmpty) {
          final lockSnap = await transaction.get(lockRef);
          final dynamic raw = lockSnap.data();
          final Map<String, dynamic> lockData = raw is Map<String, dynamic>
              ? raw
              : <String, dynamic>{};
          final String lockedSponsorUid = (lockData['sponsorUid'] ?? '')
              .toString()
              .trim();

          if (lockedSponsorUid.isNotEmpty && lockedSponsorUid != sponsorUid) {
            throw StateError(
              'This student is already assigned to another sponsor.',
            );
          }

          final String sponsorshipId = '${sponsorUid}_$studentUid';
          final sponsorshipRef = FirebaseFirestore.instance
              .collection('sponsorships')
              .doc(sponsorshipId);

          transaction.set(lockRef, {
            'studentUid': studentUid,
            'sponsorUid': sponsorUid,
            'status': 'active',
            'sourceRequestId': requestId,
            'updatedAt': FieldValue.serverTimestamp(),
            if (!lockSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          transaction.set(sponsorshipRef, {
            'sponsorUid': sponsorUid,
            'studentUid': studentUid,
            'studentName': (data['studentName'] ?? 'Student').toString(),
            'studentGrade': (data['studentGrade'] ?? 'N/A').toString(),
            'studentDistrict': (data['studentDistrict'] ?? 'N/A').toString(),
            'studentPoints':
                int.tryParse((data['studentPoints'] ?? '0').toString()) ?? 0,
            'studentScore':
                int.tryParse((data['studentPoints'] ?? '0').toString()) ?? 0,
            'sourceRequestId': requestId,
            'status': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        transaction.set(requestRef, {
          'status': normalizedStatus,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'type': 'sponsorship_review',
        'title': 'Request ${normalizedStatus.toUpperCase()}',
        'message':
            '${(data['studentName'] ?? 'Student').toString()} sponsorship request ${normalizedStatus.toLowerCase()}.',
        'requestId': requestId,
        'sponsorUid': sponsorUid,
        'studentUid': studentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${normalizedStatus.toUpperCase()}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1C2E),
        title: const Text(
          'Sponsorship Requests',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sponsorship_requests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }

          final requests =
              snapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['status'] ?? 'pending')
                    .toString()
                    .toLowerCase();
                return status == 'pending';
              }).toList() ??
              [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending sponsorship requests.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              final String name = (data['studentName'] ?? 'Student')
                  .toString()
                  .trim();
              final String grade = (data['studentGrade'] ?? 'N/A')
                  .toString()
                  .trim();
              final String district = (data['studentDistrict'] ?? 'N/A')
                  .toString()
                  .trim();
              final String points = (data['studentPoints'] ?? '0')
                  .toString()
                  .trim();

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9EEFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFF5C71D1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name.isEmpty ? 'Student' : name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1C2E),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$points pts',
                            style: const TextStyle(
                              color: Color(0xFF3730A3),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grade: $grade • District: $district',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _updateRequestStatus(
                              context: context,
                              requestId: doc.id,
                              data: data,
                              nextStatus: 'rejected',
                            ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _updateRequestStatus(
                              context: context,
                              requestId: doc.id,
                              data: data,
                              nextStatus: 'approved',
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
