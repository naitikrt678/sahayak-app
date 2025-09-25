import '../models/civic_report.dart';
import 'supabase_service.dart';

class SupabaseReportsService {
  // Valid status values for reports table
  static const List<String> validReportStatuses = [
    'pending',
    'in-process',
    'completed',
  ];

  // Valid urgency values for reports table
  static const List<String> validUrgencyLevels = [
    'low',
    'medium',
    'high',
    'critical',
  ];

  // Valid status values for dispatched_workers table
  static const List<String> validDispatchedWorkerStatuses = [
    'active',
    'completed',
    'delayed',
  ];

  /// Validate report status
  static bool isValidReportStatus(String status) {
    return validReportStatuses.contains(status);
  }

  /// Validate urgency level
  static bool isValidUrgencyLevel(String urgency) {
    return validUrgencyLevels.contains(urgency);
  }

  /// Validate dispatched worker status
  static bool isValidDispatchedWorkerStatus(String status) {
    return validDispatchedWorkerStatuses.contains(status);
  }

  /// Insert a new report into the Supabase reports table
  static Future<Map<String, dynamic>?> insertReport({
    required String category,
    required String area,
    required String time,
    required String date,
    required String description,
    required double geolocationLat,
    required double geolocationLong,
    required String address,
    required String urgency,
    required String imageUrl,
    String? voiceUrl,
    String? additionalNotes,
    String? landmarks,
    String status = 'pending',
  }) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      // Validate status and urgency values
      if (!isValidReportStatus(status)) {
        throw Exception(
          'Invalid status: $status. Must be one of: ${validReportStatuses.join(", ")}',
        );
      }

      if (!isValidUrgencyLevel(urgency)) {
        throw Exception(
          'Invalid urgency: $urgency. Must be one of: ${validUrgencyLevels.join(", ")}',
        );
      }

      // Validate coordinate precision (ensure they fit DECIMAL(10,8) and DECIMAL(11,8))
      if (geolocationLat.abs() > 90) {
        throw Exception(
          'Invalid latitude: $geolocationLat. Must be between -90 and 90',
        );
      }

      if (geolocationLong.abs() > 180) {
        throw Exception(
          'Invalid longitude: $geolocationLong. Must be between -180 and 180',
        );
      }

      final reportData = {
        'category': category,
        'area': area,
        'time': time,
        'date': date,
        'status': status,
        'description': description,
        'geolocation_lat': geolocationLat,
        'geolocation_long': geolocationLong,
        'address': address,
        'urgency': urgency,
        'image_url': imageUrl,
        if (voiceUrl != null) 'voice_url': voiceUrl,
        if (additionalNotes != null) 'additional_notes': additionalNotes,
        if (landmarks != null) 'landmarks': landmarks,
        // Don't set request_id or serial_number - let DB generate them
      };

      final response = await SupabaseService.reports
          .insert(reportData)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Failed to insert report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports
  static Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final response = await SupabaseService.reports.select().order(
        'created_at',
        ascending: false,
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch reports: $e');
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get reports by status
  static Future<List<Map<String, dynamic>>> getReportsByStatus(
    String status,
  ) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final response = await SupabaseService.reports
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch reports by status: $e');
      throw Exception('Failed to fetch reports by status: $e');
    }
  }

  /// Get report by ID (supports both id and request_id)
  static Future<Map<String, dynamic>?> getReportById(dynamic reportId) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      // Try by id first (admin portal compatibility), then by request_id (citizen app)
      Map<String, dynamic>? response;

      if (reportId is int) {
        // Try request_id first for integer IDs
        response = await SupabaseService.reports
            .select()
            .eq('request_id', reportId)
            .maybeSingle();

        // If not found, try id field
        if (response == null) {
          response = await SupabaseService.reports
              .select()
              .eq('id', reportId)
              .maybeSingle();
        }
      } else {
        // For non-integer IDs, try id field
        response = await SupabaseService.reports
            .select()
            .eq('id', reportId)
            .maybeSingle();
      }

      return response;
    } catch (e) {
      print('Failed to fetch report by ID: $e');
      return null;
    }
  }

  /// Update report status (supports both id and request_id)
  static Future<bool> updateReportStatus(
    dynamic reportId,
    String newStatus,
  ) async {
    try {
      if (!SupabaseService.isAvailable) return false;

      // Validate new status
      if (!isValidReportStatus(newStatus)) {
        throw Exception(
          'Invalid status: $newStatus. Must be one of: ${validReportStatuses.join(", ")}',
        );
      }

      // Try to update by request_id first, then by id
      var affectedRows = 0;

      if (reportId is int) {
        // Try request_id first for integer IDs
        final response1 = await SupabaseService.reports
            .update({'status': newStatus})
            .eq('request_id', reportId)
            .select('id');

        affectedRows = response1.length;

        // If no rows affected, try id field
        if (affectedRows == 0) {
          final response2 = await SupabaseService.reports
              .update({'status': newStatus})
              .eq('id', reportId)
              .select('id');
          affectedRows = response2.length;
        }
      } else {
        // For non-integer IDs, try id field
        final response = await SupabaseService.reports
            .update({'status': newStatus})
            .eq('id', reportId)
            .select('id');
        affectedRows = response.length;
      }

      return affectedRows > 0;
    } catch (e) {
      print('Failed to update report status: $e');
      return false;
    }
  }

  /// Convert Supabase report data to CivicReport model
  static CivicReport mapSupabaseReportToCivicReport(Map<String, dynamic> data) {
    return CivicReport(
      id: data['request_id']?.toString(),
      serialNumber: data['serial_number'],
      requestId: data['request_id']?.toString(),
      imageUrl: data['image_url'],
      latitude: data['geolocation_lat']?.toDouble(),
      longitude: data['geolocation_long']?.toDouble(),
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      voiceNotes: data['voice_url'] ?? '',
      additionalNotes: data['additional_notes'] ?? '',
      category: data['category'] ?? '',
      area: data['area'] ?? '',
      time: data['time'] ?? '',
      date: data['date'] ?? '',
      status: data['status'] ?? 'pending',
      urgency: data['urgency'] ?? 'medium',
      landmarks: data['landmarks'],
      timestamp: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  /// Convert CivicReport model to Supabase format
  static Map<String, dynamic> mapCivicReportToSupabase(CivicReport report) {
    return {
      'category': report.category,
      'area': report.area,
      'time': report.time,
      'date': report.date,
      'status': report.status,
      'description': report.description,
      'geolocation_lat': report.latitude,
      'geolocation_long': report.longitude,
      'address': report.address,
      'urgency': report.urgency,
      'image_url': report.imageUrl ?? '',
      'voice_url': report.voiceNotes.isNotEmpty ? report.voiceNotes : null,
      'additional_notes': report.additionalNotes.isNotEmpty
          ? report.additionalNotes
          : null,
      'landmarks': report.landmarks,
    };
  }

  /// Get recent reports (last 10)
  static Future<List<CivicReport>> getRecentReports() async {
    try {
      final data = await SupabaseService.reports
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      return data
          .map(
            (item) =>
                mapSupabaseReportToCivicReport(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (e) {
      print('Failed to fetch recent reports: $e');
      return [];
    }
  }

  /// Test database connection
  static Future<bool> testConnection() async {
    try {
      if (!SupabaseService.isAvailable) return false;

      // Try a simple query
      await SupabaseService.reports.select('request_id').limit(1);
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  // ============================================
  // WORKERS TABLE OPERATIONS
  // ============================================

  /// Insert a new worker
  static Future<Map<String, dynamic>?> insertWorker({
    required String name,
    required String category,
    required String contact,
    required String area,
    bool available = true,
    String? id, // Optional ID for admin portal compatibility
  }) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final workerData = {
        'name': name,
        'category': category,
        'contact': contact,
        'area': area,
        'available': available,
      };

      // Add ID if provided (for admin portal compatibility)
      if (id != null) {
        workerData['id'] = id;
      }

      final response = await SupabaseService.client
          .from('workers')
          .insert(workerData)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Failed to insert worker: $e');
      throw Exception('Failed to create worker: $e');
    }
  }

  /// Get all workers
  static Future<List<Map<String, dynamic>>> getAllWorkers() async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final response = await SupabaseService.client.from('workers').select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch workers: $e');
      throw Exception('Failed to fetch workers: $e');
    }
  }

  /// Get available workers by category and area
  static Future<List<Map<String, dynamic>>> getAvailableWorkers({
    String? category,
    String? area,
  }) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      var query = SupabaseService.client
          .from('workers')
          .select()
          .eq('available', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (area != null) {
        query = query.eq('area', area);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch available workers: $e');
      throw Exception('Failed to fetch available workers: $e');
    }
  }

  /// Update worker availability
  static Future<bool> updateWorkerAvailability(
    String workerId, // Changed from int to String for TEXT ID compatibility
    bool available,
  ) async {
    try {
      if (!SupabaseService.isAvailable) return false;

      await SupabaseService.client
          .from('workers')
          .update({'available': available})
          .eq('id', workerId);

      return true;
    } catch (e) {
      print('Failed to update worker availability: $e');
      return false;
    }
  }

  // ============================================
  // DISPATCHED_WORKERS TABLE OPERATIONS
  // ============================================

  /// Dispatch a worker to a report
  static Future<Map<String, dynamic>?> dispatchWorker({
    required String workerId, // Changed to String for TEXT ID
    required dynamic reportId, // Support both int and String
    DateTime? estimatedCompletion,
    String status = 'active',
    int progress = 0,
    String? id, // Optional ID for admin portal compatibility
  }) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      // Validate dispatched worker status
      if (!isValidDispatchedWorkerStatus(status)) {
        throw Exception(
          'Invalid dispatched worker status: $status. Must be one of: ${validDispatchedWorkerStatuses.join(", ")}',
        );
      }

      // Validate progress range
      if (progress < 0 || progress > 100) {
        throw Exception(
          'Invalid progress: $progress. Must be between 0 and 100',
        );
      }

      // Determine the correct report ID to use
      dynamic actualReportId = reportId;
      if (reportId is int) {
        // For citizen app, find the actual database ID from request_id
        final report = await getReportById(reportId);
        if (report != null && report['id'] != null) {
          actualReportId = report['id'];
        }
      }

      final dispatchData = {
        'worker_id': workerId,
        'report_id': actualReportId,
        'estimated_completion': estimatedCompletion?.toIso8601String(),
        'status': status,
        'progress': progress,
      };

      // Add ID if provided (for admin portal compatibility)
      if (id != null) {
        dispatchData['id'] = id;
      }

      final response = await SupabaseService.client
          .from('dispatched_workers')
          .insert(dispatchData)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Failed to dispatch worker: $e');
      throw Exception('Failed to dispatch worker: $e');
    }
  }

  /// Update dispatched worker status and progress
  static Future<bool> updateDispatchedWorkerStatus(
    String dispatchId, // Changed to String for TEXT ID
    String newStatus, {
    int? progress,
    DateTime? estimatedCompletion,
  }) async {
    try {
      if (!SupabaseService.isAvailable) return false;

      // Validate new status
      if (!isValidDispatchedWorkerStatus(newStatus)) {
        throw Exception(
          'Invalid status: $newStatus. Must be one of: ${validDispatchedWorkerStatuses.join(", ")}',
        );
      }

      // Validate progress if provided
      if (progress != null && (progress < 0 || progress > 100)) {
        throw Exception(
          'Invalid progress: $progress. Must be between 0 and 100',
        );
      }

      final updateData = <String, dynamic>{'status': newStatus};

      if (progress != null) {
        updateData['progress'] = progress;
      }

      if (estimatedCompletion != null) {
        updateData['estimated_completion'] = estimatedCompletion
            .toIso8601String();
      }

      await SupabaseService.client
          .from('dispatched_workers')
          .update(updateData)
          .eq('id', dispatchId);

      return true;
    } catch (e) {
      print('Failed to update dispatched worker status: $e');
      return false;
    }
  }

  /// Get dispatched workers for a report
  static Future<List<Map<String, dynamic>>> getDispatchedWorkersForReport(
    dynamic reportId, // Support both int and String
  ) async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      // Determine the correct report ID to use
      dynamic actualReportId = reportId;
      if (reportId is int) {
        // For citizen app, find the actual database ID from request_id
        final report = await getReportById(reportId);
        if (report != null && report['id'] != null) {
          actualReportId = report['id'];
        }
      }

      final response = await SupabaseService.client
          .from('dispatched_workers')
          .select('*, workers(*)')
          .eq('report_id', actualReportId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch dispatched workers for report: $e');
      throw Exception('Failed to fetch dispatched workers for report: $e');
    }
  }

  /// Get all dispatched workers with their details
  static Future<List<Map<String, dynamic>>> getAllDispatchedWorkers() async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase service not available');
      }

      final response = await SupabaseService.client
          .from('dispatched_workers')
          .select('*, workers(*), reports(*)')
          .order('dispatched_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to fetch dispatched workers: $e');
      throw Exception('Failed to fetch dispatched workers: $e');
    }
  }
}
