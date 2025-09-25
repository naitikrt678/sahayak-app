import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class RealtimeService {
  static RealtimeChannel? _reportsChannel;
  static bool _isSubscribed = false;
  static List<int> _userReportIds = [];

  static bool get isSubscribed => _isSubscribed;

  /// Subscribe to realtime updates for reports table
  static Future<bool> subscribeToReports({List<int>? userReportIds}) async {
    try {
      if (!SupabaseService.isAvailable) {
        print('Supabase service not available for realtime');
        return false;
      }

      // Store user's report IDs for filtering
      _userReportIds = userReportIds ?? [];

      // Unsubscribe from existing channel if any
      await unsubscribeFromReports();

      // Create new realtime channel
      _reportsChannel = SupabaseService.subscribeToReports(_handleReportChange);

      _isSubscribed = true;
      print('Subscribed to reports realtime updates');
      return true;
    } catch (e) {
      print('Failed to subscribe to realtime updates: $e');
      _isSubscribed = false;
      return false;
    }
  }

  /// Handle realtime report changes
  static void _handleReportChange(PostgresChangePayload payload) {
    try {
      print('Received realtime update: ${payload.eventType}');

      switch (payload.eventType) {
        case PostgresChangeEvent.update:
          _handleReportUpdate(payload);
          break;
        case PostgresChangeEvent.insert:
          _handleReportInsert(payload);
          break;
        case PostgresChangeEvent.delete:
          _handleReportDelete(payload);
          break;
        default:
          print('Unhandled event type: ${payload.eventType}');
      }
    } catch (e) {
      print('Error handling realtime change: $e');
    }
  }

  /// Handle report update events
  static void _handleReportUpdate(PostgresChangePayload payload) {
    try {
      final newData = payload.newRecord;
      final oldData = payload.oldRecord;

      if (newData == null) return;

      final requestId = newData['request_id'] as int?;
      if (requestId == null) return;

      // Check if this is a user's report
      if (_userReportIds.isNotEmpty && !_userReportIds.contains(requestId)) {
        return; // Not user's report, ignore
      }

      final newStatus = newData['status'] as String?;
      final oldStatus = oldData?['status'] as String?;

      // Check if status changed
      if (newStatus != null && newStatus != oldStatus) {
        _showStatusUpdateNotification(requestId, newStatus, newData);
      }
    } catch (e) {
      print('Error handling report update: $e');
    }
  }

  /// Handle report insert events
  static void _handleReportInsert(PostgresChangePayload payload) {
    try {
      final newData = payload.newRecord;
      if (newData == null) return;

      final requestId = newData['request_id'] as int?;
      final category = newData['category'] as String?;

      if (requestId != null && category != null) {
        print('New report inserted: $requestId - $category');
        // Could show notification for new reports if needed
      }
    } catch (e) {
      print('Error handling report insert: $e');
    }
  }

  /// Handle report delete events
  static void _handleReportDelete(PostgresChangePayload payload) {
    try {
      final oldData = payload.oldRecord;
      if (oldData == null) return;

      final requestId = oldData['request_id'] as int?;
      if (requestId != null) {
        print('Report deleted: $requestId');
        // Could show notification for deleted reports if needed
      }
    } catch (e) {
      print('Error handling report delete: $e');
    }
  }

  /// Show notification for status updates
  static Future<void> _showStatusUpdateNotification(
    int requestId,
    String newStatus,
    Map<String, dynamic> reportData,
  ) async {
    try {
      final category = reportData['category'] as String? ?? 'Report';

      String title;
      String message;

      switch (newStatus.toLowerCase()) {
        case 'in-process':
          title = 'Report In Progress';
          message = 'Your $category report is now being processed';
          break;
        case 'completed':
          title = 'Report Completed';
          message = 'Your $category report has been resolved';
          break;
        case 'rejected':
          title = 'Report Update';
          message = 'There was an update to your $category report';
          break;
        default:
          title = 'Report Update';
          message = 'Your $category report status changed to $newStatus';
      }

      // Show local notification
      await NotificationService.showReportStatusUpdate(
        title: title,
        message: message,
        reportId: requestId.toString(),
      );

      print('Notification sent for report $requestId: $newStatus');
    } catch (e) {
      print('Error showing status update notification: $e');
    }
  }

  /// Update user's report IDs for filtering
  static void updateUserReportIds(List<int> reportIds) {
    _userReportIds = reportIds;
    print('Updated user report IDs: $_userReportIds');
  }

  /// Add a new report ID to track
  static void addUserReportId(int reportId) {
    if (!_userReportIds.contains(reportId)) {
      _userReportIds.add(reportId);
      print('Added report ID to track: $reportId');
    }
  }

  /// Unsubscribe from realtime updates
  static Future<void> unsubscribeFromReports() async {
    try {
      if (_reportsChannel != null) {
        await _reportsChannel!.unsubscribe();
        _reportsChannel = null;
        _isSubscribed = false;
        print('Unsubscribed from reports realtime updates');
      }
    } catch (e) {
      print('Error unsubscribing from realtime updates: $e');
    }
  }

  /// Check realtime connection status
  static bool get isConnected {
    if (_reportsChannel == null || !_isSubscribed) {
      return false;
    }

    // Check if the channel is in a connected state
    try {
      // If we can access the channel and it's subscribed, consider it connected
      return _isSubscribed && SupabaseService.isAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Get connection state
  static String get connectionState {
    if (!SupabaseService.isAvailable) {
      return 'Supabase Unavailable';
    }

    if (_isSubscribed && _reportsChannel != null) {
      return 'Connected';
    } else if (_isSubscribed) {
      return 'Connecting...';
    } else {
      return 'Disconnected';
    }
  }

  /// Dispose all realtime resources
  static Future<void> dispose() async {
    await unsubscribeFromReports();
    _userReportIds.clear();
  }

  /// Force reconnect realtime service
  static Future<bool> reconnect() async {
    try {
      await unsubscribeFromReports();
      await Future.delayed(const Duration(milliseconds: 500));
      return await subscribeToReports(userReportIds: _userReportIds);
    } catch (e) {
      print('Failed to reconnect realtime service: $e');
      return false;
    }
  }

  /// Check if realtime should be enabled based on settings
  static Future<bool> shouldBeEnabled() async {
    try {
      return await SettingsService.getRealtimeEnabled();
    } catch (e) {
      return true; // Default to enabled if can't check
    }
  }
}
