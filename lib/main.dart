import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/department_view_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/document_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
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
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Anweshan Document Library',
        debugShowCheckedModeBanner: false,
        theme: AnweshanTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/department': (context) => DepartmentViewScreen(),
          '/upload': (context) => const UploadScreen(),
          '/detail': (context) => const DocumentDetailScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
