import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = "AIzaSyCZbXtaL-URxWSEE3uPkRWLsEjRe3mz7gA";
  static const String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey";

  // Greeting and thank-you intents
  static final Map<String, String> predefinedResponses = {
    "hi": "Hello! How can I help you with waste management and recycling today?",
    "hello": "Hi there! Ask me anything about waste disposal, recycling, or sustainability.",
    "hey": "Hey! I'm here to assist you with waste management topics.",
    "good morning": "Good morning! Let’s talk about eco-friendly waste solutions.",
    "good evening": "Good evening! Need tips on recycling? I’ve got you covered.",
    "thank you": "You're welcome! Keep up the great work for a greener planet!",
    "thanks": "No problem! Let me know if you have more waste-related questions.",
  };

  // Function to check if the message is a greeting or thank-you intent
  static String? checkPredefinedResponse(String message) {
    String normalizedMessage = message.toLowerCase().trim();
    return predefinedResponses[normalizedMessage];
  }

  // Function to classify whether the query is about waste management
  static Future<bool> isWasteManagementQuestion(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Classify the following query as 'Waste Management' or 'Other'. If it relates to waste disposal, recycling, composting, sustainability, or environmental waste management, return 'Waste Management'. Otherwise, return 'Other'.\n\nQuery: $message"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String classification = data['candidates'][0]['content']['parts'][0]['text'].trim();
        return classification == "Waste Management";
      }
    } catch (e) {
      return false; // Default to rejecting off-topic questions if there's an error.
    }
    return false;
  }

  static Future<String> sendMessage(String message) async {
    // Check if the message is a greeting or thank-you intent
    String? predefinedResponse = checkPredefinedResponse(message);
    if (predefinedResponse != null) {
      return predefinedResponse;
    }

    // Classify if the question is related to waste management
    bool isRelevant = await isWasteManagementQuestion(message);
    if (!isRelevant) {
      return "I can only assist with waste management and recycling topics. Please ask about waste disposal, recycling, composting, or sustainability.";
    }

    // Process the relevant waste management question
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "You are an expert in waste management. Answer only questions related to recycling, waste disposal, composting, and sustainability.\n\nUser: $message"
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Error: ${response.body}";
      }
    } catch (e) {
      return "Failed to connect: $e";
    }
  }
}
