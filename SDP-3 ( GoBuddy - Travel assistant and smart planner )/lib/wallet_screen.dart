import 'package:flutter/material.dart';

// Global variable (App bondho na howa porjonto thakbe)
double globalTotalBudget = 0.0;

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Screen open hole current budget controller-e dekhabe
    if (globalTotalBudget > 0) {
      _budgetController.text = globalTotalBudget.toString();
    }
  }

  void _saveBudget() {
    if (_budgetController.text.isNotEmpty) {
      setState(() {
        // ✅ Global variable-e data save kora hochche
        globalTotalBudget = double.tryParse(_budgetController.text) ?? 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Total Budget Saved Successfully!"),
          backgroundColor: Color(0xFF00D2A0),
        ),
      );

      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF3285E1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Wallet Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Color(0xFF3285E1),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 60, color: Colors.white),
                  const SizedBox(height: 15),
                  const Text("Current Total Budget", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(
                    // ✅ BDT symbol add kora hoyeche
                    "৳ ${globalTotalBudget.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Input Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Set Your Total Budget",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: "Enter amount (e.g. 5000)",
                        // ✅ Prefix BDT kora hoyeche
                        prefixText: "৳ ",
                        prefixStyle: TextStyle(color: Color(0xFF3285E1), fontWeight: FontWeight.bold),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D2A0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: const Text(
                        "SAVE BUDGET",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "This budget will be used for your trip planning.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}