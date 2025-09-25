import 'package:flutter/material.dart';
import '../services/supabase_status_service.dart';
import '../services/environment_service.dart';

class SupabaseStatusCard extends StatefulWidget {
  const SupabaseStatusCard({super.key});

  @override
  State<SupabaseStatusCard> createState() => _SupabaseStatusCardState();
}

class _SupabaseStatusCardState extends State<SupabaseStatusCard> {
  SupabaseHealthStatus? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await SupabaseStatusService.getHealthStatus();
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              const Icon(Icons.storage, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Database Connection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Supabase Status Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage, size: 20, color: Colors.black87),
                    const SizedBox(width: 8),
                    const Text(
                      'Supabase Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_status != null) ...[
                  // Connection Status
                  _buildStatusRow(
                    'Connection',
                    _status!.connection.isConnected,
                    _status!.connection.message,
                    Icons.wifi,
                  ),
                  const SizedBox(height: 12),

                  // Database Tables Section
                  const Text(
                    'Database Tables',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ..._status!.tables.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(entry.key, style: const TextStyle(fontSize: 13)),
                          const Spacer(),
                          _buildStatusIndicator(entry.value.isAccessible),
                          const SizedBox(width: 8),
                          _buildStatusBadge(entry.value.isAccessible),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 12),

                  // Overall Status
                  Row(
                    children: [
                      const Text(
                        'Overall Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      _buildStatusIndicator(_status!.isHealthy),
                      const SizedBox(width: 8),
                      _buildOverallStatusBadge(_status!.isHealthy),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Test Connection Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checkStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Test Connection'),
                    ),
                  ),
                ] else
                  const Center(
                    child: Text(
                      'Failed to load status',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                const SizedBox(height: 12),

                // Configuration Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuration',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'URL: ${_maskUrl(EnvironmentService.supabaseUrl)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Bucket: ${EnvironmentService.reportsBucket}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                      if (_status != null)
                        Text(
                          'Last checked: ${_formatDateTime(_status!.lastChecked)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    bool isHealthy,
    String message,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isHealthy ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        _buildStatusIndicator(isHealthy),
        const SizedBox(width: 8),
        _buildStatusBadge(isHealthy),
      ],
    );
  }

  Widget _buildStatusIndicator(bool isHealthy) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusBadge(bool isHealthy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isHealthy ? 'OK' : 'ERROR',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOverallStatusBadge(bool isHealthy) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isHealthy ? 'Ready' : 'Issues',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  String _maskUrl(String url) {
    if (url.length <= 20) return url;
    return '${url.substring(0, 15)}...${url.substring(url.length - 10)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
