import 'package:flutter/material.dart';
import 'package:computing_group_project/screens/student/class_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "text":
          "Get instant help with your studies anytime, anywhere. Our smart AI Tutor is available 24/7 to answer your questions in Mathematics, Science, and more, helping you master the local syllabus.",
      "image":
          "https://img.freepik.com/free-vector/female-student-listening-webinar-online_74855-6474.jpg",
    },
    {
      "text":
          "Turn your spare time into rewards! Complete simple mini-jobs like educational puzzles and data entry to earn virtual coins and build your student profile.",
      "image":
          "https://img.freepik.com/free-vector/freelancer-working-laptop-her-house_23-2148635192.jpg",
    },
    {
      "text":
          "High marks deserve high rewards. If you have a scholarship score over 160, apply for our device sponsorship program and get the technology you need to succeed.",
      "image":
          "https://img.freepik.com/free-vector/business-woman-working-laptop-desk_23-2148230694.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) => _buildPage(index),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C71D1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_currentPage == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClassSelectionScreen(),
                          ),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == 2 ? "Let's Make a Journey" : "Next",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                if (_currentPage < 2)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClassSelectionScreen(),
                      ),
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: Color(0xFF5C71D1)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.55,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF3B5998),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(200),
                  bottomRight: Radius.circular(200),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _onboardingData[index]["image"]!,
                  height: 250,
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            _onboardingData[index]["text"]!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: i == _currentPage ? 30 : 10,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? const Color(0xFF5C71D1)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
