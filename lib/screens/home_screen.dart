import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/media_service.dart';
import '../models/civic_report.dart';
import '../services/local_storage_service.dart';
import '../services/data_service.dart';
import '../services/upload_queue_service.dart';
import 'photo_location_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'civic_officers_screen.dart';

enum ImageSourceType { camera, gallery }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Nagrik';
  List<CivicReport> _recentReports = [];
  int _unreadNotifications = 0;
  Map<String, int> _statistics = {'inProgress': 0, 'resolved': 0, 'total': 0};
  QueueStatus? _uploadStatus;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStatusUpdates() {
    // Update upload status every 2 seconds when there are active uploads
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final queueStatus = await UploadQueueService.getQueueStatus();
      if (mounted) {
        setState(() {
          _uploadStatus = queueStatus;
        });

        // If no active uploads, reduce update frequency
        if (!queueStatus.isActive) {
          timer.cancel();
          _statusUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
            timer,
          ) async {
            if (!mounted) {
              timer.cancel();
              return;
            }
            final status = await UploadQueueService.getQueueStatus();
            if (mounted) {
              setState(() {
                _uploadStatus = status;
              });
              if (status.isActive) {
                timer.cancel();
                _startStatusUpdates(); // Resume frequent updates
              }
            }
          });
        }
      }
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Nagrik';
    setState(() {
      _userName = name;
    });
  }

  Future<void> _loadData() async {
    try {
      // Load recent reports using DataService (handles mock vs live)
      final reports = await DataService.getRecentReports();
      setState(() {
        _recentReports = reports;
      });

      // Load notifications count
      final unreadCount =
          await LocalStorageService.getUnreadNotificationCount();
      setState(() {
        _unreadNotifications = unreadCount;
      });

      // Load upload queue status
      final queueStatus = await UploadQueueService.getQueueStatus();
      setState(() {
        _uploadStatus = queueStatus;
      });

      // Load statistics
      final stats = DataService.getStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      // Remove print and use proper error handling
      // Use dummy data on error
      final dummyReports = await DataService.getAllReports();
      final stats = DataService.getStatistics();
      setState(() {
        _recentReports = dummyReports.take(5).toList();
        _statistics = stats;
        _unreadNotifications = 3; // Default dummy count
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _handleImageSource(ImageSourceType.camera),
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _handleImageSource(ImageSourceType.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSource(ImageSourceType sourceType) async {
    Navigator.pop(context); // Close the bottom sheet

    File? imageFile;

    if (sourceType == ImageSourceType.camera) {
      // Request camera permission and take photo
      bool hasPermission = await MediaService.requestCameraPermission();
      if (hasPermission) {
        imageFile = await MediaService.takePhoto();
      } else {
        _showPermissionDeniedDialog('Camera');
        return;
      }
    } else {
      // Request gallery permission and pick image
      bool hasPermission = await MediaService.requestGalleryPermission();
      if (hasPermission) {
        imageFile = await MediaService.pickFromGallery();
      } else {
        _showPermissionDeniedDialog('Gallery');
        return;
      }
    }

    if (imageFile != null) {
      // Create a new civic report and navigate to photo location screen
      CivicReport report = CivicReport(image: imageFile);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoLocationScreen(report: report),
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType Permission Required'),
          content: Text('Please allow $permissionType access to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    final hasActiveUploads = _uploadStatus?.isActive ?? false;
    final uploadingCount = _uploadStatus?.uploading ?? 0;
    final pendingCount = _uploadStatus?.pending ?? 0;
    final totalActive = _uploadStatus?.active ?? 0;

    return Stack(
      children: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications, color: Colors.black54),
              // Upload progress indicator
              if (hasActiveUploads)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: uploadingCount > 0
                          ? Colors.orange
                          : const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            if (hasActiveUploads) {
              _showUploadProgressDialog();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            }
          },
        ),
        // Notification badge for unread notifications (when no active uploads)
        if (_unreadNotifications > 0 && !hasActiveUploads)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadNotifications.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        // Upload progress badge (takes priority over notification badge)
        if (hasActiveUploads)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: uploadingCount > 0
                    ? Colors.orange
                    : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                totalActive.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showUploadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: (_uploadStatus?.uploading ?? 0) > 0
                        ? Colors.orange
                        : const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Upload Progress',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_uploadStatus != null) ...[
                      _buildUploadStatusItem(
                        'Uploading',
                        _uploadStatus!.uploading,
                        Colors.orange,
                        Icons.cloud_upload,
                      ),
                      _buildUploadStatusItem(
                        'Pending',
                        _uploadStatus!.pending,
                        Colors.blue,
                        Icons.schedule,
                      ),
                      _buildUploadStatusItem(
                        'Retrying',
                        _uploadStatus!.retrying,
                        Colors.amber,
                        Icons.refresh,
                      ),
                      if (_uploadStatus!.failed > 0)
                        _buildUploadStatusItem(
                          'Failed',
                          _uploadStatus!.failed,
                          Colors.red,
                          Icons.error,
                        ),
                      const SizedBox(height: 16),
                      // Overall progress bar
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _uploadStatus!.total > 0
                              ? _uploadStatus!.completed / _uploadStatus!.total
                              : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_uploadStatus!.completed} of ${_uploadStatus!.total} completed',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ] else ...[
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
              actions: [
                if ((_uploadStatus?.failed ?? 0) > 0)
                  TextButton(
                    onPressed: () async {
                      await UploadQueueService.retryFailedUploads();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Retry Failed'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: const Text('View Notifications'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUploadStatusItem(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8), // Light green background
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E8),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey[600], size: 20),
            const SizedBox(width: 4),
            const Text(
              'Sahayak',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
        actions: [_buildNotificationButton()],
      ),
      body: Stack(
        children: [
          // Background logo with transparency
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Section
                Text(
                  'Hello, $_userName!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Voice for a Better India',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // Quick Action Tiles
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionTile(
                        title: 'Report Problem',
                        icon: Icons.camera_alt,
                        color: const Color(0xFF4CAF50),
                        onTap: _showImageSourceDialog,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildProgressStatusTile()),
                  ],
                ),
                const SizedBox(height: 16),

                // Issue Map and Civic Officers Row
                Row(
                  children: [
                    Expanded(child: _buildIssueMapTile()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCivicOfficersTile()),
                  ],
                ),

                const SizedBox(height: 30),

                // Recent Issues Section
                _buildRecentIssuesSection(),

                const SizedBox(height: 30),

                // Footer
                const Center(
                  child: Text(
                    'www.sahayakindia.com',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatusTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        );
      },
      child: Container(
        height: 120,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Progress Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Amazon-style progress bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.66, // 66% progress
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Progress stages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressStage('Dispatched', true),
                  _buildProgressStage('Working', true),
                  _buildProgressStage('Done', false),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_statistics['inProgress']} in progress',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStage(String label, bool isActive) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        color: isActive ? const Color(0xFF4CAF50) : Colors.grey[500],
      ),
    );
  }

  Widget _buildIssueMapTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      },
      child: Container(
        height: 120,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.map, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Issue Map',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'View all issues',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCivicOfficersTile() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CivicOfficersScreen()),
        );
      },
      child: Container(
        height: 120,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Civic Officers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Contact officers',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentIssuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Issues',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentReports.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
              children: [
                Icon(Icons.report, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No recent issues',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start reporting to see your issues here',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              ..._recentReports
                  .take(5)
                  .map((report) => _buildRecentIssueCard(report)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentIssueCard(CivicReport report) {
    final progress = DataService.getReportProgress(report);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(progress['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress['status'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(report.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.category.isNotEmpty ? report.category : 'General Issue',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Dispatched':
        return Colors.orange;
      case 'Working':
        return Colors.blue;
      case 'Done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
