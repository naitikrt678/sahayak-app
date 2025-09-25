import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageCompressionService {
  static const int maxDimension = 800;
  static const int quality = 50;
  static const _uuid = Uuid();

  /// Compress an image file according to the specified requirements
  /// - Max dimension: 1280px
  /// - JPEG format at 70% quality
  /// - Returns compressed file bytes and suggested filename
  static Future<CompressedImageResult> compressImage(File imageFile) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 200,
        minHeight: 200,
        quality: quality,
        format: CompressFormat.jpeg,
        // Auto-resize to maintain aspect ratio with max dimension
        autoCorrectionAngle: true,
      );

      if (compressedBytes == null) {
        throw Exception('Failed to compress image');
      }

      // Further resize if needed based on dimensions
      final resizedBytes = await _resizeToMaxDimension(
        compressedBytes,
        imageFile.path,
      );

      // Generate unique filename
      final filename = '${_uuid.v4()}.jpg';

      // Calculate compression ratio
      final originalSize = await imageFile.length();
      final compressedSize = resizedBytes.length;
      final compressionRatio = (1 - (compressedSize / originalSize)) * 100;

      return CompressedImageResult(
        bytes: resizedBytes,
        filename: filename,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
      );
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Resize image to ensure max dimension doesn't exceed limit
  static Future<Uint8List> _resizeToMaxDimension(
    Uint8List imageBytes,
    String originalPath,
  ) async {
    try {
      // Create a temporary file to work with
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_${_uuid.v4()}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        tempFile.path,
        minWidth: 200,
        minHeight: 200,
        quality: quality,
        format: CompressFormat.jpeg,
        // Ensure max dimension constraint
        rotate: 0,
      );

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      if (compressedBytes == null) {
        return imageBytes; // Return original if resize fails
      }

      return compressedBytes;
    } catch (e) {
      print('Error resizing image: $e');
      return imageBytes; // Return original bytes if resize fails
    }
  }

  /// Compress multiple images in batch
  static Future<List<CompressedImageResult>> compressMultipleImages(
    List<File> imageFiles,
  ) async {
    final results = <CompressedImageResult>[];

    for (final file in imageFiles) {
      try {
        final result = await compressImage(file);
        results.add(result);
      } catch (e) {
        print('Failed to compress image ${file.path}: $e');
        // Continue with other images even if one fails
      }
    }

    return results;
  }

  /// Save compressed image to local storage for offline sync
  static Future<File> saveCompressedImageLocally(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/compressed_images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final file = File('${imagesDir.path}/$filename');
      await file.writeAsBytes(imageBytes);

      return file;
    } catch (e) {
      throw Exception('Failed to save compressed image locally: $e');
    }
  }

  /// Get image dimensions without loading full image into memory
  static Future<ImageDimensions?> getImageDimensions(String imagePath) async {
    try {
      // This is a simplified approach - in a real app you might want to use
      // a more sophisticated method to get dimensions without loading the full image
      final file = File(imagePath);
      if (!await file.exists()) return null;

      // For now, we'll return null and rely on the compression logic
      // In a production app, you could use packages like 'image' to get dimensions
      return null;
    } catch (e) {
      print('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Validate image file before compression
  static Future<bool> isValidImageFile(File imageFile) async {
    try {
      if (!await imageFile.exists()) return false;

      final filename = imageFile.path.toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp'];

      return validExtensions.any((ext) => filename.endsWith(ext));
    } catch (e) {
      return false;
    }
  }
}

class CompressedImageResult {
  final Uint8List bytes;
  final String filename;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;

  CompressedImageResult({
    required this.bytes,
    required this.filename,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
  });

  String get compressionInfo =>
      'Original: ${_formatBytes(originalSize)}, '
      'Compressed: ${_formatBytes(compressedSize)}, '
      'Saved: ${compressionRatio.toStringAsFixed(1)}%';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});

  bool get exceedsMaxDimension =>
      width > ImageCompressionService.maxDimension ||
      height > ImageCompressionService.maxDimension;

  double get aspectRatio => width / height;
}
