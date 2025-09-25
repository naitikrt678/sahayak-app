import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/environment_service.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'services/upload_queue_service.dart';
import 'services/voice_recording_service.dart';
import 'services/realtime_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvironmentService.initialize();

  // Initialize Supabase (gracefully handle failures)
  await SupabaseService.initialize();

  // Initialize local notifications
  await NotificationService.initialize();

  // Initialize voice recording service
  await VoiceRecordingService.initialize();

  // Start upload queue connectivity monitoring
  UploadQueueService.startConnectivityMonitoring();

  // Initialize realtime service if enabled
  await _initializeRealtimeService();

  runApp(const CivicApp());
}

/// Initialize realtime service based on settings
Future<void> _initializeRealtimeService() async {
  try {
    // Check if realtime is enabled in settings
    final realtimeEnabled = await SettingsService.getRealtimeEnabled();

    if (realtimeEnabled && SupabaseService.isAvailable) {
      await RealtimeService.subscribeToReports();
      print('Realtime service initialized successfully');
    } else {
      print(
        'Realtime service not initialized - disabled in settings or Supabase unavailable',
      );
    }
  } catch (e) {
    print('Failed to initialize realtime service: $e');
  }
}

class CivicApp extends StatelessWidget {
  const CivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak - Civic App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF4CAF50),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const CustomBackButtonWrapper(child: AuthWrapper()),
    );
  }
}

/// Custom wrapper to handle back button behavior globally
class CustomBackButtonWrapper extends StatefulWidget {
  final Widget child;

  const CustomBackButtonWrapper({super.key, required this.child});

  @override
  State<CustomBackButtonWrapper> createState() =>
      _CustomBackButtonWrapperState();
}

class _CustomBackButtonWrapperState extends State<CustomBackButtonWrapper> {
  bool _canExit = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Check if we're on the main navigation screen (home)
        final route = ModalRoute.of(context);
        if (route != null && route.isFirst) {
          // We're on the home screen - show exit confirmation
          if (_canExit) {
            Navigator.of(context).pop(); // Allow exit
          } else {
            // Show snackbar and set exit flag
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
            setState(() {
              _canExit = true;
            });
            // Reset the flag after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _canExit = false;
                });
              }
            });
          }
        } else {
          // We're not on the home screen - navigate to home first
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: widget.child,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
      );
    }

    return _isLoggedIn! ? const MainNavigationScreen() : const LoginScreen();
  }
}
