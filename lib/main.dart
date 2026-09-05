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
    
    // Request permission for Android 13+ and iOS
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // We no longer need to subscribe to a topic because we are using direct device tokens
    // await messaging.subscribeToTopic('admin_alerts');
    
    // Listen for messages while app is open (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint('Foreground Message Received: ${message.notification?.title}');
      }
    });

  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  await ApiService.instance.load();
  
  // Register this device's token with the server for bulletproof notifications
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await ApiService.instance.post('/api/register_token.php', {'token': token});
      debugPrint("FCM Token registered successfully: $token");
    }
  } catch (e) {
    debugPrint("Failed to register token: $e");
  }

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
