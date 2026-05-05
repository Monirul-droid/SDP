import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  // ✅ AI Backend (main.py) 8000 port-e run korche, tai port change kora hoyeche
  // Emulator support-er jonno 10.0.2.2 babohar kora hoyeche
  static const String _baseUrl = "http://192.168.0.106:5000";

  Future<String?> getTravelPlan(String destination, String type, int budget, int days) async {
    try {
      final prompt = "Plan a $days day $type trip to $destination with a budget of BDT $budget.";

      // ✅ URL-ti backend-er endpoint-er sathe mil rakha hoyeche
      final url = Uri.parse('$_baseUrl/ask-gobuddy?prompt=${Uri.encodeComponent(prompt)}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Backend theke 'reply' key-ti receive kora hochche
        if (data.containsKey('reply')) {
          return data['reply'];
        } else if (data.containsKey('error')) {
          return "AI Error: ${data['error']}";
        }
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      // ✅ Connection error (e.g. Server bondho thakle) handle korbe
      print("Error connecting to Python AI Backend: $e");
      return "Could not connect to AI server.";
    }
    return "Something went wrong.";
  }
}