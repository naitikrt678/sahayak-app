import 'package:flutter/material.dart';
import 'dart:io';
import '../models/civic_report.dart';
import '../services/local_storage_service.dart';
import '../services/data_service.dart';
import '../services/upload_queue_service.dart';
import '../services/upload_service.dart';
import 'report_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CivicReport> _reports = [];
  List<UploadQueueItem> _failedUploads = [];
  bool _isLoading = true;
  bool _showFailedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = mounted
          ? await DataService.getAllReports()
          : <CivicReport>[];

      // Load failed uploads from queue
      final failedItems = await UploadQueueService.getFailedUploads();

      if (mounted) {
        setState(() {
          _reports = reports;
          _failedUploads = failedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reports = [];
          _failedUploads = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Issue History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _showFailedOnly = value == 'failed';
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Show All')),
              PopupMenuItem(
                value: 'failed',
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Failed Uploads (${_failedUploads.length})'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _showFailedOnly
          ? _buildFailedUploadsList()
          : (_reports.isEmpty && _failedUploads.isEmpty)
          ? _buildEmptyState()
          : _buildCombinedList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No Reports Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Start reporting civic issues to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length + _failedUploads.length,
      itemBuilder: (context, index) {
        if (index < _failedUploads.length) {
          // Show failed upload
          final failedUpload = _failedUploads[index];
          return _buildFailedUploadCard(failedUpload);
        } else {
          // Show regular report
          final reportIndex = index - _failedUploads.length;
          final report = _reports[reportIndex];
          return _buildReportCard(report);
        }
      },
    );
  }

  Widget _buildFailedUploadsList() {
    if (_failedUploads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 100, color: Colors.green[400]),
              const SizedBox(height: 20),
              Text(
                'No Failed Uploads',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'All your reports have been uploaded successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _failedUploads.length,
      itemBuilder: (context, index) {
        final failedUpload = _failedUploads[index];
        return _buildFailedUploadCard(failedUpload);
      },
    );
  }

  Widget _buildFailedUploadCard(UploadQueueItem failedUpload) {
    return GestureDetector(
      onTap: () => _navigateToReportDetail(failedUpload: failedUpload),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FAILED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(failedUpload.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                failedUpload.report.category.isNotEmpty
                    ? failedUpload.report.category
                    : 'General Issue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                failedUpload.report.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Upload Error',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      failedUpload.lastError ?? 'Unknown error',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                    if (failedUpload.retryCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Retry attempts: ${failedUpload.retryCount}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _retryUpload(failedUpload),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _deleteFailedUpload(failedUpload),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(CivicReport report) {
    final progress = DataService.getReportProgress(report);

    return GestureDetector(
      onTap: () => _navigateToReportDetail(report: report),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(progress['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      progress['status'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(report.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.category.isNotEmpty ? report.category : 'General Issue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              if (report.address.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress['progress'],
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(progress['status']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReportDetail({
    CivicReport? report,
    UploadQueueItem? failedUpload,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReportDetailScreen(report: report, failedUpload: failedUpload),
      ),
    );
  }

  Future<void> _retryUpload(UploadQueueItem failedUpload) async {
    try {
      // Reset the failed upload to pending status
      await UploadQueueService.retryFailedUploads();

      // Reload the screen
      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload retry initiated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFailedUpload(UploadQueueItem failedUpload) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Failed Upload'),
        content: const Text(
          'Are you sure you want to delete this failed upload? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Remove from queue by clearing completed uploads
        await UploadQueueService.clearCompletedUploads();
        await _loadReports();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed upload deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete upload: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
