import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sponsorship_success_screen.dart';

class ConfirmSponsorshipScreen extends StatelessWidget {
  const ConfirmSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(context),

          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confirm Your Sponsorship",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildStudentMiniCard(),

                const SizedBox(height: 15),
                const Text(
                  "Confirm your sponsorship for Amara Perera",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                _buildActionButton(
                  context,
                  "Fund a Laptop (LKR 85,000)",
                  const Color(0xFFE67E22),
                  Icons.laptop,
                  85000.0,
                  "Laptop",
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  context,
                  "Fund a Mobile Phone (LKR 30,000)",
                  const Color(0xFF5C71D1),
                  Icons.smartphone,
                  30000.0,
                  "Mobile Phone",
                ),

                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "Note: No direct payment processed here. This is at\nis commitment to fund.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF5C71D1),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Center(
              child: Text(
                "SPONSOR DASHBOARD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentMiniCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Amara Perera",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Grade: 8",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Text(
                  "District: Colombo",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  "178",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "Eligibility for Devices: YES",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordSponsorship(
    BuildContext context, {
    required double amount,
    required String item,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('sponsor_payments').add({
        'sponsorUid': user.uid,
        'studentName': 'Amara Perera', // Keep for now as it matches the mockup
        'studentId': 'STU-0012',
        'amount': amount,
        'item': item,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SponsorshipSuccessScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
    double amount,
    String item,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => _recordSponsorship(context, amount: amount, item: item),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home_outlined, color: Colors.grey, size: 28),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment, color: Color(0xFF5C71D1), size: 28),
              Text(
                "Dashboard",
                style: TextStyle(color: Color(0xFF5C71D1), fontSize: 10),
              ),
            ],
          ),
          Icon(Icons.person_outline, color: Colors.grey, size: 28),
        ],
      ),
    );
  }
}
