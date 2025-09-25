import 'dart:io';
import 'dart:typed_data';
import '../models/civic_report.dart';
import 'media_service.dart';
import 'voice_recording_service.dart';
import 'upload_queue_service.dart';
import 'settings_service.dart';
import 'local_storage_service.dart';

class UploadService {
  /// Upload a complete civic report with image and optional voice
  static Future<UploadResult> uploadReport({
    required CivicReport report,
    required File imageFile,
    VoiceRecordingResult? voiceResult,
  }) async {
    try {
      // Validate required fields
      if (!_validateReport(report)) {
        throw Exception('Report validation failed');
      }

      // Check compression setting
      final useCompression = await SettingsService.getFileCompressionEnabled();

      Uint8List imageBytes;
      String imageFilename;

      if (useCompression) {
        // Compress image
        final compressedImage = await MediaService.compressImage(imageFile);
        imageBytes = compressedImage.bytes;
        imageFilename = compressedImage.filename;
      } else {
        // Use raw image
        imageBytes = await imageFile.readAsBytes();
        imageFilename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      // Check if we should use live upload or mock mode
      final shouldUseLive = await SettingsService.shouldUseLiveData();

      if (shouldUseLive) {
        // Add to upload queue for live upload
        final queueId = await UploadQueueService.addToQueue(
          report: report,
          imageBytes: imageBytes,
          imageFilename: imageFilename,
          voiceBytes: voiceResult?.bytes,
          voiceFilename: voiceResult?.filename,
        );

        return UploadResult(
          success: true,
          queueId: queueId,
          message: useCompression
              ? 'Report added to upload queue (compressed)'
              : 'Report added to upload queue (uncompressed)',
          isQueued: true,
        );
      } else {
        // Mock mode - save locally only
        if (useCompression) {
          final compressedImage = await MediaService.compressImage(imageFile);
          await _saveMockReport(report, compressedImage, voiceResult);
        } else {
          await _saveMockReportRaw(report, imageFile, voiceResult);
        }

        return UploadResult(
          success: true,
          message: 'Report saved locally (Mock mode)',
          isQueued: false,
        );
      }
    } catch (e) {
      return UploadResult(success: false, error: e.toString(), isQueued: false);
    }
  }

  /// Save report in mock mode (local storage only)
  static Future<void> _saveMockReport(
    CivicReport report,
    CompressedImageResult compressedImage,
    VoiceRecordingResult? voiceResult,
  ) async {
    try {
      // Save compressed image locally
      final imageFile = await MediaService.saveCompressedImageLocally(
        compressedImage.bytes,
        compressedImage.filename,
      );

      // Save voice recording locally if available
      File? voiceFile;
      if (voiceResult != null) {
        voiceFile = await VoiceRecordingService.saveRecordingLocally(
          voiceResult.bytes,
          voiceResult.filename,
        );
      }

      // Create updated report with local file paths
      final updatedReport = report.copyWith(
        imagePath: imageFile.path,
        voiceNotes: voiceFile?.path ?? '',
        timestamp: DateTime.now(),
      );

      // Store in local storage
      await LocalStorageService.storeReport(updatedReport);

      // Report saved locally in mock mode
    } catch (e) {
      throw Exception('Failed to save mock report: $e');
    }
  }

  /// Save report in mock mode with raw files (no compression)
  static Future<void> _saveMockReportRaw(
    CivicReport report,
    File imageFile,
    VoiceRecordingResult? voiceResult,
  ) async {
    try {
      // Save voice recording locally if available
      File? voiceFile;
      if (voiceResult != null) {
        voiceFile = await VoiceRecordingService.saveRecordingLocally(
          voiceResult.bytes,
          voiceResult.filename,
        );
      }

      // Create updated report with local file paths
      final updatedReport = report.copyWith(
        imagePath: imageFile.path,
        voiceNotes: voiceFile?.path ?? '',
        timestamp: DateTime.now(),
      );

      // Store in local storage
      await LocalStorageService.storeReport(updatedReport);

      print('Report saved locally in mock mode (uncompressed)');
    } catch (e) {
      throw Exception('Failed to save raw mock report: $e');
    }
  }

  /// Validate report before upload
  static bool _validateReport(CivicReport report) {
    // Check required fields
    if (report.category.isEmpty) {
      throw Exception('Category is required');
    }

    if (report.description.isEmpty) {
      throw Exception('Description is required');
    }

    if (report.address.isEmpty) {
      throw Exception('Address is required');
    }

    if (report.latitude == null || report.longitude == null) {
      throw Exception('Location coordinates are required');
    }

    return true;
  }

  /// Get upload queue status
  static Future<QueueStatus> getUploadStatus() async {
    return await UploadQueueService.getQueueStatus();
  }

  /// Retry failed uploads
  static Future<void> retryFailedUploads() async {
    await UploadQueueService.retryFailedUploads();
  }

  /// Clear completed uploads
  static Future<void> clearCompletedUploads() async {
    await UploadQueueService.clearCompletedUploads();
  }
}

class UploadResult {
  final bool success;
  final String? queueId;
  final String? message;
  final String? error;
  final bool isQueued;

  UploadResult({
    required this.success,
    this.queueId,
    this.message,
    this.error,
    required this.isQueued,
  });

  @override
  String toString() {
    if (success) {
      return message ?? 'Upload successful';
    } else {
      return error ?? 'Upload failed';
    }
  }
}
