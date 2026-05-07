// lib/config.dart

class AppConfig {
  // Door 5000: For app.py (Login, Register, Profiles, etc.)
  static const String baseUrl = "http://192.168.0.104:5000";

  // Door 8000: For main.py (AI Chatbot, Search, or whatever is in main.py)
  static const String chatBaseUrl = "http://192.168.0.104:8000";
}