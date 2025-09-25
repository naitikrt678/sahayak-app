import 'supabase_service.dart';
import 'supabase_storage_service.dart';
import 'environment_service.dart';

class SupabaseStatusService {
  /// Check overall Supabase connection status
  static Future<ConnectionStatus> checkConnectionStatus() async {
    try {
      if (!SupabaseService.isAvailable) {
        return ConnectionStatus(
          isConnected: false,
          message: 'Supabase service not configured',
          error: 'Missing environment configuration',
        );
      }

      // Test basic connection
      await SupabaseService.reports.select('request_id').limit(1);

      return ConnectionStatus(
        isConnected: true,
        message: 'Connected to Supabase',
      );
    } catch (e) {
      return ConnectionStatus(
        isConnected: false,
        message: 'Connection failed',
        error: e.toString(),
      );
    }
  }

  /// Check database table status
  static Future<Map<String, TableStatus>> checkDatabaseTables() async {
    final tables = <String, TableStatus>{};

    // Check reports table
    tables['reports'] = await _checkTable('reports', () async {
      return await SupabaseService.reports.select('request_id').limit(1);
    });

    // Check workers table
    tables['workers'] = await _checkTable('workers', () async {
      return await SupabaseService.client.from('workers').select('id').limit(1);
    });

    // Check dispatched_workers table
    tables['dispatched_workers'] = await _checkTable(
      'dispatched_workers',
      () async {
        return await SupabaseService.client
            .from('dispatched_workers')
            .select('id')
            .limit(1);
      },
    );

    return tables;
  }

  /// Check storage bucket status
  static Future<StorageStatus> checkStorageStatus() async {
    try {
      if (!SupabaseService.isAvailable) {
        return StorageStatus(
          isAvailable: false,
          message: 'Service not available',
        );
      }

      final isConnected = await SupabaseStorageService.testStorageConnection();

      return StorageStatus(
        isAvailable: isConnected,
        message: isConnected
            ? 'Storage accessible'
            : 'Storage connection failed',
        bucketName: EnvironmentService.reportsBucket,
      );
    } catch (e) {
      return StorageStatus(
        isAvailable: false,
        message: 'Storage error: ${e.toString()}',
        bucketName: EnvironmentService.reportsBucket,
      );
    }
  }

  /// Get comprehensive status
  static Future<SupabaseHealthStatus> getHealthStatus() async {
    final connection = await checkConnectionStatus();
    final tables = await checkDatabaseTables();
    final storage = await checkStorageStatus();

    final allTablesOk = tables.values.every((table) => table.isAccessible);
    final overallHealthy =
        connection.isConnected && allTablesOk && storage.isAvailable;

    return SupabaseHealthStatus(
      connection: connection,
      tables: tables,
      storage: storage,
      isHealthy: overallHealthy,
      lastChecked: DateTime.now(),
    );
  }

  /// Test connection with retry
  static Future<bool> testConnection() async {
    try {
      final status = await checkConnectionStatus();
      return status.isConnected;
    } catch (e) {
      return false;
    }
  }

  static Future<TableStatus> _checkTable(
    String tableName,
    Future<dynamic> Function() testQuery,
  ) async {
    try {
      if (!SupabaseService.isAvailable) {
        return TableStatus(
          isAccessible: false,
          message: 'Service not available',
          recordCount: 0,
        );
      }

      await testQuery();

      // Table is accessible if query succeeds
      return TableStatus(
        isAccessible: true,
        message: 'Accessible',
        recordCount: -1, // Use -1 to indicate count not available
      );
    } catch (e) {
      return TableStatus(
        isAccessible: false,
        message: 'Error: ${e.toString()}',
        recordCount: 0,
      );
    }
  }
}

class ConnectionStatus {
  final bool isConnected;
  final String message;
  final String? error;

  ConnectionStatus({
    required this.isConnected,
    required this.message,
    this.error,
  });
}

class TableStatus {
  final bool isAccessible;
  final String message;
  final int recordCount;

  TableStatus({
    required this.isAccessible,
    required this.message,
    required this.recordCount,
  });
}

class StorageStatus {
  final bool isAvailable;
  final String message;
  final String? bucketName;

  StorageStatus({
    required this.isAvailable,
    required this.message,
    this.bucketName,
  });
}

class SupabaseHealthStatus {
  final ConnectionStatus connection;
  final Map<String, TableStatus> tables;
  final StorageStatus storage;
  final bool isHealthy;
  final DateTime lastChecked;

  SupabaseHealthStatus({
    required this.connection,
    required this.tables,
    required this.storage,
    required this.isHealthy,
    required this.lastChecked,
  });
}
