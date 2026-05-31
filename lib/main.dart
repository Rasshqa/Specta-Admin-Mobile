import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'state/gatekeeper_state.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'theme/specta_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before any service reads them
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Failed to load .env file: $e');
  }

  // Initialise Firebase then FCM (must complete before UI builds)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FcmService().initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase initialization skipped: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => GatekeeperState()),
      ],
      child: const SpectaAdminApp(),
    ),
  );
}

class SpectaAdminApp extends StatelessWidget {
  const SpectaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SPECTA Command Center',
      theme: SpectaTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return Scaffold(
              backgroundColor: SpectaTheme.slateBg,
              body: Center(
                child: CircularProgressIndicator(color: SpectaTheme.neonPurple),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return const HomeWrapper();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
