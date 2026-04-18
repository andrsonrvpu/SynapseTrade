import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/synapse_theme.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SynapseTradeApp());
}

class SynapseTradeApp extends StatelessWidget {
  const SynapseTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'SynapseTrade',
        debugShowCheckedModeBanner: false,
        theme: SynapseTheme.darkTheme,
        home: const _AppEntry(),
      ),
    );
  }
}

/// Stream-based auth guard — listens to Firebase auth state.
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // User is not logged in — show login
        return LoginScreen(
          onLogin: () {}, // Navigation handled by stream
        );
      },
    );
  }
}

/// Minimal splash/loading screen while checking auth state.
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SynapseTheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SynapseTheme.primaryContainer.withOpacity(0.3),
                    SynapseTheme.primaryContainer.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: SynapseTheme.primaryContainer.withOpacity(0.35),
                ),
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SynapseTrade',
              style: SynapseTheme.headline(fontSize: 24, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                color: SynapseTheme.primaryContainer,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
