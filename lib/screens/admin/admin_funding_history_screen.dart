import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminFundingHistoryScreen extends StatelessWidget {
  const AdminFundingHistoryScreen({super.key});

  String _formatDate(DateTime dateTime) {
    final String dd = dateTime.day.toString().padLeft(2, '0');
    final String mm = dateTime.month.toString().padLeft(2, '0');
    final String yyyy = dateTime.year.toString();
    return '$yyyy-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Funded Sponsors',
          style: TextStyle(
            color: Color(0xFF1A1C2E),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('study_mate_funding_payments')
            .where('status', isEqualTo: 'simulated_paid')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5C71D1)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No completed funding records yet.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final List<Map<String, dynamic>> rows = snapshot.data!.docs.map((
            doc,
          ) {
            final dynamic raw = doc.data();
            final Map<String, dynamic> data = raw is Map<String, dynamic>
                ? raw
                : <String, dynamic>{};
            final dynamic timestamp =
                data['simulatedPaidAt'] ?? data['createdAt'];
            final DateTime paidAt = timestamp is Timestamp
                ? timestamp.toDate()
                : DateTime(1970);
            return {
              'paymentId': (data['paymentId'] ?? doc.id).toString(),
              'sponsorName': (data['sponsorName'] ?? 'Sponsor').toString(),
              'sponsorID': (data['sponsorID'] ?? '').toString(),
              'method': (data['method'] ?? 'N/A').toString(),
              'amountLkr': (data['amountLkr'] as num?)?.toDouble() ?? 0,
              'paidAt': paidAt,
            };
          }).toList();

          rows.sort(
            (a, b) =>
                (b['paidAt'] as DateTime).compareTo(a['paidAt'] as DateTime),
          );

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = rows[index];
              final String sponsorId = (row['sponsorID'] as String).trim();

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9EEFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row['sponsorName'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1C2E),
                            ),
                          ),
                        ),
                        Text(
                          'LKR ${(row['amountLkr'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sponsor ID: ${sponsorId.isEmpty ? 'N/A' : sponsorId}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Method: ${row['method']}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Paid Date: ${_formatDate(row['paidAt'] as DateTime)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
