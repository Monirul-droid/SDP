import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'wallet_screen.dart'; // globalTotalBudget access করার জন্য
import 'login_screen.dart';  // userEmail access করার জন্য

class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  List<dynamic> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  // মেসেজ দেখানোর জন্য হেল্পার ফাংশন
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- API: ডাটাবেস থেকে সব খরচ নিয়ে আসা ---
  Future<void> _fetchExpenses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("http://192.168.0.106:5000/get_expenses/$email");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _expenses = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        debugPrint("Server Error (Fetch): ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Connection Error (Fetch): $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- API: নতুন খরচ ডাটাবেসে সেভ করা ---
  Future<void> _saveExpenseToDatabase(String title, double amount) async {
    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("http://192.168.0.106:5000/add_expense");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email,
          "title": title,
          "amount": amount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ সফলভাবে সেভ হলে স্ক্রিনে মেসেজ দেখাবে
        _showMessage("Expense Saved Successfully! ✅");
        _fetchExpenses();
      } else {
        _showMessage("Failed to save to Database! ❌", isError: true);
        debugPrint("Server Error (Add): ${response.body}");
      }
    } catch (e) {
      _showMessage("Connection Error! check server.", isError: true);
      debugPrint("Connection Error (Add): $e");
    }
  }

  // --- API: ডাটাবেস থেকে খরচ ডিলিট করা ---
  Future<void> _deleteExpense(int id) async {
    final url = Uri.parse("http://192.168.0.106:5000/delete_expense/$id");
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _showMessage("Expense Deleted!");
        _fetchExpenses();
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  double get _totalExpense => _expenses.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));

  void _addExpenseDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(hintText: "Title")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Amount")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                _saveExpenseToDatabase(titleController.text, double.parse(amountController.text));
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double balance = globalTotalBudget - _totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Planner", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3285E1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SUMMARY SECTION
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF3285E1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem("Total Budget", globalTotalBudget, Colors.white),
                _buildSummaryItem("Expenses", _totalExpense, Colors.orangeAccent),
                _buildSummaryItem("Balance", balance, balance < 0 ? Colors.redAccent : Colors.greenAccent),
              ],
            ),
          ),

          // LIST SECTION
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.money)),
                  title: Text(expense['title']),
                  subtitle: Text("৳ ${expense['amount']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteExpense(expense['id']),
                  ),
                );
              },
            ),
          ),

          // ADD BUTTON AT BOTTOM
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add New Expense"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D2A0), foregroundColor: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text("৳ ${amount.toStringAsFixed(0)}", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}