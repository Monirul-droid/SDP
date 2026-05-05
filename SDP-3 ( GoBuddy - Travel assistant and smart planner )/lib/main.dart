import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'base.dart';
import 'splash_screen.dart';

// Global variable: App cholakalin budget store korbe
double globalTotalBudget = 0.0;

String? loggedInUserEmail;
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // ✅ ERROR FIX: Ei method-ti Settings Screen theke 'changeTheme' access korte sahajyo korbe
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Manual toggle control korar jonno themeMode variable
  ThemeMode _themeMode = ThemeMode.system;

  // Ei function-ti call korle puro App-er theme change hobe
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel App',

      // ✅ Light Mode Configuration
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1CB5D1),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // ✅ Dark Mode Configuration
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // 💡 System mode er poriborte amader state variable thakbe
      themeMode: _themeMode,

      home: const SplashScreen(),
    );
  }
}
