import 'dart:async';
import 'package:flutter/material.dart';
import 'itinerary_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'chat_overlay.dart';
import 'config.dart';
/// A screen that allows users to plan a trip by selecting dates
/// and viewing or managing their saved itineraries.
class TripPlanningScreen extends StatefulWidget {
  const TripPlanningScreen({super.key});

  @override
  State<TripPlanningScreen> createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> savedPlansFromDB = [];
  bool isLoadingPlans = false;

  // Animation Logic: Background color transition
  List<Color> colorList = [
    const Color(0xFFE0F7FA), // Light Cyan
    const Color(0xFFF1F8E9), // Light Green
    const Color(0xFFFFF3E0), // Light Orange
    const Color(0xFFF3E5F5), // Light Purple
  ];
  int colorIndex = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Periodically change the background color for a smooth transition effect
    timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          colorIndex = (colorIndex + 1) % colorList.length;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the screen is disposed to avoid memory leaks
    timer?.cancel();
    super.dispose();
  }

  /// Fetches saved plans from the database for the current user.
  Future<void> _fetchSavedPlansFromDB(StateSetter? setModalState) async {
    if (!mounted) return;

    setState(() => isLoadingPlans = true);
    if (setModalState != null) {
      setModalState(() {});
    }

    String email = LoginScreen.userEmail ?? "testuser@gmail.com";
    final url = Uri.parse("${AppConfig.baseUrl}/get_itineraries/$email");

    try {
      debugPrint("Fetching itineraries for: $email");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() {
            savedPlansFromDB = [];
            isLoadingPlans = false;
          });
          if (setModalState != null) {
            setModalState(() {});
          }
          return;
        }

        try {
          var data = json.decode(response.body);
          debugPrint("Parsed data: $data");

          if (mounted) {
            setState(() {
              savedPlansFromDB = data is List ? data : [];
              isLoadingPlans = false;
            });
          }
        } catch (parseError) {
          debugPrint("Parse error: $parseError");
          if (mounted) {
            setState(() {
              savedPlansFromDB = [];
              isLoadingPlans = false;
            });
          }
        }
      } else {
        debugPrint("Server error: ${response.statusCode}");
        if (mounted) {
          setState(() {
            savedPlansFromDB = [];
            isLoadingPlans = false;
          });
        }
      }

      if (setModalState != null) {
        setModalState(() {});
      }
    } catch (e) {
      debugPrint("Network error: $e");
      if (mounted) {
        setState(() {
          savedPlansFromDB = [];
          isLoadingPlans = false;
        });
      }
      if (setModalState != null) {
        setModalState(() {});
      }
    }
  }

  /// Helper used by FutureBuilder to retrieve itineraries.
  Future<List<dynamic>> _getItineraries() async {
    String email = LoginScreen.userEmail ?? "testuser@gmail.com";
    final url = Uri.parse("${AppConfig.baseUrl}/get_itineraries/$email");

    try {
      debugPrint("Fetching itineraries for: $email");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      debugPrint("Response status: ${response.statusCode}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        var data = json.decode(response.body);
        debugPrint("Found ${(data is List ? data.length : 0)} itineraries");
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      debugPrint("Error retrieving itineraries: $e");
      rethrow;
    }
  }

  /// Deletes a specific plan and refreshes the modal view.
  Future<void> _deletePlanAndRefresh(int id, BuildContext modalContext) async {
    final url = Uri.parse("${AppConfig.baseUrl}/delete_itinerary/$id");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Plan deleted successfully!"),
            backgroundColor: Colors.red,
          ),
        );

        // Close the modal and refresh by reopening after a short delay
        if (modalContext.mounted) {
          Navigator.pop(modalContext);
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showSavedPlans(context);
          }
        });
      }
    } catch (e) {
      debugPrint("Error deleting plan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Opens a bottom sheet to display saved itineraries.
  void _showSavedPlans(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return FutureBuilder(
          future: _getItineraries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: 550,
                child: Column(
                  children: [
                    const Text("Your Saved Itineraries",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1CB5D1))),
                    const Divider(),
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Loading your itineraries...")
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: 550,
                child: Column(
                  children: [
                    const Text("Your Saved Itineraries",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1CB5D1))),
                    const Divider(),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text("Error: ${snapshot.error}"),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showSavedPlans(context);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            List<dynamic> plans = snapshot.data ?? [];

            return Container(
              padding: const EdgeInsets.all(20),
              height: 550,
              child: Column(
                children: [
                  const Text("Your Saved Itineraries",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1CB5D1))),
                  const Divider(),
                  const SizedBox(height: 10),
                  plans.isEmpty
                      ? const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, color: Colors.grey, size: 48),
                          SizedBox(height: 16),
                          Text("No saved itineraries yet.\nStart planning your next trip!"),
                        ],
                      ),
                    ),
                  )
                      : Expanded(
                    child: ListView.builder(
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF1CB5D1),
                              child: Icon(Icons.map, color: Colors.white, size: 20),
                            ),
                            title: Text(plan["trip_name"] ?? "Trip Plan",
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${plan["day"]} - ${plan["activity"]}"),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "BDT ${plan["cost"]}",
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    if (plan['id'] != null) {
                                      _deletePlanAndRefresh(plan['id'], context);
                                    }
                                  },
                                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Opens the native date picker for start or end date selection.
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatBotButton(),
      // Main background with animated color transitions
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorList[colorIndex],
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.arrow_back, color: Colors.black)),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  onPressed: () => _showSavedPlans(context),
                  icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.bookmark, color: Color(0xFF1CB5D1))),
                ),
                const SizedBox(width: 10),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Image.asset("assets/trip_banner.jpg", fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey.shade100)),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text("Plan Your Next Adventure",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1CB5D1))),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInputBox(
                            label: "Start Date",
                            onTap: () => _selectDate(context, true),
                            child: Text(_startDate == null ? "Select Date" : "${_startDate!.toLocal()}".split(' ')[0]),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildInputBox(
                            label: "End Date",
                            onTap: () => _selectDate(context, false),
                            child: Text(_endDate == null ? "Select Date" : "${_endDate!.toLocal()}".split(' ')[0]),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_startDate != null && _endDate != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ItineraryScreen(startDate: _startDate!, endDate: _endDate!)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select dates first!")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1CB5D1),
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        icon: const Text("Generate Itinerary", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        label: const Icon(Icons.airplanemode_active, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a stylized input box for date selection.
  Widget _buildInputBox({required String label, required Widget child, VoidCallback? onTap}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6), // Glassmorphism style
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(15)
          ),
          child: Center(child: child),
        ),
      ),
    ]);
  }
}