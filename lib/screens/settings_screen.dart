import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../services/realtime_service.dart';
import '../services/supabase_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useMockData = false;
  bool _acceptTestUpdates = false;
  bool _notificationsEnabled = true;
  bool _realtimeEnabled = true;
  bool _fileCompressionEnabled = false;
  bool _isLoading = true;
  BucketValidationResult? _bucketStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.getAllSettings();
      final bucketStatus = await SupabaseStorageService.validateBucket();

      setState(() {
        _useMockData = settings['mockData'] ?? false;
        _acceptTestUpdates = settings['acceptTestUpdates'] ?? false;
        _notificationsEnabled = settings['notifications'] ?? true;
        _realtimeEnabled = settings['realtime'] ?? true;
        _fileCompressionEnabled = settings['fileCompression'] ?? false;
        _bucketStatus = bucketStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load settings: $e');
    }
  }

  Future<void> _updateMockDataSetting(bool value) async {
    try {
      await SettingsService.setMockDataEnabled(value);
      setState(() {
        _useMockData = value;
      });

      _showInfoSnackBar(
        value ? 'Switched to mock data mode' : 'Switched to live data mode',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update mock data setting: $e');
    }
  }

  Future<void> _updateTestUpdatesSetting(bool value) async {
    try {
      await SettingsService.setAcceptTestUpdatesEnabled(value);
      setState(() {
        _acceptTestUpdates = value;
      });

      _showInfoSnackBar(
        value
            ? 'Will accept admin test updates'
            : 'Will not accept admin test updates',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update test updates setting: $e');
    }
  }

  Future<void> _updateNotificationsSetting(bool value) async {
    try {
      await SettingsService.setNotificationsEnabled(value);
      setState(() {
        _notificationsEnabled = value;
      });

      _showInfoSnackBar(
        value ? 'Notifications enabled' : 'Notifications disabled',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update notifications setting: $e');
    }
  }

  Future<void> _updateRealtimeSetting(bool value) async {
    try {
      await SettingsService.setRealtimeEnabled(value);
      setState(() {
        _realtimeEnabled = value;
      });

      if (value) {
        // Re-subscribe to realtime if enabled
        await RealtimeService.subscribeToReports();
      } else {
        // Unsubscribe from realtime if disabled
        await RealtimeService.unsubscribeFromReports();
      }

      _showInfoSnackBar(
        value ? 'Realtime updates enabled' : 'Realtime updates disabled',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update realtime setting: $e');
    }
  }

  Future<void> _updateFileCompressionSetting(bool value) async {
    try {
      await SettingsService.setFileCompressionEnabled(value);
      setState(() {
        _fileCompressionEnabled = value;
      });

      _showInfoSnackBar(
        value ? 'File compression enabled' : 'File compression disabled',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to update file compression setting: $e');
    }
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    'Data Source',
                    'Configure how the app loads data',
                    [
                      _buildSwitchTile(
                        'Use Mock Data',
                        'Load data from local mock file instead of live server',
                        _useMockData,
                        _updateMockDataSetting,
                        Icons.data_usage,
                      ),
                      if (_useMockData)
                        _buildSwitchTile(
                          'Accept Admin Test Updates',
                          'Receive realtime updates even when using mock data',
                          _acceptTestUpdates,
                          _updateTestUpdatesSetting,
                          Icons.admin_panel_settings,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Notifications',
                    'Manage notification preferences',
                    [
                      _buildSwitchTile(
                        'Push Notifications',
                        'Receive notifications for report status updates',
                        _notificationsEnabled,
                        _updateNotificationsSetting,
                        Icons.notifications,
                      ),
                      _buildSwitchTile(
                        'Realtime Updates',
                        'Get instant updates when report status changes',
                        _realtimeEnabled,
                        _updateRealtimeSetting,
                        Icons.sync,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    'Upload Settings',
                    'Configure file upload behavior',
                    [
                      _buildSwitchTile(
                        'File Compression',
                        'Compress images and audio before upload (may fix upload issues)',
                        _fileCompressionEnabled,
                        _updateFileCompressionSetting,
                        Icons.compress,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildConnectionStatus(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String description,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Connection Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshConnectionStatus,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Status',
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                SupabaseService.isAvailable ? Icons.check_circle : Icons.error,
                color: SupabaseService.isAvailable ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Supabase: ${SupabaseService.isAvailable ? "Connected" : "Disconnected"}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                RealtimeService.isConnected ? Icons.sync : Icons.sync_disabled,
                color: RealtimeService.isConnected
                    ? Colors.green
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Realtime: ${RealtimeService.connectionState}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (!RealtimeService.isConnected && _realtimeEnabled)
                TextButton(
                  onPressed: _reconnectRealtime,
                  child: const Text('Reconnect'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _bucketStatus?.isFullyFunctional == true
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                color: _bucketStatus?.isFullyFunctional == true
                    ? Colors.green
                    : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage: ${_bucketStatus?.status ?? "Checking..."}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (_bucketStatus?.error != null)
                      Text(
                        _bucketStatus!.error!,
                        style: TextStyle(fontSize: 11, color: Colors.red[600]),
                      ),
                  ],
                ),
              ),
              if (_bucketStatus?.isFullyFunctional != true)
                TextButton(
                  onPressed: _refreshConnectionStatus,
                  child: const Text('Check Again'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bucketStatus = await SupabaseStorageService.validateBucket();
      setState(() {
        _bucketStatus = bucketStatus;
        _isLoading = false;
      });
      _showInfoSnackBar('Connection status refreshed');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to refresh status: $e');
    }
  }

  Future<void> _reconnectRealtime() async {
    try {
      _showInfoSnackBar('Reconnecting realtime...');
      final success = await RealtimeService.reconnect();

      if (success) {
        _showInfoSnackBar('Realtime reconnected successfully');
      } else {
        _showErrorSnackBar('Failed to reconnect realtime');
      }

      setState(() {}); // Refresh UI
    } catch (e) {
      _showErrorSnackBar('Error reconnecting: $e');
    }
  }
}
