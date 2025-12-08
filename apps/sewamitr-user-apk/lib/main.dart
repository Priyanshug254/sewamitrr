import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Supabase
    // Support both standard and Next.js style env variables
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing Supabase credentials in .env file. Please check SUPABASE_URL and SUPABASE_ANON_KEY.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    
    // Initialize FCM Service for background notifications
    FCMService().initialize();
    
    
    // Pre-initialize NotificationService to ensure it's ready
    debugPrint('🔔 Pre-initializing NotificationService...');
    
    runApp(const SewaMitrApp());
  } catch (e, stackTrace) {
    print('Startup Error: $e');
    runApp(StartupErrorApp(error: e.toString(), stackTrace: stackTrace.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;
  
  const StartupErrorApp({super.key, required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Icon(Icons.error_outline, color: Colors.red, size: 60),
                   const SizedBox(height: 20),
                   const Text(
                     'App Startup Failed',
                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                   ),
                   const SizedBox(height: 20),
                   const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text(error, style: const TextStyle(color: Colors.black87)),
                   const SizedBox(height: 20),
                   const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text(stackTrace, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          child: const Center(
            child: Text('An error occurred', style: TextStyle(color: Colors.red)),
          ),
        ),
      );
    };
    return child;
  }
}

class SewaMitrApp extends StatefulWidget {
  const SewaMitrApp({super.key});

  @override
  State<SewaMitrApp> createState() => _SewaMitrAppState();
}

class _SewaMitrAppState extends State<SewaMitrApp> {
  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
        ],
        child: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return MaterialApp(
              title: 'SewaMitr',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              locale: Locale(languageService.currentLanguage),
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}