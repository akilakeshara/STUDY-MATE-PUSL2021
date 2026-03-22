import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'class_selection_screen.dart';
import '../../core/page_transition.dart';

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
      "title": "24/7 AI Tutor",
      "text":
          "Get instant help with your studies anytime, anywhere. Our smart AI Tutor is available 24/7 to answer your questions.",
      "image":
          "https://img.freepik.com/free-vector/female-student-listening-webinar-online_74855-6474.jpg",
    },
    {
      "title": "Earn Rewards",
      "text":
          "Turn your spare time into rewards! Complete simple mini-jobs like educational puzzles to earn virtual coins.",
      "image":
          "https://img.freepik.com/free-vector/freelancer-working-laptop-her-house_23-2148635192.jpg",
    },
    {
      "title": "Device Sponsorship",
      "text":
          "High marks deserve high rewards. Apply for our device sponsorship program and get the technology you need.",
      "image":
          "https://img.freepik.com/free-vector/business-woman-working-laptop-desk_23-2148230694.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) => _buildPage(index),
            ),

            Positioned(
              bottom: 20 + bottomInset,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 8,
                          width: i == _currentPage ? 24 : 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? const Color(0xFF5C71D1)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C71D1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_currentPage == 2) {
                            Navigator.pushReplacement(
                              context,
                              PageTransition(
                                child: const ClassSelectionScreen(),
                              ),
                            );
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == 2 ? "GET STARTED" : "NEXT",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage < 2) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          PageTransition(child: const ClassSelectionScreen()),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double reservedBottom = 200 + bottomInset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double headerHeight = (constraints.maxHeight * 0.44).clamp(
          250.0,
          380.0,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: reservedBottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: headerHeight,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(100),
                          bottomRight: Radius.circular(100),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildPageIllustration(index),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _onboardingData[index]["title"]!,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1C2E),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _onboardingData[index]["text"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[400],
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIllustration(int index) {
    final String assetPath = switch (index) {
      0 => 'assets/images/onboarding_page3_primary.svg',
      1 => 'assets/images/onboarding_page3_secondary.svg',
      2 => 'assets/images/onboarding_page3_primary.svg',
      _ => '',
    };

    if (assetPath.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          _onboardingData[index]["image"]!,
          height: 280,
          fit: BoxFit.contain,
        ),
      );
    }

    return _buildSvgIllustration(assetPath: assetPath);
  }

  Widget _buildSvgIllustration({required String assetPath}) {
    return SizedBox(
      height: 280,
      width: 260,
      child: Center(
        child: SvgPicture.asset(assetPath, width: 220, fit: BoxFit.contain),
      ),
    );
  }
}
