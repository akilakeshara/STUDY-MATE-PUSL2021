import 'package:flutter/material.dart';

class TeacherVerifiedScreen extends StatelessWidget {
  final String teacherName;

  const TeacherVerifiedScreen({super.key, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              _buildIllustration(),

              const SizedBox(height: 50),

              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF66BB6A),
                child: Icon(Icons.check, color: Colors.white, size: 35),
              ),

              const SizedBox(height: 25),

              const Text(
                "Application Approved!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                "$teacherName's account\nhas successfully activated.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C71D1),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Return to Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Center(
      child: SizedBox(
        height: 220,

        child: Image.network(
          'https://i.imgur.com/rD898G7.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
