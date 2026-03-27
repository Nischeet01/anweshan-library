import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/department_view_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vqadmmkhjdzuazjgohva.supabase.co',
    anonKey: 'sb_publishable_jIylBoaWJguVbjDGoUIU7Q_wtvn3nEb',
  );

  runApp(const AnweshanApp());
}

class AnweshanApp extends StatelessWidget {
  const AnweshanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer2<AuthService, ThemeProvider>(
        builder: (context, authService, themeProvider, _) {
          return MaterialApp(
            title: 'Anweshan Document Library',
            debugShowCheckedModeBanner: false,
            theme: AnweshanTheme.lightTheme,
            darkTheme: AnweshanTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Use a StreamBuilder to listen to auth state changes for the initial screen
            home: StreamBuilder<AuthState>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final session = snapshot.data?.session;
                if (session != null) {
                  return const DashboardScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/dashboard': (context) => const DashboardScreen(),
              '/department': (context) => const DepartmentViewScreen(),
              '/upload': (context) => const UploadScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
