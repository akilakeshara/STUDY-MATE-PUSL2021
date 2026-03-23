import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Imported to load environment variables securely

class AITutorService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  AITutorService() {
    // Retrieve the API key from the .env file (Removed hardcoded key for security)
    final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
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
      // Handle API Limit Exceeded or AI-specific errors
      print("Gemini API Error: $e");
      return "Many students are asking questions at this time. Please ask again in about 30 seconds! ⏳";
       
    } catch (e) {
      // Handle network or other general errors
      print("General Error: $e");
      return "Sorry, please check your internet connection. 📶";
    }
  }
}