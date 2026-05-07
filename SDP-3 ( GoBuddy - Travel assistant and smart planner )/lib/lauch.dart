import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'config.dart';
/// The main entry point for the Flutter application.
void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
/// Sets up the basic material app configuration and routes the user
/// to the initial splash screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}