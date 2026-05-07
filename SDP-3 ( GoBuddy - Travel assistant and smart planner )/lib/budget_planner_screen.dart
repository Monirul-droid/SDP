import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'wallet_screen.dart';
import 'login_screen.dart';
import 'config.dart';
/// A screen that allows users to view their total budget,
/// track their expenses, and add or delete specific expense items.
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

  /// Displays a brief SnackBar message at the bottom of the screen.
  ///
  /// Parameters:
  ///   message (String): The text to display.
  ///   isError (bool): If true, displays a red background; otherwise green.
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Retrieves the list of saved expenses for the logged-in user from the database.
  /// Updates the UI with the fetched data.
  Future<void> _fetchExpenses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("${AppConfig.baseUrl}/get_expenses/$email");

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

  /// Sends a new expense item to the backend API to be saved in the database.
  ///
  /// Parameters:
  ///   title (String): The name or description of the expense.
  ///   amount (double): The cost of the expense.
  Future<void> _saveExpenseToDatabase(String title, double amount) async {
    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("${AppConfig.baseUrl}/add_expense");

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
        _showMessage("Expense Saved Successfully! ");
        _fetchExpenses();
      } else {
        _showMessage("Failed to save to Database! ", isError: true);
        debugPrint("Server Error (Add): ${response.body}");
      }
    } catch (e) {
      _showMessage("Connection Error! check server.", isError: true);
      debugPrint("Connection Error (Add): $e");
    }
  }

  /// Deletes a specific expense item from the database using its ID.
  ///
  /// Parameters:
  ///   id (int): The unique identifier of the expense to be removed.
  Future<void> _deleteExpense(int id) async {
    final url = Uri.parse("${AppConfig.baseUrl}/delete_expense/$id");
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

  /// Calculates the total sum of all fetched expenses.
  double get _totalExpense => _expenses.fold(0.0, (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0));

  /// Opens an alert dialog allowing the user to input a new expense title and amount.
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

  /// Builds a stylized summary column displaying a label and a formatted currency amount.
  ///
  /// Parameters:
  ///   label (String): The title of the summary item (e.g., "Total Budget").
  ///   amount (double): The numerical value to display.
  ///   color (Color): The text color applied to the amount.
  ///
  /// Returns:
  ///   Widget: A column containing the text widgets.
  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text("৳ ${amount.toStringAsFixed(0)}", style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}