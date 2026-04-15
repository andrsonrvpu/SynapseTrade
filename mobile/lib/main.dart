import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/synapse_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

/// Entry point that shows Splash first, then HomeScreen after login.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return SplashScreen(
        onLogin: () => setState(() => _loggedIn = true),
      );
    }
    return const HomeScreen();
  }
}
