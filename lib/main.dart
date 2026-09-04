import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Requires google-services.json to be set up)
  try {
    await Firebase.initializeApp();
    // Subscribe to notifications topic
    await FirebaseMessaging.instance.subscribeToTopic('admin_alerts');
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

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
