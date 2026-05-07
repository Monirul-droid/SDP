import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail_screen.dart';
import 'chat_overlay.dart';
import 'config.dart';
/// A screen that allows users to search for travel destinations.
/// It supports category filtering and provides real-time search results.
class SearchScreen extends StatefulWidget {
  final bool isSelectionMode;

  const SearchScreen({super.key, this.isSelectionMode = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedCategory = "All";

  final List<String> _categories = ["All", "Beach", "Hill", "City", "Forest"];

  @override
  void initState() {
    super.initState();
    // Fetch all available data when the screen is first initialized
    _fetchPlaces("");
  }

  /// Communicates with the backend API to fetch destination data based on
  /// the search query and the selected category.
  Future<void> _fetchPlaces(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = query.isNotEmpty || _selectedCategory != "All";
    });

    try {
      // Ensure the IP address matches your local backend server environment
      final url = Uri.parse('${AppConfig.baseUrl}/search');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "category": _selectedCategory
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['results'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching places: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatBotButton(),
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text(
            "Explore",
            style: TextStyle(color: Color(0xFF1CB5D1), fontWeight: FontWeight.bold, fontSize: 24)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1CB5D1).withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => _fetchPlaces(val), // Triggers search on every keystroke
                decoration: const InputDecoration(
                  hintText: "Search destinations...",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1CB5D1)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Horizontal Category Selection
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategory == _categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = _categories[index]);
                      _fetchPlaces(_searchController.text);
                    },
                    selectedColor: const Color(0xFF1CB5D1),
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.lightBlue),
                  ),
                );
              },
            ),
          ),

          // Search Results Display Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1CB5D1)))
                : _searchResults.isEmpty && _hasSearched
                ? _buildNotFoundView()
                : _searchResults.isEmpty && !_hasSearched
                ? const Center(child: Text("No Data Available", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return _buildAdvancedResultCard(place);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Displays a placeholder view when no matching results are found.
  Widget _buildNotFoundView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.orangeAccent),
          const SizedBox(height: 10),
          Text(
              "No results for \"${_searchController.text}\"",
              style: const TextStyle(color: Colors.white70, fontSize: 16)
          ),
        ],
      ),
    );
  }

  /// Builds a card representing a single search result.
  Widget _buildAdvancedResultCard(Map place) {
    // Resolve the location string by checking various possible data keys
    String displayLocation = place['location'] ??
        place['location_address'] ??
        place['address'] ??
        "Unknown";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(
                place: place,
                isSelectionMode: widget.isSelectionMode,
              ),
            ),
          );

          if (result != null) {
            Navigator.pop(context, result);
          }
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 60, height: 60, color: Colors.white12,
            child: (place['image_url'] != null && place['image_url'].toString().isNotEmpty)
                ? Image.network(
                place['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image)
            )
                : const Icon(Icons.map, color: Color(0xFF1CB5D1)),
          ),
        ),
        title: Text(
            place['name'] ?? "Unknown Place",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        subtitle: Text(
            "$displayLocation • ${place['category'] ?? 'General'}",
            style: const TextStyle(color: Colors.white54)
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF1CB5D1), size: 18),
      ),
    );
  }
}