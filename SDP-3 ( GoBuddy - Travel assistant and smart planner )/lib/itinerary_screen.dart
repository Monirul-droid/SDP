import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'search_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'chat_overlay.dart';
class Activity {
  String name;
  double cost;
  Activity({required this.name, required this.cost});
}

class ItineraryScreen extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ItineraryScreen({super.key, required this.startDate, required this.endDate});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  // ✅ Map to store list of activities for each day
  final Map<int, List<Activity>> _dayPlans = {};
  bool _isSaving = false;

  // Animated Background Variables
  List<Color> _colorList = [const Color(0xFF1CB5D1), const Color(0xFF4CAF50)];
  Alignment _begin = Alignment.topLeft;
  Alignment _end = Alignment.bottomRight;

  @override
  void initState() {
    super.initState();
    _initializeData();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _colorList = _colorList.reversed.toList();
          _begin = _begin == Alignment.topLeft ? Alignment.bottomLeft : Alignment.topLeft;
          _end = _end == Alignment.bottomRight ? Alignment.topRight : Alignment.bottomRight;
        });
      }
    });
  }

  void _initializeData() {
    int dayCount = widget.endDate.difference(widget.startDate).inDays + 1;
    for (int i = 1; i <= dayCount; i++) {
      _dayPlans[i] = [];
    }
  }

  double _calculateDayTotal(int dayNumber) {
    return _dayPlans[dayNumber]!.fold(0, (sum, item) => sum + item.cost);
  }

  // --- LOGIC: ADD ACTIVITIES ---
  void _searchAndAddActivity(int dayNumber) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen(isSelectionMode: true)),
    );
    if (result != null && result is Map<String, dynamic>) {
      _showPriceInputDialog(dayNumber, result['name']);
    }
  }

  void _showPriceInputDialog(int dayNumber, String placeName) {
    TextEditingController _costController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cost for $placeName"),
        content: TextField(
          controller: _costController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter amount", prefixText: "BDT "),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dayPlans[dayNumber]!.add(Activity(
                  name: placeName,
                  cost: double.tryParse(_costController.text) ?? 0.0,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _manualAddActivity(int dayNumber) {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _costController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Manual Activity - Day $dayNumber"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: "What's the plan?")),
            TextField(controller: _costController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Cost", prefixText: "BDT ")),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                setState(() {
                  _dayPlans[dayNumber]!.add(Activity(
                    name: _nameController.text,
                    cost: double.tryParse(_costController.text) ?? 0.0,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: SAVE TO BACKEND SQLITE (CSV Logic Bad dewa hoyeche)
  Future<void> _saveToDatabase() async {
    setState(() => _isSaving = true);

    Map<String, dynamic> plansJson = {};
    _dayPlans.forEach((day, activities) {
      if (activities.isNotEmpty) {
        plansJson[day.toString()] = activities.map((a) => {'name': a.name, 'cost': a.cost}).toList();
      }
    });

    if (plansJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add some activities first!")));
      setState(() => _isSaving = false);
      return;
    }

    // Backend Endpoint
    final url = Uri.parse("http://192.168.0.106:5000/save_itinerary");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          // ✅ LoginScreen theke real email nichche
          "email": LoginScreen.userEmail ?? "siam123@gmail.com",
          "trip_name": "Trip ${DateFormat('dd-MMM').format(widget.startDate)}",
          "destination": "Bangladesh Tour",
          "plans": plansJson,
        }),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['status'] == 'success') {
        _showSuccessDialog();
      } else {
        throw Exception(result['message'] ?? "Server Error");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Success!"),
        content: const Text("Your trip itinerary has been saved to the database."),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int dayCount = widget.endDate.difference(widget.startDate).inDays + 1;
    return Scaffold(
      floatingActionButton: const ChatBotButton(),
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(gradient: LinearGradient(begin: _begin, end: _end, colors: _colorList)),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dayCount,
                  itemBuilder: (context, index) => _buildDayCard(index + 1),
                ),
              ),
              _isSaving
                  ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: _saveToDatabase, // ✅ Notun Backend Logic
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.white),
                  child: const Text("SAVE ITINERARY", style: TextStyle(color: Color(0xFF1CB5D1), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text("Plan Your Days", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayNumber) {
    double total = _calculateDayTotal(dayNumber);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Day $dayNumber", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Total: BDT ${total.toStringAsFixed(0)}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(),
          ..._dayPlans[dayNumber]!.map((a) => ListTile(title: Text(a.name), trailing: Text("BDT ${a.cost}"))),
          Row(
            children: [
              TextButton.icon(onPressed: () => _manualAddActivity(dayNumber), icon: const Icon(Icons.add), label: const Text("Manual")),
              const Spacer(),
              ElevatedButton.icon(onPressed: () => _searchAndAddActivity(dayNumber), icon: const Icon(Icons.search), label: const Text("Discover")),
            ],
          )
        ],
      ),
    );
  }
}