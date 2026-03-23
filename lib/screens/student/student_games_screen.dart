import 'package:flutter/material.dart';
import 'puzzle_game_screen.dart';
import 'memory_match_game_screen.dart';
import 'knowledge_arena_screen.dart';

class StudentGamesScreen extends StatelessWidget {
  const StudentGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Learning Games',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF5C71D1), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildGameCard(
            context,
            title: "Subject Master",
            subtitle: "Science, ICT & Logic Challenge",
            icon: Icons.psychology_rounded,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PuzzleGameScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            context,
            title: "Memory Match",
            subtitle: "Find the matching pairs",
            icon: Icons.psychology_rounded,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MemoryMatchGameScreen()),
            ),
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            context,
            title: "Knowledge Arena",
            subtitle: "Test your skills with timers, streaks & lifelines!",
            icon: Icons.psychology_rounded,
            color: const Color(0xFF6B21A8), // Premium Purple
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KnowledgeArenaScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _PressableScaleWrapper(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(right: -15, top: -15, child: Icon(icon, size: 80, color: color.withOpacity(0.05))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: color.withOpacity(0.4),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressableScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScaleWrapper({required this.child, required this.onTap});

  @override
  State<_PressableScaleWrapper> createState() => _PressableScaleWrapperState();
}

class _PressableScaleWrapperState extends State<_PressableScaleWrapper> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        child: widget.child,
      ),
    );
  }
}
