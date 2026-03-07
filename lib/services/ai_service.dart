import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/dare_model.dart';
import '../models/dare_verification_result.dart';

class AiService {
  static const _apiKey = 'AIzaSyAQgip4g40BuQmwN9Trp6malJfd2KZONw0';
  static const _model = 'gemma-3-27b-it';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Calls Gemini API directly to generate a personalized dare
  Future<DareModel> generatePersonalizedDare(List<String> interests, String difficulty) async {
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final prompt = '''
You are a dare challenge generator for a social app called DareDay.
Generate ONE fun, safe, creative dare for the difficulty level: $difficulty.
Interests to incorporate: ${interests.join(', ')}.

Respond ONLY with valid JSON in this exact format:
{
  "title": "Short catchy dare title (max 5 words)",
  "instructions": "One brief sentence for completing the dare.",
  "difficulty": "$difficulty",
  "category": "${interests.first}",
  "xp_reward": 10,
  "gem_reward": 0
}

Rules:
- Keep it safe and appropriate for all ages.
- Title must be VERY simple and catchy.
- Instructions must be brief and under 15 words.
- ONLY Hard difficulty dares get "gem_reward": 1. All others must be 0.
- NEVER mention your AI model name or version in the response.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      }
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('Gemini API error (${response.statusCode}): $responseBody');
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      
      if (json['candidates'] == null || (json['candidates'] as List).isEmpty) {
        throw Exception('Gemini returned no candidates. Full response: $responseBody');
      }
      
      final candidate = json['candidates'][0] as Map<String, dynamic>;
      if (candidate['content'] == null || candidate['content']['parts'] == null) {
        throw Exception('Gemini candidate has no content. Full response: $responseBody');
      }
      
      final text = candidate['content']['parts'][0]['text'] as String;
      debugPrint('Gemini Raw Response: $text');

      // --- ULTRA ROBUST JSON EXTRACTION ---
      String cleanedText = text.trim();
      
      // 1. Try to find the first '{' and the last '}'
      final firstBrace = cleanedText.indexOf('{');
      final lastBrace = cleanedText.lastIndexOf('}');
      
      if (firstBrace == -1 || lastBrace == -1) {
        throw FormatException('No JSON object found. Raw text: $text');
      }
      
      if (firstBrace == lastBrace) {
         throw FormatException('Response appears truncated or invalid (only one brace found). Raw text: $text');
      }
      
      cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);

      Map<String, dynamic> dareJson;
      try {
        dareJson = jsonDecode(cleanedText) as Map<String, dynamic>;
      } catch (e) {
        // 2. If simple substring fails, try stripping markdown more aggressively
        try {
          final regex = RegExp(r'\{[\s\S]*\}', multiLine: true);
          final match = regex.stringMatch(text);
          if (match != null) {
            dareJson = jsonDecode(match) as Map<String, dynamic>;
          } else {
            rethrow;
          }
        } catch (e2) {
          throw FormatException('Invalid JSON format. The AI response might be too long. Raw text: $text\nParse error: $e');
        }
      }

      // Add required fields for DareModel
      dareJson['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      dareJson['created_at'] = DateTime.now().toIso8601String();
      
      // Calculate reward points based on difficulty and weekend multiplier
      int basePoints = difficulty == 'Easy' ? 3 : (difficulty == 'Medium' ? 5 : 10);
      final now = DateTime.now();
      final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
      dareJson['xp_reward'] = isWeekend ? basePoints * 2 : basePoints;
      
      dareJson['title'] ??= 'New Challenge';
      dareJson['instructions'] ??= 'Follow the instructions provided.';
      dareJson['difficulty'] ??= difficulty;
      dareJson['gem_reward'] ??= (difficulty == 'Hard' ? 1 : 0);

      return DareModel.fromJson(dareJson);
    } catch (e) {
      debugPrint('Error in generatePersonalizedDare: $e');
      if (e is FormatException) {
         throw Exception('AI Response Error: The challenge data was incomplete. Please try again.\n${e.message}');
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Verifies if a custom dare is safe, fair, and appropriate
  Future<bool> verifyCustomDare(String title, String instructions) async {
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
    
    final prompt = '''
    You are a safety moderator for DareDay. Verify this dare:
    Title: $title
    Instructions: $instructions
    
    Rules: Safe, Legal, Appropriate, Realistic.
    Return JSON only: { "is_safe": true/false }
    ''';

    final body = jsonEncode({
      'contents': [{'parts': [{'text': prompt}]}],
      'generationConfig': {'temperature': 0.1}
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.write(body);
      final response = await request.close();
      if (response.statusCode != 200) return false;
      
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      
      // --- ROBUST JSON EXTRACTION ---
      String cleanedText = text.trim();
      final firstBrace = cleanedText.indexOf('{');
      final lastBrace = cleanedText.lastIndexOf('}');
      
      if (firstBrace == -1 || lastBrace == -1) return false;
      
      cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);
      final result = jsonDecode(cleanedText) as Map<String, dynamic>;
      return result['is_safe'] == true;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Uses Gemini Vision to verify a dare proof from video frames
  Future<DareVerificationResult> verifyDareProof({
    required String title,
    required String instructions,
    required List<Uint8List> frames,
    Uint8List? audioData,
  }) async {
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final prompt = '''
You are the "Dare Guard" AI for DareDay. Your job is to verify if a user's video proof matches the dare they were assigned.

DARE TITLE: $title
DARE INSTRUCTIONS: $instructions

I have provided both visual frames from the video AND the audio track.
Examine BOTH carefully:
1. What do you see in the images?
2. What do you hear in the audio? (Check for speech, keyword detection, or specific sounds matching the instructions).
3. Determine if the combination of visual and audio evidence accurately fulfills the dare.
4. Assign a "relevance_score" from 0 to 100.

Respond ONLY with valid JSON in this exact format:
{
  "description": "A detailed 1-sentence description of the video and audio content.",
  "relevance_score": 85,
  "reasoning": "Explain your score based on both visual and audio evidence."
}
''';

    final List<Map<String, dynamic>> parts = [
      {'text': prompt}
    ];

    // Add audio if available
    if (audioData != null) {
      parts.add({
        'inlineData': {
          'mimeType': 'audio/aac',
          'data': base64Encode(audioData),
        }
      });
    }

    // Add image frames
    for (final frame in frames) {
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Encode(frame),
        }
      });
    }

    final body = jsonEncode({
      'contents': [
        {
          'parts': parts
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
      }
    });

    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        debugPrint('Gemini Vision API Error: HTTP ${response.statusCode}');
        debugPrint('Response Body: $responseBody');
        throw Exception('Vision API Error (${response.statusCode}): $responseBody');
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      if (json['candidates'] == null || (json['candidates'] as List).isEmpty) {
        debugPrint('Gemini Vision API Empty Response: $responseBody');
        throw Exception('AI returned no analysis candidates.');
      }

      final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
      debugPrint('Gemini Vision Raw Response: $text');
      
      // --- ROBUST JSON EXTRACTION ---
      String cleanedText = text.trim();
      final firstBrace = cleanedText.indexOf('{');
      final lastBrace = cleanedText.lastIndexOf('}');
      
      if (firstBrace == -1 || lastBrace == -1) {
        throw FormatException('No JSON object found in AI response.');
      }
      
      cleanedText = cleanedText.substring(firstBrace, lastBrace + 1);
      final resultJson = jsonDecode(cleanedText) as Map<String, dynamic>;
      return DareVerificationResult.fromJson(resultJson);
    } catch (e) {
      debugPrint('DEBUG: Error in verifyDareProof: $e');
      if (e is Exception) rethrow;
      throw Exception('Verification Error: ${e.toString()}');
    } finally {
      client.close();
    }
  }
}
