import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class StudentMiniJobsScreen extends StatefulWidget {
  const StudentMiniJobsScreen({super.key});

  @override
  State<StudentMiniJobsScreen> createState() => _StudentMiniJobsScreenState();
}

class _StudentMiniJobsScreenState extends State<StudentMiniJobsScreen> {
  final List<Map<String, dynamic>> _jobs = [
    {
      'title': 'Invoice Verification',
      'category': 'Data Entry',
      'points': 15,
      'time': '2-3 mins',
      'icon': Icons.description_rounded,
      'color': const Color(0xFF5C71D1),
      'description': 'Verify details on product invoices matches digital records.',
    },
    {
      'title': 'Image Tagging',
      'category': 'AI Training',
      'points': 10,
      'time': '1 min',
      'icon': Icons.image_search_rounded,
      'color': const Color(0xFF2EBD85),
      'description': 'Tag objects in images to help improve our AI tutor.',
    },
    {
      'title': 'Short Audio Transcribe',
      'category': 'Transcription',
      'points': 25,
      'time': '5 mins',
      'icon': Icons.audiotrack_rounded,
      'color': const Color(0xFFF3A31D),
      'description': 'Type out a 30-second educational clip for better accessibility.',
    },
    {
      'title': 'Subject Classification',
      'category': 'Organization',
      'points': 12,
      'time': '1 min',
      'icon': Icons.category_rounded,
      'color': const Color(0xFFE91E63),
      'description': 'Sort questions into their correct academic subjects.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Mini Jobs Center",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackgroundDecorations(theme, isDark),
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(22),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: _buildBanner(theme),
                      ),
                      const SizedBox(height: 30),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          "Available Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = _jobs[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: Duration(milliseconds: 100 * index),
                        child: _buildJobCard(job, theme),
                      );
                    },
                    childCount: _jobs.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations(ThemeData theme, bool isDark) {
    final primaryColor = theme.colorScheme.primary;
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(isDark ? 0.08 : 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C71D1), Color(0xFF4354B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C71D1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Earn While Learning",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Complete small tasks and earn points for your education rewards.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, ThemeData theme) {
    final color = job['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showJobDetails(job),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(job['icon'], color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              job['category'].toString().toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFF3A31D), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "${job['points']} Pts",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFFF3A31D),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        job['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            job['time'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "Start Job",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: (job['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: Icon(job['icon'], color: job['color'], size: 32),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                            Text(job['category'], style: TextStyle(color: (job['color'] as Color), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("Job Requirements", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    _buildRequirementRow("Device with stable internet connection"),
                    _buildRequirementRow("Basic understanding of the subject"),
                    _buildRequirementRow("Accuracy is critical for point earning"),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Starting job session... Prepere your workspace!")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text("Accept & Start", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
  }

  Widget _buildRequirementRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2EBD85), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
        ],
      ),
    );
  }
}
