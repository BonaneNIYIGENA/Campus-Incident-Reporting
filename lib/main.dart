import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/facility_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/incident_service.dart';
import 'services/facility_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final preferences = await SharedPreferences.getInstance();
  runApp(CirApp(preferences: preferences));
}

class CirApp extends StatelessWidget {
  const CirApp({
    super.key,
    this.preferences,
    this.authService,
    this.incidentService,
    this.initialScreen,
    this.testMode = false,
  });

  final SharedPreferences? preferences;
  final AuthService? authService;
  final IncidentService? incidentService;
  final Widget? initialScreen;
  final bool testMode;

  @override
  Widget build(BuildContext context) {
    if (testMode) {
      return MaterialApp(
        title: 'ALU Campus Care',
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
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences!)),
        ChangeNotifierProvider(create: (_) => FacilityProvider(FacilityService())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'ALU Campus Care',
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
