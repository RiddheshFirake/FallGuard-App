import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hello/screens/home_screen.dart'; // Normal user home screen
import 'package:hello/screens/LoginScreen.dart'; // Login screen
import 'package:hello/screens/SignUpScreen.dart'; // Sign-up screen
import 'package:hello/screens/first_time_screen.dart'; // Role selection screen
import 'package:hello/screens/hospital_dashboard.dart'; // Hospital dashboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

// Background message handler function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Handle background notifications, like showing a local notification or updating the app state
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Authentication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Start at the first-time screen
      routes: {
        '/': (context) => FirstTimeScreen(), // First-time screen for choosing role
        '/home': (context) => HomeScreen(), // Navigate to home screen after login/signup
        '/login': (context) => LoginScreen(), // Login route
        '/hospital_dashboard': (context) => HospitalDashboard(), // Correct class name
      },
      onGenerateRoute: (settings) {
        // Handling dynamic routes (e.g., passing arguments to SignUpScreen)
        if (settings.name == '/signup') {
          final String role = settings.arguments as String; // Get the role argument
          return MaterialPageRoute(
            builder: (context) => SignUpScreen(role: role), // Pass role to SignUpScreen
          );
        }
        return null; // Return null if no matching route found
      },
    );
  }
}
