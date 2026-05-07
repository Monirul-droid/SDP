import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'base.dart';
import 'splash_screen.dart';
import 'config.dart';

/// Global variable to store the total budget during the app's runtime.
double globalTotalBudget = 0.0;

/// Stores the currently logged-in user's email address.
String? loggedInUserEmail;

/// Initializes the Flutter application, configures Firebase, and starts the app.
///
/// Returns:
///   void
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// The root widget of the Flutter application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// Allows descendant widgets (like a Settings Screen) to access
  /// the state of MyApp, primarily for changing the app theme.
  ///
  /// Parameters:
  ///   context (BuildContext): The build context of the calling widget.
  ///
  /// Returns:
  ///   _MyAppState: The state object of MyApp.
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  /// Updates the application's overall theme mode (Light/Dark/System).
  ///
  /// Parameters:
  ///   themeMode (ThemeMode): The new theme mode to be applied.
  ///
  /// Returns:
  ///   void
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  /// Builds the root MaterialApp, configuring light and dark themes
  /// and setting the initial routing screen.
  ///
  /// Parameters:
  ///   context (BuildContext): The build context provided by Flutter.
  ///
  /// Returns:
  ///   Widget: The configured MaterialApp.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel App',
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
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: _themeMode,
      home: const SplashScreen(),
    );
  }
}