import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  print('Starting Gemini API test...');

  // 1. Read the API key from .env manually (since we are not in Flutter context)
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found!');
    return;
  }

  final lines = envFile.readAsLinesSync();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
    print('Error: Valid GEMINI_API_KEY not found in .env file.');
    return;
  }

  print('API Key found. Initializing Gemini model...');

  // 2. Initialize Gemini Model
  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  // 3. Send a test prompt
  final prompt = 'Respond with "Yes, Gemini is working perfectly!" if you receive this message.';
  print('Sending prompt: "\$prompt"');

  try {
    final response = await model.generateContent([Content.text(prompt)]);
    print('\n=== GEMINI RESPONSE ===');
    print(response.text);
    print('=======================\n');
    print('Test successful! Gemini is ready to be used in your Flutter app.');
  } catch (e) {
    print('\nError communicating with Gemini:');
    print(e.toString());
  }
}
