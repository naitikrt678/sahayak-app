import 'package:shared_preferences/shared_preferences.dart';
import 'environment_service.dart';

class SettingsService {
  static const String _mockDataKey = 'use_mock_data';
  static const String _acceptTestUpdatesKey = 'accept_admin_test_updates';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _realtimeEnabledKey = 'realtime_enabled';
  static const String _fileCompressionKey = 'file_compression_enabled';

  /// Mock Data Settings
  static Future<bool> getMockDataEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to environment setting if not explicitly set
    return prefs.getBool(_mockDataKey) ?? EnvironmentService.useMockData;
  }

  static Future<void> setMockDataEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mockDataKey, enabled);
  }

  /// Accept Admin Test Updates Setting
  static Future<bool> getAcceptTestUpdatesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptTestUpdatesKey) ?? false;
  }

  static Future<void> setAcceptTestUpdatesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptTestUpdatesKey, enabled);
  }

  /// Notifications Settings
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Realtime Updates Settings
  static Future<bool> getRealtimeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_realtimeEnabledKey) ?? true;
  }

  static Future<void> setRealtimeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_realtimeEnabledKey, enabled);
  }

  /// File Compression Settings
  static Future<bool> getFileCompressionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fileCompressionKey) ?? false; // Default OFF
  }

  static Future<void> setFileCompressionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fileCompressionKey, enabled);
  }

  /// Get all settings as a map
  static Future<Map<String, bool>> getAllSettings() async {
    return {
      'mockData': await getMockDataEnabled(),
      'acceptTestUpdates': await getAcceptTestUpdatesEnabled(),
      'notifications': await getNotificationsEnabled(),
      'realtime': await getRealtimeEnabled(),
      'fileCompression': await getFileCompressionEnabled(),
    };
  }

  /// Check if app should use live data (not mock)
  static Future<bool> shouldUseLiveData() async {
    final useMockData = await getMockDataEnabled();
    return !useMockData;
  }

  /// Check if app should accept realtime updates even with mock data
  static Future<bool> shouldAcceptRealtimeUpdates() async {
    final acceptTestUpdates = await getAcceptTestUpdatesEnabled();
    final useMockData = await getMockDataEnabled();

    // Accept realtime if:
    // - Using live data OR
    // - Using mock data but accepting test updates
    return !useMockData || acceptTestUpdates;
  }
}
