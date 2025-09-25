import 'package:supabase_flutter/supabase_flutter.dart';
import 'environment_service.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase client not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  static bool get isInitialized => _initialized;

  static Future<bool> initialize() async {
    try {
      // Ensure environment is loaded
      await EnvironmentService.initialize();

      if (!EnvironmentService.hasValidSupabaseConfig) {
        print('Warning: Supabase configuration not found');
        print(EnvironmentService.configStatus);
        return false;
      }

      await Supabase.initialize(
        url: EnvironmentService.supabaseUrl,
        anonKey: EnvironmentService.supabaseAnonKey,
        debug: EnvironmentService.isDevelopment,
      );

      _client = Supabase.instance.client;
      _initialized = true;

      print('Supabase initialized successfully');
      return true;
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      _initialized = false;
      return false;
    }
  }

  // Check if client is available and properly configured
  static bool get isAvailable {
    return _initialized &&
        _client != null &&
        EnvironmentService.hasValidSupabaseConfig;
  }

  // Get auth user
  static User? get currentUser => _client?.auth.currentUser;

  // Storage helpers
  static SupabaseStorageClient get storage => client.storage;

  static StorageFileApi get reportsStorage =>
      storage.from(EnvironmentService.reportsBucket);

  // Database helpers
  static SupabaseQueryBuilder get reports => client.from('reports');

  // Realtime helpers
  static RealtimeChannel subscribeToReports(
    void Function(PostgresChangePayload) callback,
  ) {
    return client
        .channel('reports_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: callback,
        )
        .subscribe();
  }

  // Cleanup
  static Future<void> dispose() async {
    _client = null;
    _initialized = false;
  }
}
