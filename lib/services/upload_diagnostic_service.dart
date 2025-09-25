import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/environment_service.dart';
import '../services/supabase_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/supabase_reports_service.dart';
import '../services/settings_service.dart';

class UploadDiagnosticService {
  /// Run comprehensive upload diagnostics
  static Future<DiagnosticResult> runDiagnostics() async {
    final results = <DiagnosticCheck>[];

    try {
      // 1. Environment Configuration Check
      results.add(await _checkEnvironmentConfig());

      // 2. Supabase Connection Check
      results.add(await _checkSupabaseConnection());

      // 3. App Settings Check
      results.add(await _checkAppSettings());

      // 4. Storage Bucket Check
      results.add(await _checkStorageBucket());

      // 5. Database Connection Check
      results.add(await _checkDatabaseConnection());

      // 6. Upload Test
      results.add(await _testFileUpload());

      final passed = results.where((r) => r.passed).length;
      final total = results.length;

      return DiagnosticResult(
        checks: results,
        overallScore: passed / total,
        canUpload: results.every((r) => r.passed || !r.critical),
      );
    } catch (e) {
      results.add(
        DiagnosticCheck(
          name: 'Diagnostic Error',
          passed: false,
          critical: true,
          message: 'Failed to run diagnostics: $e',
          solution: 'Check app permissions and network connection',
        ),
      );

      return DiagnosticResult(
        checks: results,
        overallScore: 0.0,
        canUpload: false,
      );
    }
  }

  static Future<DiagnosticCheck> _checkEnvironmentConfig() async {
    try {
      await EnvironmentService.initialize();

      if (!EnvironmentService.hasValidSupabaseConfig) {
        return DiagnosticCheck(
          name: 'Environment Configuration',
          passed: false,
          critical: true,
          message: 'Missing Supabase configuration',
          solution: 'Check .env file has SUPABASE_URL and SUPABASE_ANON_KEY',
          details: EnvironmentService.configStatus,
        );
      }

      return DiagnosticCheck(
        name: 'Environment Configuration',
        passed: true,
        critical: true,
        message: 'Environment loaded successfully',
        details: 'URL: ${EnvironmentService.supabaseUrl.substring(0, 30)}...',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'Environment Configuration',
        passed: false,
        critical: true,
        message: 'Failed to load environment: $e',
        solution: 'Ensure .env file exists and is properly formatted',
      );
    }
  }

  static Future<DiagnosticCheck> _checkSupabaseConnection() async {
    try {
      final initialized = await SupabaseService.initialize();

      if (!initialized || !SupabaseService.isAvailable) {
        return DiagnosticCheck(
          name: 'Supabase Connection',
          passed: false,
          critical: true,
          message: 'Failed to connect to Supabase',
          solution:
              'Check Supabase URL and API key, verify internet connection',
        );
      }

      return DiagnosticCheck(
        name: 'Supabase Connection',
        passed: true,
        critical: true,
        message: 'Connected to Supabase successfully',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'Supabase Connection',
        passed: false,
        critical: true,
        message: 'Supabase connection error: $e',
        solution:
            'Verify Supabase project is active and credentials are correct',
      );
    }
  }

  static Future<DiagnosticCheck> _checkAppSettings() async {
    try {
      final useMockData = await SettingsService.getMockDataEnabled();

      if (useMockData) {
        return DiagnosticCheck(
          name: 'App Settings',
          passed: false,
          critical: false,
          message: 'App is in Mock Mode - uploads will be local only',
          solution: 'Go to Profile → Settings and turn OFF "Use Mock Data"',
          details: 'Mock mode saves reports locally instead of uploading',
        );
      }

      return DiagnosticCheck(
        name: 'App Settings',
        passed: true,
        critical: false,
        message: 'App is in Live Mode - ready for uploads',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'App Settings',
        passed: false,
        critical: false,
        message: 'Failed to check app settings: $e',
        solution: 'Try restarting the app',
      );
    }
  }

  static Future<DiagnosticCheck> _checkStorageBucket() async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase not available');
      }

      final canAccess = await SupabaseStorageService.testStorageConnection();

      if (!canAccess) {
        return DiagnosticCheck(
          name: 'Storage Bucket',
          passed: false,
          critical: true,
          message: 'Cannot access "reports" storage bucket',
          solution: 'Create "reports" bucket in Supabase Dashboard → Storage',
          details: 'Bucket must be public for file access',
        );
      }

      return DiagnosticCheck(
        name: 'Storage Bucket',
        passed: true,
        critical: true,
        message: 'Storage bucket is accessible',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'Storage Bucket',
        passed: false,
        critical: true,
        message: 'Storage bucket test failed: $e',
        solution: 'Check if "reports" bucket exists and is publicly accessible',
      );
    }
  }

  static Future<DiagnosticCheck> _checkDatabaseConnection() async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase not available');
      }

      // Try to query the reports table structure
      final result = await SupabaseService.client
          .from('reports')
          .select('id')
          .limit(1);

      return DiagnosticCheck(
        name: 'Database Connection',
        passed: true,
        critical: true,
        message: 'Database is accessible',
        details: 'Reports table exists and is queryable',
      );
    } catch (e) {
      String solution = 'Create reports table using DATABASE_SCHEMA.sql';
      String details = e.toString();

      if (e.toString().contains('relation "reports" does not exist')) {
        solution = 'Run CREATE TABLE reports... in Supabase SQL Editor';
        details = 'Reports table is missing from database';
      } else if (e.toString().contains('row-level security')) {
        solution = 'Configure RLS policies or disable RLS for testing';
        details = 'Row Level Security is blocking access';
      }

      return DiagnosticCheck(
        name: 'Database Connection',
        passed: false,
        critical: true,
        message: 'Database access failed',
        solution: solution,
        details: details,
      );
    }
  }

  static Future<DiagnosticCheck> _testFileUpload() async {
    try {
      if (!SupabaseService.isAvailable) {
        throw Exception('Supabase not available');
      }

      // Create a tiny test image (1x1 pixel PNG)
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x37, 0x6E, 0xF9, 0x24, 0x00, 0x00,
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND chunk
        0x60, 0x82,
      ]);

      final testFilename =
          'diagnostic_test_${DateTime.now().millisecondsSinceEpoch}.png';

      // Test image upload
      final imageUrl = await SupabaseStorageService.uploadImage(
        imageBytes: testImageBytes,
        filename: testFilename,
      );

      // Clean up test file
      await SupabaseStorageService.deleteFile('reports/${testFilename}');

      return DiagnosticCheck(
        name: 'File Upload Test',
        passed: true,
        critical: false,
        message: 'File upload successful',
        details: 'Test image uploaded and cleaned up successfully',
      );
    } catch (e) {
      String solution = 'Check storage bucket permissions and network connection';
      String details = e.toString();
      
      // Provide specific solutions for common RLS issues
      if (e.toString().contains('row-level security') ||
          e.toString().contains('policy') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('403')) {
        solution = 'Fix Supabase RLS policies: Run the SQL script in supabase_storage_fix.sql '
                  'in your Supabase SQL Editor, or disable RLS on storage.objects table';
        details = 'Row-Level Security is blocking anonymous uploads. '
                 'Either add RLS policies for anonymous users or disable RLS.';
      } else if (e.toString().contains('not found') || e.toString().contains('does not exist')) {
        solution = 'Create "reports" bucket in Supabase Dashboard → Storage';
        details = 'Storage bucket "reports" does not exist';
      }
      
      return DiagnosticCheck(
        name: 'File Upload Test',
        passed: false,
        critical: false,
        message: 'File upload test failed: ${e.toString().split(':').first}',
        solution: solution,
        details: details,
      );
    }
  }
}

class DiagnosticResult {
  final List<DiagnosticCheck> checks;
  final double overallScore;
  final bool canUpload;

  DiagnosticResult({
    required this.checks,
    required this.overallScore,
    required this.canUpload,
  });

  int get passedCount => checks.where((c) => c.passed).length;
  int get failedCount => checks.where((c) => !c.passed).length;
  int get criticalFailures =>
      checks.where((c) => !c.passed && c.critical).length;

  String get summary {
    if (overallScore == 1.0) {
      return '✅ All systems operational';
    } else if (canUpload) {
      return '⚠️ Minor issues detected but uploads should work';
    } else {
      return '❌ Critical issues preventing uploads';
    }
  }
}

class DiagnosticCheck {
  final String name;
  final bool passed;
  final bool critical;
  final String message;
  final String? solution;
  final String? details;

  DiagnosticCheck({
    required this.name,
    required this.passed,
    required this.critical,
    required this.message,
    this.solution,
    this.details,
  });

  IconData get icon {
    if (passed) return Icons.check_circle;
    if (critical) return Icons.error;
    return Icons.warning;
  }

  Color get color {
    if (passed) return Colors.green;
    if (critical) return Colors.red;
    return Colors.orange;
  }
}
