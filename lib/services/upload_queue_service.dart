import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/civic_report.dart';
import 'supabase_storage_service.dart';
import 'supabase_reports_service.dart';
import 'notification_service.dart';

class UploadQueueService {
  static const String _queueKey = 'upload_queue';
  static const int maxRetryAttempts = 3;
  static bool _isProcessing = false;
  static bool _hasScheduledProcessing = false;

  /// Add a report to the upload queue
  static Future<String> addToQueue({
    required CivicReport report,
    required Uint8List imageBytes,
    required String imageFilename,
    Uint8List? voiceBytes,
    String? voiceFilename,
  }) async {
    try {
      final queueItem = UploadQueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        report: report,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
        voiceBytes: voiceBytes,
        voiceFilename: voiceFilename,
        createdAt: DateTime.now(),
        retryCount: 0,
        status: UploadStatus.pending,
      );

      await _saveQueueItem(queueItem);

      // Try to process queue with delay to prevent multiple calls
      _scheduleQueueProcessing();

      return queueItem.id;
    } catch (e) {
      throw Exception('Failed to add to upload queue: $e');
    }
  }

  /// Schedule queue processing with delay to prevent multiple simultaneous calls
  static void _scheduleQueueProcessing() {
    if (_hasScheduledProcessing) return;

    _hasScheduledProcessing = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      _hasScheduledProcessing = false;
      if (!_isProcessing) {
        _processQueue();
      }
    });
  }

  /// Process the upload queue
  static Future<void> _processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Check network connectivity
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        print('No network connection, skipping queue processing');
        return;
      }

      final queue = await _getQueue();
      final pendingItems = queue
          .where(
            (item) =>
                item.status == UploadStatus.pending ||
                item.status == UploadStatus.retrying,
          )
          .toList();

      for (final item in pendingItems) {
        await _processQueueItem(item);
      }
    } catch (e) {
      print('Error processing upload queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single queue item
  static Future<void> _processQueueItem(UploadQueueItem item) async {
    try {
      // Update status to uploading
      item.status = UploadStatus.uploading;
      await _updateQueueItem(item);

      // Show upload progress notification
      await NotificationService.showUploadProgress(
        title: 'Uploading Report',
        message: 'Uploading ${item.report.category} report...',
        progress: 10,
        reportId: item.id,
      );

      // Upload files to storage
      final uploadResult = await SupabaseStorageService.uploadReportFiles(
        imageBytes: item.imageBytes,
        imageFilename: item.imageFilename,
        voiceBytes: item.voiceBytes,
        voiceFilename: item.voiceFilename,
        onProgress: (message, progress) async {
          await NotificationService.showUploadProgress(
            title: 'Uploading Report',
            message: message,
            progress: (progress * 80).round() + 10, // 10-90%
            reportId: item.id,
          );
        },
      );

      if (!uploadResult.success) {
        throw Exception(uploadResult.error ?? 'Upload failed');
      }

      // Update progress
      await NotificationService.showUploadProgress(
        title: 'Uploading Report',
        message: 'Saving report to database...',
        progress: 95,
        reportId: item.id,
      );

      // Insert report into database
      final dbResult = await SupabaseReportsService.insertReport(
        category: item.report.category,
        area: item.report.area,
        time: item.report.time,
        date: item.report.date,
        description: item.report.description,
        geolocationLat: item.report.latitude!,
        geolocationLong: item.report.longitude!,
        address: item.report.address,
        urgency: item.report.urgency,
        imageUrl: uploadResult.imageUrl!,
        voiceUrl: uploadResult.voiceUrl,
        additionalNotes: item.report.additionalNotes.isNotEmpty
            ? item.report.additionalNotes
            : null,
        landmarks: item.report.landmarks,
      );

      // Mark as completed
      item.status = UploadStatus.completed;
      item.completedAt = DateTime.now();
      item.reportId = dbResult?['request_id']?.toString();
      await _updateQueueItem(item);

      // Show success notification
      await NotificationService.showUploadProgress(
        title: 'Report Uploaded',
        message:
            'Your ${item.report.category} report was submitted successfully',
        progress: 100,
        reportId: item.id,
      );

      print('Successfully uploaded report: ${item.id}');
    } catch (e) {
      print('Failed to upload report ${item.id}: $e');
      await _handleUploadFailure(item, e.toString());
    }
  }

  /// Handle upload failure with retry logic
  static Future<void> _handleUploadFailure(
    UploadQueueItem item,
    String error,
  ) async {
    item.retryCount++;
    item.lastError = error;

    if (item.retryCount >= maxRetryAttempts) {
      item.status = UploadStatus.failed;
      await NotificationService.showReportStatusUpdate(
        title: 'Upload Failed',
        message:
            'Failed to upload ${item.report.category} report after ${item.retryCount} attempts',
        reportId: item.id,
      );
    } else {
      item.status = UploadStatus.retrying;
      // Schedule retry with exponential backoff
      final delaySeconds = (item.retryCount * item.retryCount) * 5;
      Future.delayed(Duration(seconds: delaySeconds), () {
        _scheduleQueueProcessing();
      });
    }

    await _updateQueueItem(item);
  }

  /// Get all queue items
  static Future<List<UploadQueueItem>> _getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson == null) return [];

      final queueData = jsonDecode(queueJson) as List;
      return queueData.map((item) => UploadQueueItem.fromJson(item)).toList();
    } catch (e) {
      print('Error getting upload queue: $e');
      return [];
    }
  }

  /// Save queue item
  static Future<void> _saveQueueItem(UploadQueueItem item) async {
    final queue = await _getQueue();
    queue.add(item);
    await _saveQueue(queue);
  }

  /// Update queue item
  static Future<void> _updateQueueItem(UploadQueueItem item) async {
    final queue = await _getQueue();
    final index = queue.indexWhere((q) => q.id == item.id);

    if (index != -1) {
      queue[index] = item;
      await _saveQueue(queue);
    }
  }

  /// Save entire queue
  static Future<void> _saveQueue(List<UploadQueueItem> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(queue.map((item) => item.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      print('Error saving upload queue: $e');
    }
  }

  /// Get queue status for UI
  static Future<QueueStatus> getQueueStatus() async {
    final queue = await _getQueue();

    return QueueStatus(
      total: queue.length,
      pending: queue
          .where((item) => item.status == UploadStatus.pending)
          .length,
      uploading: queue
          .where((item) => item.status == UploadStatus.uploading)
          .length,
      retrying: queue
          .where((item) => item.status == UploadStatus.retrying)
          .length,
      completed: queue
          .where((item) => item.status == UploadStatus.completed)
          .length,
      failed: queue.where((item) => item.status == UploadStatus.failed).length,
    );
  }

  /// Retry failed uploads
  static Future<void> retryFailedUploads() async {
    final queue = await _getQueue();

    for (final item in queue) {
      if (item.status == UploadStatus.failed) {
        item.status = UploadStatus.pending;
        item.retryCount = 0;
        item.lastError = null;
        await _updateQueueItem(item);
      }
    }

    _scheduleQueueProcessing();
  }

  /// Clear completed uploads from queue
  static Future<void> clearCompletedUploads() async {
    final queue = await _getQueue();
    final activeQueue = queue
        .where((item) => item.status != UploadStatus.completed)
        .toList();
    await _saveQueue(activeQueue);
  }

  /// Get failed uploads for UI display
  static Future<List<UploadQueueItem>> getFailedUploads() async {
    final queue = await _getQueue();
    return queue.where((item) => item.status == UploadStatus.failed).toList();
  }

  /// Get all queue items (for debugging/admin purposes)
  static Future<List<UploadQueueItem>> getAllQueueItems() async {
    return await _getQueue();
  }

  /// Start automatic queue processing when connectivity changes
  static void startConnectivityMonitoring() {
    Connectivity().onConnectivityChanged.listen((connectivityResult) {
      if (connectivityResult != ConnectivityResult.none) {
        // Network connectivity restored, schedule processing
        _scheduleQueueProcessing();
      }
    });
  }
}

enum UploadStatus { pending, uploading, retrying, completed, failed }

class UploadQueueItem {
  final String id;
  final CivicReport report;
  final Uint8List imageBytes;
  final String imageFilename;
  final Uint8List? voiceBytes;
  final String? voiceFilename;
  final DateTime createdAt;

  int retryCount;
  UploadStatus status;
  String? lastError;
  DateTime? completedAt;
  String? reportId;

  UploadQueueItem({
    required this.id,
    required this.report,
    required this.imageBytes,
    required this.imageFilename,
    this.voiceBytes,
    this.voiceFilename,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.lastError,
    this.completedAt,
    this.reportId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report': _reportToJson(report),
      'imageBytes': imageBytes,
      'imageFilename': imageFilename,
      'voiceBytes': voiceBytes,
      'voiceFilename': voiceFilename,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'status': status.toString(),
      'lastError': lastError,
      'completedAt': completedAt?.toIso8601String(),
      'reportId': reportId,
    };
  }

  factory UploadQueueItem.fromJson(Map<String, dynamic> json) {
    return UploadQueueItem(
      id: json['id'],
      report: _reportFromJson(json['report']),
      imageBytes: Uint8List.fromList(List<int>.from(json['imageBytes'])),
      imageFilename: json['imageFilename'],
      voiceBytes: json['voiceBytes'] != null
          ? Uint8List.fromList(List<int>.from(json['voiceBytes']))
          : null,
      voiceFilename: json['voiceFilename'],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'],
      status: UploadStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
      ),
      lastError: json['lastError'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      reportId: json['reportId'],
    );
  }

  static Map<String, dynamic> _reportToJson(CivicReport report) {
    // Simplified report serialization for queue storage
    return {
      'category': report.category,
      'area': report.area,
      'time': report.time,
      'date': report.date,
      'description': report.description,
      'latitude': report.latitude,
      'longitude': report.longitude,
      'address': report.address,
      'urgency': report.urgency,
      'additionalNotes': report.additionalNotes,
      'landmarks': report.landmarks,
    };
  }

  static CivicReport _reportFromJson(Map<String, dynamic> json) {
    return CivicReport(
      category: json['category'],
      area: json['area'],
      time: json['time'],
      date: json['date'],
      description: json['description'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      urgency: json['urgency'],
      additionalNotes: json['additionalNotes'] ?? '',
      landmarks: json['landmarks'],
    );
  }
}

class QueueStatus {
  final int total;
  final int pending;
  final int uploading;
  final int retrying;
  final int completed;
  final int failed;

  QueueStatus({
    required this.total,
    required this.pending,
    required this.uploading,
    required this.retrying,
    required this.completed,
    required this.failed,
  });

  int get active => pending + uploading + retrying;
  bool get hasFailures => failed > 0;
  bool get isActive => active > 0;
}
