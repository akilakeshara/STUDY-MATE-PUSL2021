import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  final String studentName;
  final String score;

  const StudentProfileScreen({
    super.key,
    required this.studentName,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _buildSummaryCard(),

                  const SizedBox(height: 20),

                  _buildAcademicPerformanceCard(),

                  const SizedBox(height: 20),

                  _buildProgressCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
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
            Positioned(
              left: 10,
              top: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop,
              ),
            ),
            const Center(
              child: Text(
                "STUDENT PROFILE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text("Grade: 8", style: TextStyle(color: Colors.grey)),
                const Text(
                  "District: Colombo",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          _buildScoreBadge(),
        ],
      ),
    );
  }

  Widget _buildScoreBadge() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C1E),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                score,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Scholarship Exam Score",
                style: TextStyle(color: Colors.white54, fontSize: 8),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "YES",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(80, 35),
          ),
          child: const Text(
            "Contact",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicPerformanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Academic Performance & Need",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDummyChart(Icons.show_chart, Colors.blue),
              _buildDummyChart(Icons.donut_large, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Essay Grade: A-",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Teacher Notes:\nVerified low-income household.\nApplying for device support.",
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDummyChart(IconData icon, Color color) {
    return Container(
      height: 80,
      width: 100,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, size: 50, color: color),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Science (Grade 8: 7% Completed)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.07,
              backgroundColor: Color(0xFFF0F0F0),
              color: Color(0xFF5C71D1),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Progress on Sponsored Courses",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          const Text(
            "Math (Grade 8: 7% Completed)",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Text(
            "Science (Grade 7: 7% Completed)",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
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
          Icon(Icons.home_filled, color: Color(0xFF5C71D1), size: 30),
          Icon(Icons.book_outlined, color: Colors.grey, size: 30),
          Icon(Icons.person_outline, color: Colors.grey, size: 30),
        ],
      ),
    );
  }
}
