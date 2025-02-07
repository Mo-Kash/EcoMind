import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';


class GeminiService {
  static const String apiKey = "AIzaSyCZbXtaL-URxWSEE3uPkRWLsEjRe3mz7gA";
  static const String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey";

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {"parts": [{"text": message}]}
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