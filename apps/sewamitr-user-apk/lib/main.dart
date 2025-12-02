import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(const SewaMitrApp());
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
          child: Center(
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