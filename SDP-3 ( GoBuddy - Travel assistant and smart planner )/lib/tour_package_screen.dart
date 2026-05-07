import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_overlay.dart';
import 'config.dart';
/// A screen that displays a list of available tour packages.
/// Users can view basic details and expand cards for more in-depth information.
class TourPackageScreen extends StatefulWidget {
  const TourPackageScreen({super.key});

  @override
  State<TourPackageScreen> createState() => _TourPackageScreenState();
}

class _TourPackageScreenState extends State<TourPackageScreen> {
  List<dynamic> packages = [];
  bool isLoading = true;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  /// Fetches the list of tour packages from the backend API.
  Future<void> fetchPackages() async {
    final url = Uri.parse("${AppConfig.baseUrl}/get_all_packages");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          packages = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatBotButton(),
      appBar: AppBar(
        title: const Text(
            "Exclusive Tour Packages",
            style: TextStyle(color: Colors.white)
        ),
        backgroundColor: const Color(0xFF3285E1),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final item = packages[index];
          bool isExpanded = expandedIndex == index;

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Loading Section: Increased height slightly for better visibility
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3285E1).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                        ? Image.network(
                      item['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                        : const Center(
                      child: Icon(Icons.image, size: 50, color: Color(0xFF3285E1)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              item['city'],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(
                                item['budget'],
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.hotel, "Hotel", item['hotel']),
                      _buildInfoRow(Icons.explore, "Places", item['places']),

                      // Expanded details section
                      if (isExpanded) ...[
                        const Divider(height: 30),
                        const Text(
                            "Additional Information",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3285E1))
                        ),
                        const SizedBox(height: 10),
                        Table(
                          border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(2),
                          },
                          children: [
                            _buildTableRow("Restaurants", item['restaurants'] ?? "N/A"),
                            _buildTableRow("Travel Ways", item['travel_way'] ?? "N/A"),
                          ],
                        ),
                      ],

                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpanded ? Colors.grey : const Color(0xFF3285E1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              expandedIndex = isExpanded ? null : index;
                            });
                          },
                          icon: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white
                          ),
                          label: Text(
                              isExpanded ? "Collapse" : "Extend",
                              style: const TextStyle(color: Colors.white)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a simple row with an icon and key-value text pair.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text("$label: $value", style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  /// Helper to create a row for the additional information table.
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}