import 'package:flutter/material.dart';
import 'trip_planning_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'chat_overlay.dart';
import 'config.dart';
/// A screen that displays detailed information about a specific location,
/// allowing users to view its description, toggle its favorite status,
/// or add it to their trip itinerary.
class DetailScreen extends StatefulWidget {
  final Map place;
  final bool isSelectionMode;

  const DetailScreen({
    super.key,
    required this.place,
    this.isSelectionMode = false,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isFavorite = false;
  int? favoriteId;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  /// Queries the backend database to determine if the current location
  /// is already saved in the user's favorites list.
  Future<void> _checkIfFavorite() async {
    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    String name = widget.place['name'] ?? "Unknown";
    final url = Uri.parse("${AppConfig.baseUrl}/check_favourite/$email/$name");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            isFavorite = data['is_favorite'] ?? false;
            favoriteId = data['id'];
          });
        }
      }
    } catch (e) {
      debugPrint("Check Favorite Error: $e");
    }
  }

  /// Toggles the favorite status of the location.
  /// If it is already a favorite, it removes it; otherwise, it adds it.
  Future<void> _toggleFavorite() async {
    if (isFavorite && favoriteId != null) {
      _removeFavorite();
    } else {
      _addFavorite();
    }
  }

  /// Sends a POST request to the backend to save the current location
  /// to the logged-in user's favorites list.
  Future<void> _addFavorite() async {
    final url = Uri.parse("${AppConfig.baseUrl}/add_favourite");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": LoginScreen.userEmail ?? "siam123@gmail.com",
          "location_id": widget.place['location_id'] ?? 0,
          "name": widget.place['name'],
          "location": widget.place['location'] ?? widget.place['location_address'] ?? "Unknown Location",
          "image_url": widget.place['image_url'],
          "description": widget.place['description'],
          "category": widget.place['category']
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() => isFavorite = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Added to Favourites!"), backgroundColor: Colors.green),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: ${response.body}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  /// Sends a DELETE request to the backend to remove the current location
  /// from the user's favorites list using its unique ID.
  Future<void> _removeFavorite() async {
    if (favoriteId == null) return;

    final url = Uri.parse("${AppConfig.baseUrl}/delete_favourite/$favoriteId");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() => isFavorite = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Removed from Favourites!"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  /// Parses the description text to find and apply bold styling
  /// to any "Estimated Value" information.
  ///
  /// Parameters:
  ///   text (String): The full description text to parse.
  ///
  /// Returns:
  ///   List<TextSpan>: A list of styled text spans ready to be rendered in a RichText widget.
  List<TextSpan> _formatDescription(String text) {
    List<TextSpan> spans = [];
    final regExp = RegExp(r"(Estimated Value:.*)", caseSensitive: false);

    final matches = regExp.allMatches(text);
    int lastIndex = 0;

    for (var match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    String description = widget.place['description'] ?? "No description available.";

    String displayLocation = widget.place['location'] ??
        widget.place['location_address'] ??
        widget.place['address'] ??
        "Unknown Location";

    return Scaffold(
      floatingActionButton: const ChatBotButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 350,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Image.network(
                    (widget.place['image_url'] != null && widget.place['image_url'].toString().isNotEmpty)
                        ? widget.place['image_url']
                        : "https://via.placeholder.com/400",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 100)),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1CB5D1)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.place['name'] ?? "Unknown Place",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 32,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF1CB5D1), size: 20),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        displayLocation,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
                    children: _formatDescription(description),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(25),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.isSelectionMode) {
                    Navigator.pop(context, {'name': widget.place['name'], 'price': 0});
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TripPlanningScreen()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1CB5D1),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  widget.isSelectionMode ? "Add to Itinerary" : "Plan a Visit",
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}