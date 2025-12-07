import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageGeotagUtil {
  /// Adds geotag overlay (latitude, longitude, timestamp) to an image
  static Future<XFile?> addGeotagToImage({
    required XFile imageFile,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('ImageGeotagUtil: Starting geotag process');
      print('ImageGeotagUtil: Lat=$latitude, Lng=$longitude');
      
      // Read the original image
      final bytes = await imageFile.readAsBytes();
      print('ImageGeotagUtil: Image bytes loaded: ${bytes.length}');
      
      final image = await decodeImageFromList(bytes);
      print('ImageGeotagUtil: Image decoded: ${image.width}x${image.height}');

      // Create a canvas to draw the image and overlay
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // Draw the original image
      canvas.drawImage(image, Offset.zero, paint);
      print('ImageGeotagUtil: Original image drawn');

      // Prepare geotag text
      final now = DateTime.now();
      final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final latStr = '${latitude >= 0 ? 'N' : 'S'} ${latitude.abs().toStringAsFixed(6)}°';
      final lngStr = '${longitude >= 0 ? 'E' : 'W'} ${longitude.abs().toStringAsFixed(6)}°';
      print('ImageGeotagUtil: Geotag text prepared: $dateStr, $latStr, $lngStr');

      // Create text painters
      final textStyle = ui.TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          ui.Shadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      );

      // Background for text
      final bgPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      // Position at bottom-left corner
      const padding = 12.0;
      const lineHeight = 22.0;
      final bgRect = Rect.fromLTWH(
        0,
        image.height.toDouble() - (lineHeight * 3 + padding * 2),
        image.width.toDouble(),
        lineHeight * 3 + padding * 2,
      );
      canvas.drawRect(bgRect, bgPaint);
      print('ImageGeotagUtil: Background drawn');

      // Draw text lines
      _drawText(canvas, dateStr, padding, image.height - (lineHeight * 3 + padding), textStyle);
      _drawText(canvas, latStr, padding, image.height - (lineHeight * 2 + padding), textStyle);
      _drawText(canvas, lngStr, padding, image.height - (lineHeight + padding), textStyle);
      print('ImageGeotagUtil: Text drawn');

      // Convert canvas to image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(image.width, image.height);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      print('ImageGeotagUtil: Image converted to PNG: ${pngBytes.length} bytes');

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'geotagged_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      print('ImageGeotagUtil: Geotagged image saved: ${file.path}');

      return XFile(file.path);
    } catch (e, stackTrace) {
      print('ImageGeotagUtil ERROR: $e');
      print('ImageGeotagUtil STACK: $stackTrace');
      return null;
    }
  }

  static void _drawText(Canvas canvas, String text, double x, double y, ui.TextStyle style) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.left,
      fontSize: 16.0,
    ))
      ..pushStyle(style)
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: double.infinity));

    canvas.drawParagraph(paragraph, Offset(x, y));
  }
}
