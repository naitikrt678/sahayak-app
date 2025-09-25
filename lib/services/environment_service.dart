import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        await dotenv.load(fileName: ".env");
        _initialized = true;
      } catch (e) {
        print('Warning: Could not load .env file: $e');
        print('Environment variables will need to be set manually');
        _initialized = true;
      }
    }
  }

  // Supabase Configuration
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isNotEmpty) return url;

    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (key.isNotEmpty) return key;

    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // Storage Configuration
  static String get reportsBucket {
    const bucket = String.fromEnvironment('REPORTS_BUCKET');
    if (bucket.isNotEmpty) return bucket;

    return dotenv.env['REPORTS_BUCKET'] ?? 'reports';
  }

  // App Configuration
  static String get appEnv {
    const env = String.fromEnvironment('APP_ENV');
    if (env.isNotEmpty) return env;

    return dotenv.env['APP_ENV'] ?? 'development';
  }

  // Mock Mode Configuration
  static bool get useMockData {
    const mockMode = String.fromEnvironment('USE_MOCK_DATA');
    if (mockMode.isNotEmpty) return mockMode.toLowerCase() == 'true';

    final envValue = dotenv.env['USE_MOCK_DATA'] ?? 'true';
    return envValue.toLowerCase() == 'true';
  }

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';

  // Validation
  static bool get hasValidSupabaseConfig {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static String get configStatus {
    if (!hasValidSupabaseConfig) {
      return 'Missing Supabase configuration. Please set SUPABASE_URL and SUPABASE_ANON_KEY';
    }
    return 'Configuration loaded successfully';
  }
}
