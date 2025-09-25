import 'dart:typed_data';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'environment_service.dart';

class SupabaseStorageService {
  static const int maxRetries = 3;
  static const int initialRetryDelayMs = 1000;
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB

  /// Validate bucket accessibility and permissions
  static Future<BucketValidationResult> validateBucket() async {
    try {
      if (!SupabaseService.isAvailable) {
        return BucketValidationResult(
          accessible: false,
          canRead: false,
          canWrite: false,
          error: 'Supabase service not available',
        );
      }

      final bucketName = EnvironmentService.reportsBucket;
      bool accessible = false;
      bool canRead = false;
      bool canWrite = false;
      String? error;

      try {
        // Test 1: Try to list files (tests bucket existence and read access)
        await SupabaseService.reportsStorage.list();
        accessible = true;
        canRead = true;
      } catch (e) {
        error = 'Cannot access bucket "$bucketName": $e';
        if (e.toString().contains('not found') ||
            e.toString().contains('does not exist')) {
          error = 'Storage bucket "$bucketName" does not exist';
        } else if (e.toString().contains('permission') ||
            e.toString().contains('unauthorized')) {
          accessible = true; // Bucket exists but no read permission
          error = 'No read permission for bucket "$bucketName"';
        }
      }

      if (accessible) {
        try {
          // Test 2: Try to upload a tiny test file (tests write access)
          final testData = Uint8List.fromList([0x01, 0x02, 0x03]);
          final testPath =
              'test/connectivity_test_${DateTime.now().millisecondsSinceEpoch}.dat';

          await SupabaseService.reportsStorage.uploadBinary(
            testPath,
            testData,
            fileOptions: const FileOptions(cacheControl: '60'),
          );

          canWrite = true;

          // Clean up test file
          try {
            await SupabaseService.reportsStorage.remove([testPath]);
          } catch (e) {
            print('Warning: Could not clean up test file: $e');
          }
        } catch (e) {
          error = 'No write permission for bucket "$bucketName": $e';
        }
      }

      return BucketValidationResult(
        accessible: accessible,
        canRead: canRead,
        canWrite: canWrite,
        error: error,
        bucketName: bucketName,
      );
    } catch (e) {
      return BucketValidationResult(
        accessible: false,
        canRead: false,
        canWrite: false,
        error: 'Bucket validation failed: $e',
      );
    }
  }

  /// Upload image to Supabase storage with enhanced error handling
  static Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
    Function(double)? onProgress,
  }) async {
    if (!SupabaseService.isAvailable) {
      throw StorageException('Supabase service not available');
    }

    if (imageBytes.isEmpty) {
      throw StorageException('Image data is empty');
    }

    if (imageBytes.length > maxFileSizeBytes) {
      throw StorageException(
        'Image file too large: ${imageBytes.length} bytes (max: $maxFileSizeBytes)',
      );
    }

    final path = 'reports/${_generateUniqueFilename(filename)}';

    return await _uploadFileWithRetry(
      path: path,
      data: imageBytes,
      contentType: 'image/jpeg',
      onProgress: onProgress,
    );
  }

  /// Upload voice recording to Supabase storage with enhanced error handling
  static Future<String> uploadVoiceRecording({
    required Uint8List audioBytes,
    required String filename,
    Function(double)? onProgress,
  }) async {
    if (!SupabaseService.isAvailable) {
      throw StorageException('Supabase service not available');
    }

    if (audioBytes.isEmpty) {
      throw StorageException('Audio data is empty');
    }

    if (audioBytes.length > maxFileSizeBytes) {
      throw StorageException(
        'Audio file too large: ${audioBytes.length} bytes (max: $maxFileSizeBytes)',
      );
    }

    final path = 'reports/${_generateUniqueFilename(filename)}';

    return await _uploadFileWithRetry(
      path: path,
      data: audioBytes,
      contentType: _getAudioContentType(filename),
      onProgress: onProgress,
    );
  }

  /// Core upload method with retry logic
  static Future<String> _uploadFileWithRetry({
    required String path,
    required Uint8List data,
    required String contentType,
    Function(double)? onProgress,
  }) async {
    StorageException? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        onProgress?.call(0.1 * attempt);

        // Upload file to storage
        await SupabaseService.reportsStorage.uploadBinary(
          path,
          data,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true, // Allow overwriting to avoid conflicts
            contentType: contentType,
          ),
        );

        onProgress?.call(0.8);

        // Get public URL
        final publicUrl = SupabaseService.reportsStorage.getPublicUrl(path);

        if (publicUrl.isEmpty) {
          throw StorageException('Failed to get public URL for uploaded file');
        }

        onProgress?.call(1.0);
        print('Successfully uploaded file: $path (attempt $attempt)');
        return publicUrl;
      } catch (e) {
        final errorMessage = e.toString();
        
        // Check for RLS policy violations
        if (errorMessage.contains('row-level security') || 
            errorMessage.contains('policy') ||
            errorMessage.contains('Unauthorized') ||
            errorMessage.contains('403')) {
          throw StorageException(
            'Upload blocked by security policy. Please check Supabase bucket permissions. '
            'Go to Supabase Dashboard → Storage → "reports" bucket → Settings and either '
            'disable RLS or add a policy to allow anonymous uploads.'
          );
        }
        
        // Check for bucket not found
        if (errorMessage.contains('not found') || errorMessage.contains('does not exist')) {
          throw StorageException(
            'Storage bucket "reports" does not exist. Please create it in Supabase Dashboard.'
          );
        }
        
        lastError = StorageException('Upload attempt $attempt failed: $e');
        print('Upload attempt $attempt failed for $path: $e');

        if (attempt < maxRetries) {
          final delayMs = initialRetryDelayMs * pow(2, attempt - 1).toInt();
          print('Retrying upload in ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    throw lastError ??
        StorageException('Upload failed after $maxRetries attempts');
  }

  /// Generate unique filename to avoid conflicts
  static String _generateUniqueFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFilename.split('.').last;
    final randomSuffix = Random().nextInt(10000).toString().padLeft(4, '0');
    return '${timestamp}_$randomSuffix.$extension';
  }

  /// Get appropriate content type for audio files
  static String _getAudioContentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'audio/mpeg';
    }
  }

  /// Upload both image and voice recording with enhanced error handling
  static Future<UploadResult> uploadReportFiles({
    required Uint8List imageBytes,
    required String imageFilename,
    Uint8List? voiceBytes,
    String? voiceFilename,
    Function(String, double)? onProgress,
  }) async {
    try {
      // Validate inputs
      if (imageBytes.isEmpty) {
        throw StorageException('Image data is required');
      }

      if (voiceBytes != null && voiceBytes.isEmpty) {
        throw StorageException('Voice data is empty (provide null instead)');
      }

      String? imageUrl;
      String? voiceUrl;

      // Upload image
      onProgress?.call('Uploading image...', 0.1);
      try {
        imageUrl = await uploadImage(
          imageBytes: imageBytes,
          filename: imageFilename,
          onProgress: (progress) {
            onProgress?.call('Uploading image...', 0.1 + (progress * 0.4));
          },
        );
      } catch (e) {
        throw StorageException('Image upload failed: $e');
      }

      // Upload voice recording if provided
      if (voiceBytes != null && voiceFilename != null) {
        onProgress?.call('Uploading voice recording...', 0.6);
        try {
          voiceUrl = await uploadVoiceRecording(
            audioBytes: voiceBytes,
            filename: voiceFilename,
            onProgress: (progress) {
              onProgress?.call(
                'Uploading voice recording...',
                0.6 + (progress * 0.3),
              );
            },
          );
        } catch (e) {
          // Voice upload failure is not critical - continue with image only
          print('Warning: Voice upload failed, continuing with image only: $e');
        }
      }

      onProgress?.call('Upload complete', 1.0);

      return UploadResult(
        imageUrl: imageUrl,
        voiceUrl: voiceUrl,
        success: true,
      );
    } on StorageException catch (e) {
      return UploadResult(error: e.message, success: false);
    } catch (e) {
      return UploadResult(error: 'Unexpected upload error: $e', success: false);
    }
  }

  /// Delete file from storage
  static Future<bool> deleteFile(String path) async {
    try {
      if (!SupabaseService.isAvailable) return false;

      await SupabaseService.reportsStorage.remove([path]);
      return true;
    } catch (e) {
      print('Failed to delete file from storage: $e');
      return false;
    }
  }

  /// Check if storage bucket exists and is accessible
  static Future<bool> testStorageConnection() async {
    try {
      if (!SupabaseService.isAvailable) return false;

      // Try to list files in the bucket (this will fail if bucket doesn't exist)
      await SupabaseService.reportsStorage.list();
      return true;
    } catch (e) {
      print('Storage connection test failed: $e');
      return false;
    }
  }

  /// Get file info from storage
  static Future<FileObject?> getFileInfo(String path) async {
    try {
      if (!SupabaseService.isAvailable) return null;

      final files = await SupabaseService.reportsStorage.list(
        path: path.split('/').first,
      );

      return files.firstWhere(
        (file) => file.name == path.split('/').last,
        orElse: () => throw Exception('File not found'),
      );
    } catch (e) {
      print('Failed to get file info: $e');
      return null;
    }
  }
}

class UploadResult {
  final String? imageUrl;
  final String? voiceUrl;
  final String? error;
  final bool success;

  UploadResult({
    this.imageUrl,
    this.voiceUrl,
    this.error,
    required this.success,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVoice => voiceUrl != null && voiceUrl!.isNotEmpty;

  @override
  String toString() {
    if (success) {
      return 'Upload successful - Image: $hasImage, Voice: $hasVoice';
    } else {
      return 'Upload failed: $error';
    }
  }
}

class BucketValidationResult {
  final bool accessible;
  final bool canRead;
  final bool canWrite;
  final String? error;
  final String? bucketName;

  BucketValidationResult({
    required this.accessible,
    required this.canRead,
    required this.canWrite,
    this.error,
    this.bucketName,
  });

  bool get isFullyFunctional => accessible && canRead && canWrite;

  String get status {
    if (isFullyFunctional) return 'Fully Accessible';
    if (accessible && canRead) return 'Read Only';
    if (accessible) return 'Limited Access';
    return 'Inaccessible';
  }

  String get statusMessage {
    if (isFullyFunctional) {
      return 'Storage bucket "${bucketName ?? 'reports'}" is fully accessible';
    }
    return error ?? 'Unknown bucket status';
  }
}

class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
