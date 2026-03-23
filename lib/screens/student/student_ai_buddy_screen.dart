import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_tutor_service.dart';

class StudentAiBuddyScreen extends StatefulWidget {
  const StudentAiBuddyScreen({super.key});

  @override
  State<StudentAiBuddyScreen> createState() => _StudentAiBuddyScreenState();
}

class _StudentAiBuddyScreenState extends State<StudentAiBuddyScreen> {
  final AITutorService _aiTutorService = AITutorService();
  final user = FirebaseAuth.instance.currentUser;

  // List to store chat messages
  final List<ChatMessage> _messages = [];

  // Current user (Student) profile
  late ChatUser _currentUser;

  // AI Bot profile
  final ChatUser _aiBot = ChatUser(
    id: 'ai_buddy',
    firstName: 'AI Buddy',
    profileImage:
        'https://cdn-icons-png.flaticon.com/512/4712/4712010.png', // Robot icon
  );

  @override
  void initState() {
    super.initState();
    _currentUser = ChatUser(id: user?.uid ?? 'student_id', firstName: 'You');

    // Initial welcome message from AI Buddy
    _messages.add(
      ChatMessage(
        text: "Hi! I am AI Buddy 🤖. Ask me anything about your studies.",
        user: _aiBot,
        createdAt: DateTime.now(),
      ),
    );
  }

  // Function to handle sending messages
  Future<void> _handleSend(ChatMessage message) async {
    // 1. Add the student's message to the UI
    setState(() {
      _messages.insert(0, message);
    });

    try {
      // 2. Get the response from Gemini AI
      final response = await _aiTutorService.askQuestion(message.text);

      // 3. Create the AI's response message
      final botMessage = ChatMessage(
        text: response,
        user: _aiBot,
        createdAt: DateTime.now(),
      );

      // 4. Add the AI's message to the UI
      setState(() {
        _messages.insert(0, botMessage);
      });
    } catch (e) {
      debugPrint("AI Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "AI Buddy",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF5C71D1),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // DashChat handles the entire chat UI
      body: DashChat(
        currentUser: _currentUser,
        onSend: _handleSend,
        messages: _messages,
        messageOptions: MessageOptions(
          currentUserContainerColor: const Color(
            0xFF5C71D1,
          ), // Student message bubble color
          containerColor: Theme.of(
            context,
          ).cardColor, // AI message bubble color
          textColor: Theme.of(context).colorScheme.onSurface,
        ),
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: "Ask AI Buddy...",
            filled: true,
            fillColor: const Color(0xFFF6F8FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
