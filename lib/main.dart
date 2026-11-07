import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/alerts_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/facility_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/incident_service.dart';
import 'services/facility_service.dart';
import 'theme/app_theme.dart';
import 'widgets/splash_screen.dart';

// Draw the splash straight away and set Firebase up behind it, so there is no blank window.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CirBoot());
}

class CirBoot extends StatefulWidget {
  const CirBoot({super.key});

  @override
  State<CirBoot> createState() => _CirBootState();
}

class _CirBootState extends State<CirBoot> {
  late Future<SharedPreferences> _ready = _start();

  Future<SharedPreferences> _start() async {
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 900),
    );
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final preferences = await SharedPreferences.getInstance();
    await minimumSplash;
    return preferences;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SharedPreferences>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.hasData) return CirApp(preferences: snapshot.data);
      if (snapshot.hasError) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'The app could not start. Check your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _ready = _start()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      );
    },
  );
}

class CirApp extends StatelessWidget {
  const CirApp({
    super.key,
    this.preferences,
    this.authService,
    this.incidentService,
    this.initialScreen,
    this.testMode = false,
    this.firestore,
  });

  final SharedPreferences? preferences;
  final AuthService? authService;
  final IncidentService? incidentService;
  final Widget? initialScreen;
  final bool testMode;
  final FirebaseFirestore? firestore;

  @override
  Widget build(BuildContext context) {
    if (testMode) {
      return MaterialApp(
        title: 'Campus Incident Reporting',
        theme: AppTheme.light,
        home: initialScreen,
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService ?? AuthService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          create: (_) => IncidentProvider(incidentService ?? IncidentService()),
          update: (_, auth, incidents) => incidents!..bind(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AlertsProvider>(
          create: (_) => AlertsProvider(firestore: firestore),
          update: (_, auth, alerts) => alerts!..bind(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences!)),
        ChangeNotifierProvider(
          create: (_) =>
              FacilityProvider(FacilityService(firestore: firestore)),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Campus Incident Reporting',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          home: initialScreen ?? const AuthGate(),
        ),
      ),
    );
  }
}
