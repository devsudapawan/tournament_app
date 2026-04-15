// lib/data/datasources/local/mlkit_ocr_service.dart
//
// Wraps Google ML Kit Text Recognition.
// Takes a File → returns raw extracted text string.
// Runs fully on-device. Free. No quota. No internet needed.

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitOcrService {
  // Latin script recognizer — covers all BGMI/PUBG player name characters
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts all visible text from [image].
  /// Returns empty string if recognition fails or finds nothing.
  Future<String> extractText(File image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final result     = await _recognizer.processImage(inputImage);

      // Join all text blocks with newlines — preserves layout structure
      // which helps Gemini understand row-based game UI
      final buffer = StringBuffer();
      for (final block in result.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      return buffer.toString().trim();
    } catch (_) {
      // If ML Kit fails for any reason → return empty string
      // GeminiService will then fall back to vision mode
      return '';
    }
  }

  /// Call this when the service is no longer needed
  /// to release native ML Kit resources.
  void dispose() {
    _recognizer.close();
  }
}