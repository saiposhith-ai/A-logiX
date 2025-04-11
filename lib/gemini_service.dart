import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'];
  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey!,
  );

  static Future<String> sendMessage({required String text, File? image}) async {
    final parts = <Part>[
      TextPart(text),
    ];

    if (image != null) {
      final bytes = await image.readAsBytes();
      parts.add(
        DataPart('image/jpeg', bytes),
      );
    }

    // ✅ Use Content.multi to create Content from parts
    final prompt = Content.multi(parts);

    // ✅ Wrap in a list for generateContent
    final response = await _model.generateContent([prompt]);

    return response.text ?? '[No response]';
  }
}
