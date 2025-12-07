import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

class MLService {
  final ImageLabeler _imageLabeler = ImageLabeler(options: ImageLabelerOptions());

  // Category mapping: maps app categories to expected ML labels
  static const Map<String, List<String>> _categoryKeywords = {
    'road': ['road', 'street', 'asphalt', 'highway', 'pavement', 'path', 'lane', 'sidewalk', 'pothole', 'crack'],
    'water': ['water', 'pipe', 'plumbing', 'leak', 'tap', 'faucet', 'drain', 'sewer', 'puddle', 'flood'],
    'electricity': ['wire', 'cable', 'pole', 'electric', 'light', 'lamp', 'power', 'transformer', 'meter', 'switch'],
    'garbage': ['trash', 'garbage', 'waste', 'litter', 'dump', 'rubbish', 'debris', 'dirt', 'pollution', 'bin'],
  };

  /// Validates if the image matches the selected category
  /// Returns a Map with 'isValid' (bool) and 'confidence' (double) and 'detectedLabels' (List<String>)
  Future<Map<String, dynamic>> validateImageCategory(XFile imageFile, String selectedCategory) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final labels = await _imageLabeler.processImage(inputImage);

      // Get detected label texts
      final detectedLabels = labels.map((label) => label.label.toLowerCase()).toList();
      
      // If category is 'others', always return valid
      if (selectedCategory.toLowerCase() == 'others') {
        return {
          'isValid': true,
          'confidence': 1.0,
          'detectedLabels': detectedLabels,
          'message': 'Category "Others" accepts any image'
        };
      }

      // Get expected keywords for the selected category
      final expectedKeywords = _categoryKeywords[selectedCategory.toLowerCase()] ?? [];
      
      if (expectedKeywords.isEmpty) {
        // Unknown category, treat as valid
        return {
          'isValid': true,
          'confidence': 0.5,
          'detectedLabels': detectedLabels,
          'message': 'Unknown category, validation skipped'
        };
      }

      // Check if any detected label matches expected keywords
      double maxConfidence = 0.0;
      bool isValid = false;

      for (final label in labels) {
        final labelText = label.label.toLowerCase();
        final confidence = label.confidence;

        for (final keyword in expectedKeywords) {
          if (labelText.contains(keyword) || keyword.contains(labelText)) {
            isValid = true;
            if (confidence > maxConfidence) {
              maxConfidence = confidence;
            }
          }
        }
      }

      return {
        'isValid': isValid,
        'confidence': maxConfidence,
        'detectedLabels': detectedLabels,
        'message': isValid 
            ? 'Image matches category "$selectedCategory"'
            : 'Image may not match category "$selectedCategory". Detected: ${detectedLabels.take(3).join(", ")}'
      };

    } catch (e) {
      print('ML validation error: $e');
      // On error, return valid to not block user
      return {
        'isValid': true,
        'confidence': 0.0,
        'detectedLabels': [],
        'message': 'Validation failed, proceeding anyway'
      };
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}
