import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/civic_report.dart';
import 'settings_service.dart';
import 'supabase_reports_service.dart';
import 'supabase_service.dart';

class DataService {
  static List<CivicReport> _mockReports = [];
  static bool _mockLoaded = false;

  /// Get all reports based on current settings (mock vs live)
  static Future<List<CivicReport>> getAllReports() async {
    try {
      final shouldUseLive = await SettingsService.shouldUseLiveData();

      if (shouldUseLive && SupabaseService.isAvailable) {
        return await _getLiveReports();
      } else {
        return await _getMockReports();
      }
    } catch (e) {
      print('Error getting reports, falling back to mock data: $e');
      return await _getMockReports();
    }
  }

  /// Get recent reports (last 10)
  static Future<List<CivicReport>> getRecentReports() async {
    try {
      final shouldUseLive = await SettingsService.shouldUseLiveData();

      if (shouldUseLive && SupabaseService.isAvailable) {
        return await SupabaseReportsService.getRecentReports();
      } else {
        final reports = await _getMockReports();
        reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return reports.take(5).toList();
      }
    } catch (e) {
      print('Error getting recent reports, falling back to mock data: $e');
      final reports = await _getMockReports();
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports.take(5).toList();
    }
  }

  /// Get reports by status
  static Future<List<CivicReport>> getReportsByStatus(String status) async {
    try {
      final allReports = await getAllReports();
      return allReports
          .where(
            (report) => report.status.toLowerCase() == status.toLowerCase(),
          )
          .toList();
    } catch (e) {
      print('Error getting reports by status: $e');
      return [];
    }
  }

  /// Get live reports from Supabase
  static Future<List<CivicReport>> _getLiveReports() async {
    final data = await SupabaseReportsService.getAllReports();
    return data
        .map(
          (item) => SupabaseReportsService.mapSupabaseReportToCivicReport(item),
        )
        .toList();
  }

  /// Get mock reports - loads from JSON file or generates dummy data
  static Future<List<CivicReport>> _getMockReports() async {
    if (!_mockLoaded) {
      try {
        // Try to load from JSON file first
        final json = await rootBundle.loadString('complete_dummy_data.json');
        final data = jsonDecode(json);
        _mockReports = (data['reports'] as List)
            .map<CivicReport>((r) => CivicReport.fromJson(r))
            .toList();
        _mockLoaded = true;
      } catch (e) {
        // Fall back to generated dummy data
        print('Could not load JSON data, using generated dummy data: $e');
        _mockReports = _generateDummyReports();
        _mockLoaded = true;
      }
    }
    return _mockReports;
  }

  /// Generate dummy reports for testing
  static List<CivicReport> _generateDummyReports() {
    final now = DateTime.now();

    return [
      CivicReport(
        category: 'Pothole',
        description: 'Large pothole on Main Street causing traffic issues',
        address: 'Main Street, Ranchi, Jharkhand',
        latitude: 23.3441,
        longitude: 85.3096,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      CivicReport(
        category: 'Garbage Collection',
        description: 'Overflowing garbage bins near the market area',
        address: 'Market Road, Jamshedpur, Jharkhand',
        latitude: 22.8046,
        longitude: 86.2029,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      CivicReport(
        category: 'Street Light',
        description: 'Multiple street lights not working in residential area',
        address: 'Bariatu Housing Colony, Ranchi, Jharkhand',
        latitude: 23.3629,
        longitude: 85.3371,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      CivicReport(
        category: 'Water Supply',
        description: 'Water supply disruption for the past 3 days',
        address: 'Hinoo, Ranchi, Jharkhand',
        latitude: 23.3584,
        longitude: 85.3247,
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      CivicReport(
        category: 'Road Repair',
        description: 'Damaged road surface with multiple cracks',
        address: 'Circular Road, Dhanbad, Jharkhand',
        latitude: 23.7957,
        longitude: 86.4304,
        timestamp: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// Generate dummy notifications
  static List<Map<String, dynamic>> getDummyNotifications() {
    final now = DateTime.now();

    return [
      {
        'message':
            'Your pothole report has been assigned to the maintenance team',
        'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
        'read': false,
      },
      {
        'message': 'New garbage collection schedule updated for your area',
        'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'read': false,
      },
      {
        'message': 'Your street light complaint is now in progress',
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'read': true,
      },
      {
        'message': 'Water supply restoration work completed in your area',
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'read': true,
      },
      {
        'message':
            'Thank you for reporting! Your civic participation makes a difference',
        'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
        'read': true,
      },
    ];
  }

  /// Get report status for progress tracking
  static Map<String, dynamic> getReportProgress(CivicReport report) {
    // Simulate different progress stages based on report age
    final daysSinceReport = DateTime.now().difference(report.timestamp).inDays;

    if (daysSinceReport < 1) {
      return {
        'status': 'Dispatched',
        'progress': 0.33,
        'stages': ['Submitted', 'Dispatched', 'Working', 'Done'],
        'currentStage': 1,
        'description':
            'Your report has been received and assigned to the relevant department.',
      };
    } else if (daysSinceReport < 3) {
      return {
        'status': 'Working',
        'progress': 0.66,
        'stages': ['Submitted', 'Dispatched', 'Working', 'Done'],
        'currentStage': 2,
        'description': 'Work team is actively addressing the reported issue.',
      };
    } else {
      return {
        'status': 'Done',
        'progress': 1.0,
        'stages': ['Submitted', 'Dispatched', 'Working', 'Done'],
        'currentStage': 3,
        'description': 'Issue has been resolved. Thank you for your report!',
      };
    }
  }

  /// Get summary statistics
  static Map<String, int> getStatistics() {
    return {'inProgress': 3, 'resolved': 12, 'total': 15};
  }

  /// Check data source availability
  static Future<DataSourceStatus> getDataSourceStatus() async {
    final useMockData = await SettingsService.getMockDataEnabled();

    if (useMockData) {
      return DataSourceStatus(
        source: DataSource.mock,
        available: true,
        message: 'Using mock data from local file',
      );
    }

    if (SupabaseService.isAvailable) {
      final canConnect = await SupabaseReportsService.testConnection();
      return DataSourceStatus(
        source: DataSource.live,
        available: canConnect,
        message: canConnect
            ? 'Connected to live Supabase database'
            : 'Supabase available but database connection failed',
      );
    }

    return DataSourceStatus(
      source: DataSource.live,
      available: false,
      message: 'Supabase service not configured or available',
    );
  }

  /// Force refresh data (useful for pull-to-refresh)
  static Future<List<CivicReport>> refreshReports() async {
    // For live data, this will fetch fresh data from Supabase
    // For mock data, this will reload from the JSON file
    if (!_mockLoaded) {
      _mockLoaded = false; // Force reload for mock data
    }
    return await getAllReports();
  }
}

enum DataSource { mock, live }

class DataSourceStatus {
  final DataSource source;
  final bool available;
  final String message;

  DataSourceStatus({
    required this.source,
    required this.available,
    required this.message,
  });

  String get displayName {
    switch (source) {
      case DataSource.mock:
        return 'Mock Data';
      case DataSource.live:
        return 'Live Data';
    }
  }
}
