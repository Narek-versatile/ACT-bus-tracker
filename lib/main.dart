import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storage = StorageService();
  await storage.init();

  final backgroundService = BackgroundService();
  await backgroundService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACT Drive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003865), // Dark Ocean Blue
          primary: const Color(0xFF003865),
          secondary: const Color(0xFFFFD100), // Bright Yellow
          tertiary: const Color(0xFFD4FF33), // Light Limey Color
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

/// Splash screen to determine which screen to show
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Small delay for splash effect
    await Future.delayed(const Duration(milliseconds: 500));

    final storage = StorageService();
    final isSetupComplete = storage.isSetupComplete();

    if (!mounted) return;

    // Navigate to appropriate screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isSetupComplete ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 100, color: Color(0xFF003865)),
            SizedBox(height: 24),
            Text(
              'ACT Drive',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFFFFD100)),
          ],
        ),
      ),
    );
  }
}
