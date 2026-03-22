import 'package:google_generative_ai/google_generative_ai.dart';

class AITutorService {
  // API SELECT
  static const String _apiKey = 'AIzaSyABGJqjKwpO9VBtpcch_iIvy4sowupOBkM';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  AITutorService() {
    // 
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        "You are 'Study Mate AI Tutor', an educational assistant for Sri Lankan Grade 9-13 students. "
        "Strictly answer only questions related to Mathematics, English Language, and IT/ICT based on the Sri Lankan syllabus. "
        "If asked about anything else, politely decline. "
        "Provide step-by-step math solutions. Use simple English or Sinhala as appropriate for the student's prompt."
      ),
    );

    _chatSession = _model.startChat();
  }

  Future<String> askQuestion(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? "Sorry I Can't Understand, Can You Say it again?";
      
    } on GenerativeAIException catch (e) {
      // API LIMIT
      print("Gemini API Error: $e");
      return "Many Children arew Asking Qustions at this time.Ask again in about 30 seconds! ⏳";
       
    } catch (e) {
      // Other Errors
      print("General Error: $e");
      return "Sorry, Please Check your Internet Connection. 📶";
    }
  }
} 