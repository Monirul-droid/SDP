import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
/// A service class responsible for handling communication with the Python AI backend
/// to fetch generated travel plans and itineraries.
class AIService {
  static const String _baseUrl = "${AppConfig.baseUrl}";

  /// Generates a customized travel plan by sending a constructed prompt to the AI backend.
  ///
  /// Parameters:
  ///   destination (String): The target location for the trip.
  ///   type (String): The style or theme of the trip (e.g., adventure, family, solo).
  ///   budget (int): The total allocated budget for the trip in BDT.
  ///   days (int): The duration of the trip in days.
  ///
  /// Returns:
  ///   Future<String?>: The generated travel plan text from the AI, or an error message if the request fails.
  Future<String?> getTravelPlan(String destination, String type, int budget, int days) async {
    try {
      final prompt = "Plan a $days day $type trip to $destination with a budget of BDT $budget.";
      final url = Uri.parse('$_baseUrl/ask-gobuddy?prompt=${Uri.encodeComponent(prompt)}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('reply')) {
          return data['reply'];
        } else if (data.containsKey('error')) {
          return "AI Error: ${data['error']}";
        }
      } else {
        return "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      print("Error connecting to Python AI Backend: $e");
      return "Could not connect to AI server.";
    }
    return "Something went wrong.";
  }
}