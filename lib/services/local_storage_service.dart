import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/civic_report.dart';

class LocalStorageService {
  static const String _reportsKey = 'civic_reports';
  static const String _notificationsKey = 'notifications';

  // Store a new report
  static Future<void> storeReport(CivicReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getReports();

    // Add unique ID and generate report ID
    final reportWithId = report.copyWith(timestamp: DateTime.now());

    reports.add(reportWithId);

    // Convert to JSON
    final jsonList = reports.map((r) => _reportToJson(r)).toList();
    await prefs.setString(_reportsKey, jsonEncode(jsonList));

    // Create notification for new report
    await _addNotification('New report submitted: ${report.category}');
  }

  // Get all reports
  static Future<List<CivicReport>> getReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_reportsKey);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => _reportFromJson(json)).toList();
  }

  // Get recent reports (last 5)
  static Future<List<CivicReport>> getRecentReports() async {
    final reports = await getReports();
    reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return reports.take(5).toList();
  }

  // Store notifications
  static Future<void> _addNotification(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    notifications.insert(0, {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });

    // Keep only last 20 notifications
    if (notifications.length > 20) {
      notifications.removeRange(20, notifications.length);
    }

    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  // Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notificationsKey);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.cast<Map<String, dynamic>>();
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();

    if (index < notifications.length) {
      notifications[index]['read'] = true;
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => n['read'] == false).length;
  }

  // Convert CivicReport to JSON
  static Map<String, dynamic> _reportToJson(CivicReport report) {
    return {
      'imagePath': report.imagePath,
      'latitude': report.latitude,
      'longitude': report.longitude,
      'address': report.address,
      'description': report.description,
      'voiceNotes': report.voiceNotes,
      'additionalNotes': report.additionalNotes,
      'category': report.category,
      'timestamp': report.timestamp.toIso8601String(),
    };
  }

  // Convert JSON to CivicReport
  static CivicReport _reportFromJson(Map<String, dynamic> json) {
    return CivicReport(
      imagePath: json['imagePath'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'] ?? '',
      description: json['description'] ?? '',
      voiceNotes: json['voiceNotes'] ?? '',
      additionalNotes: json['additionalNotes'] ?? '',
      category: json['category'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
