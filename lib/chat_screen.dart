import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'gemini_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  File? _pickedImage;
  bool _isLoading = false;

  Map<String, String> _nutrients = {};

  void _analyzeImage() async {
    if (_pickedImage == null) return;

    const prompt = '''
Analyze this image and provide the total estimated nutritional information of the food shown. Only include the following values:  
- Calories (kcal)  
- Protein (g)  
- Fats (g)  
- Carbohydrates (g)  
- Fiber (g)

Do not include ingredients or extra details. Just return the values clearly.
''';

    setState(() {
      _isLoading = true;
      _nutrients.clear();
    });

    final response = await GeminiService.sendMessage(
      text: prompt,
      image: _pickedImage,
    );

    _parseNutrients(response);

    setState(() {
      _isLoading = false;
    });
  }

  void _parseNutrients(String response) {
    final lines = response.split('\n');
    final Map<String, String> result = {};

    for (var line in lines) {
      if (line.toLowerCase().contains('calories')) {
        result['Calories'] = _extractValue(line) + ' kcal';
      } else if (line.toLowerCase().contains('protein')) {
        result['Protein'] = _extractValue(line) + ' g';
      } else if (line.toLowerCase().contains('fats') || line.toLowerCase().contains('fat')) {
        result['Fats'] = _extractValue(line) + ' g';
      } else if (line.toLowerCase().contains('carbohydrates')) {
        result['Carbohydrates'] = _extractValue(line) + ' g';
      } else if (line.toLowerCase().contains('fiber')) {
        result['Fiber'] = _extractValue(line) + ' g';
      }
    }

    setState(() {
      _nutrients = result;
    });
  }

  String _extractValue(String line) {
    final match = RegExp(r'[\d.]+').firstMatch(line);
    return match?.group(0) ?? 'N/A';
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
      _analyzeImage();
    }
  }

  Widget _buildNutrientTile(String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.health_and_safety),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (_pickedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.file(_pickedImage!, height: 200),
              ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_nutrients.isNotEmpty)
              Expanded(
                child: ListView(
                  children: _nutrients.entries.map((entry) {
                    return _buildNutrientTile(entry.key, entry.value);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
