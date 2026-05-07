import 'package:flutter/material.dart';
import 'config.dart';
/// A screen that allows users to track and manage their travel expenses.
/// Provides functionality to view a summary of total spending, list recent expenses,
/// delete items via swipe, and add new expenses.
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  List<Map<String, dynamic>> expenses = [
    {"title": "Flight to Bangkok", "amount": 800.0, "category": "Flights", "icon": Icons.flight, "date": "Feb 01"},
    {"title": "Hotel Booking", "amount": 600.0, "category": "Hotels", "icon": Icons.hotel, "date": "Feb 02"},
    {"title": "Dinner", "amount": 45.0, "category": "Food", "icon": Icons.restaurant, "date": "Feb 03"},
  ];

  /// Calculates the total amount spent by summing up all individual expenses.
  double get totalSpent => expenses.fold(0, (sum, item) => sum + item["amount"]);

  /// Adds a new expense to the top of the list and updates the UI state.
  ///
  /// Parameters:
  ///   title (String): The description or name of the expense.
  ///   amount (double): The monetary value of the expense.
  void addExpense(String title, double amount) {
    setState(() {
      expenses.insert(0, {
        "title": title,
        "amount": amount,
        "category": "Other",
        "icon": Icons.attach_money,
        "date": "Today"
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => showAddExpenseSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text("Expense Tracker",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text("Track your travel spending", style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  const Text("Total Spent", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text("\$${totalSpent.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 20, top: 25, bottom: 10),
            child: Align(alignment: Alignment.centerLeft,
                child: Text("Recent Expenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final item = expenses[index];
                return Dismissible(
                  key: Key(item['title'] + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() { expenses.removeAt(index); });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF3F5F9),
                          child: Icon(item["icon"], color: const Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item["title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text("${item["category"]} • ${item["date"]}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        Text("- \$${item["amount"].toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16))
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  /// Displays a modal bottom sheet allowing the user to input a new expense.
  /// Captures the title and amount, then calls [addExpense] to update the list.
  void showAddExpenseSheet() {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Add New Expense", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "What did you spend on?",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixText: "\$ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      addExpense(titleController.text, double.parse(amountController.text));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save Expense", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}