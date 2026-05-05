import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  List<dynamic> favourites = [];
  bool isLoading = true;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    _fetchFavourites();
  }

  // --- API: ফেভারিট লিস্ট নিয়ে আসা ---
  Future<void> _fetchFavourites() async {
    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("http://192.168.0.106:5000/get_favourites/$email");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            favourites = json.decode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- API: ফেভারিট ডিলিট করা ---
  Future<void> _removeFavourite(int id) async {
    final url = Uri.parse("http://192.168.0.106:5000/delete_favourite/$id");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Removed from Favourites"),
            backgroundColor: Colors.red,
          ),
        );
        _fetchFavourites(); // লিস্ট রিফ্রেশ করা
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00C9A7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Favourite",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : favourites.isEmpty
          ? const Center(
              child: Text(
                "No favorites added yet!",
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                final item = favourites[index];
                bool isExpanded = expandedIndex == index;

                return GestureDetector(
                  onTap: () =>
                      setState(() => expandedIndex = isExpanded ? null : index),
                  child: _buildFavouriteCard(item, isExpanded),
                );
              },
            ),
    );
  }

  Widget _buildFavouriteCard(Map<String, dynamic> item, bool isExpanded) {
    String imageUrl = item['image_url'] ?? "https://via.placeholder.com/400";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: Radius.circular(isExpanded ? 0 : 20),
              ),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // ডিলিট বাটন (ডান দিকে উপরে)
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFavourite(item['id']),
                    ),
                  ),
                ),
                if (!isExpanded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.black54,
                      child: Text(
                        item['name'] ?? "Unknown",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? "Unknown",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF00C9A7),
                      ),
                      Text(item['location'] ?? "Unknown"),
                    ],
                  ),
                  const Divider(),
                  Text(
                    item['description'] ?? "No description",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
