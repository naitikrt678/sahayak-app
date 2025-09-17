import '../models/civic_report.dart';

class DummyDataService {
  // Generate dummy reports for testing
  static List<CivicReport> getDummyReports() {
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

  // Generate dummy notifications
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

  // Get report status for progress tracking
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

  // Get summary statistics
  static Map<String, int> getStatistics() {
    return {'inProgress': 3, 'resolved': 12, 'total': 15};
  }
}
