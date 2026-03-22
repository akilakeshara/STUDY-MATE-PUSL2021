import 'package:flutter/material.dart';

class SponsorshipSuccessScreen extends StatelessWidget {
  const SponsorshipSuccessScreen({super.key});

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
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sponsorship Successful!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),

                _buildSuccessDetailCard(),

                const SizedBox(height: 30),

                _buildStatusBanner(
                  "Sponsored Device: Laptop (LKR 85,000)",
                  Colors.blue.shade50,
                  Colors.blue.shade700,
                  Icons.laptop,
                ),

                const SizedBox(height: 15),

                _buildStatusBanner(
                  "Administrator Verified & Device Dispatched",
                  Colors.green.shade50,
                  Colors.green.shade700,
                  Icons.verified_user,
                ),

                const SizedBox(height: 40),
                const Text(
                  "Note: No direct payment processed here. This is at\nis commitment to fund.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildSuccessDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 40),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C1E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Column(
                  children: [
                    Text(
                      "178",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      "Scholarship Exam Score\nEligibility for Devices: YES",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            "Your generous sponsorship for Amara\nPerera has been fully processed. The device\ndevice is on their way!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    String text,
    Color bgColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
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
