import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../config/api_config.dart';

class AiVisionService {
  final GenerativeModel _model;

  AiVisionService()
      : _model = GenerativeModel(
          model: 'gemini-3.6-flash',
          apiKey: ApiConfig.geminiApiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

  /// Analyzes an image of food and returns a list of identified ingredients with estimated macros.
  Future<Map<String, dynamic>?> analyzeFoodImage(Uint8List imageBytes) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY' || ApiConfig.geminiApiKey.isEmpty) {
      throw Exception('FoodGapp AI Key not set');
    }

    final prompt = '''
You are a clinical dietitian. Analyze this image of food and return a structured JSON response.

Instructions:
1. Identify all food items visible in the image.
2. Estimate the portion weight in grams (g) for each item.
3. Provide accurate Calories (kcal), Protein (g), Carbohydrates (g), and Fat (g) for each item.
4. Suggest a clear "foodName" for the entire plate.

CRITICAL: Return RAW JSON only.

Expected Response Format:
{
  "foodName": "...",
  "ingredients": [
    {
      "name": "...",
      "amount": 100.0,
      "unit": "g",
      "calories": 150.0,
      "protein": 10.0,
      "carbs": 5.0,
      "fat": 5.0,
      "isVerified": true,
      "source": "FoodGapp AI Vision"
    }
  ]
}
''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      String? jsonString = _sanitizeJson(response.text);
      if (jsonString == null) return null;

      return jsonDecode(jsonString);
    } catch (e) {
      print('AI Vision Error: $e');
      return null;
    }
  }

  String? _sanitizeJson(String? input) {
    if (input == null) return null;
    String clean = input;
    if (clean.contains('```')) {
      clean = clean.replaceAll(RegExp(r'```(?:json)?'), '').trim();
    }
    return clean.trim();
  }
}
