import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/civic_report.dart';

class FailedUploadsService {
  static const String _failedUploadsKey = 'failed_uploads';

  /// Add a failed upload to local storage
  static Future<void> addFailedUpload({
    required CivicReport report,
    required String imagePath,
    String? voicePath,
    required String errorMessage,
  }) async {
    try {
      final failedUpload = FailedUpload(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        report: report,
        imagePath: imagePath,
        voicePath: voicePath,
        errorMessage: errorMessage,
        failedAt: DateTime.now(),
        retryCount: 0,
      );

      final failedUploads = await getFailedUploads();
      failedUploads.add(failedUpload);
      await _saveFailedUploads(failedUploads);
    } catch (e) {
      print('Error adding failed upload: $e');
    }
  }

  /// Get all failed uploads
  static Future<List<FailedUpload>> getFailedUploads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedUploadsJson = prefs.getString(_failedUploadsKey);

      if (failedUploadsJson == null) return [];

      final failedUploadsData = jsonDecode(failedUploadsJson) as List;
      return failedUploadsData
          .map((item) => FailedUpload.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting failed uploads: $e');
      return [];
    }
  }

  /// Update retry count for a failed upload
  static Future<void> incrementRetryCount(String id) async {
    try {
      final failedUploads = await getFailedUploads();
      final index = failedUploads.indexWhere((upload) => upload.id == id);

      if (index != -1) {
        failedUploads[index] = failedUploads[index].copyWith(
          retryCount: failedUploads[index].retryCount + 1,
          lastRetryAt: DateTime.now(),
        );
        await _saveFailedUploads(failedUploads);
      }
    } catch (e) {
      print('Error incrementing retry count: $e');
    }
  }

  /// Remove a failed upload (after successful retry)
  static Future<void> removeFailedUpload(String id) async {
    try {
      final failedUploads = await getFailedUploads();
      failedUploads.removeWhere((upload) => upload.id == id);
      await _saveFailedUploads(failedUploads);
    } catch (e) {
      print('Error removing failed upload: $e');
    }
  }

  /// Clear all failed uploads
  static Future<void> clearAllFailedUploads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_failedUploadsKey);
    } catch (e) {
      print('Error clearing failed uploads: $e');
    }
  }

  /// Save failed uploads to local storage
  static Future<void> _saveFailedUploads(
    List<FailedUpload> failedUploads,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedUploadsJson = jsonEncode(
        failedUploads.map((upload) => upload.toJson()).toList(),
      );
      await prefs.setString(_failedUploadsKey, failedUploadsJson);
    } catch (e) {
      print('Error saving failed uploads: $e');
    }
  }

  /// Get count of failed uploads
  static Future<int> getFailedUploadsCount() async {
    final failedUploads = await getFailedUploads();
    return failedUploads.length;
  }
}

class FailedUpload {
  final String id;
  final CivicReport report;
  final String imagePath;
  final String? voicePath;
  final String errorMessage;
  final DateTime failedAt;
  final int retryCount;
  final DateTime? lastRetryAt;

  FailedUpload({
    required this.id,
    required this.report,
    required this.imagePath,
    this.voicePath,
    required this.errorMessage,
    required this.failedAt,
    required this.retryCount,
    this.lastRetryAt,
  });

  FailedUpload copyWith({
    String? id,
    CivicReport? report,
    String? imagePath,
    String? voicePath,
    String? errorMessage,
    DateTime? failedAt,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return FailedUpload(
      id: id ?? this.id,
      report: report ?? this.report,
      imagePath: imagePath ?? this.imagePath,
      voicePath: voicePath ?? this.voicePath,
      errorMessage: errorMessage ?? this.errorMessage,
      failedAt: failedAt ?? this.failedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report': report.toJson(),
      'imagePath': imagePath,
      'voicePath': voicePath,
      'errorMessage': errorMessage,
      'failedAt': failedAt.toIso8601String(),
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
    };
  }

  factory FailedUpload.fromJson(Map<String, dynamic> json) {
    return FailedUpload(
      id: json['id'],
      report: CivicReport.fromJson(json['report']),
      imagePath: json['imagePath'],
      voicePath: json['voicePath'],
      errorMessage: json['errorMessage'],
      failedAt: DateTime.parse(json['failedAt']),
      retryCount: json['retryCount'] ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'])
          : null,
    );
  }
}
