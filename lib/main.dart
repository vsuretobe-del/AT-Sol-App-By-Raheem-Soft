import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.load();
  runApp(const AtSolApp());
}

class AtSolApp extends StatelessWidget {
  const AtSolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AT Sol',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ApiService.instance.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
