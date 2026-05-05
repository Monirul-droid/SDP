import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'change_password_screen.dart';
import 'account_information_screen.dart';
import 'login_screen.dart';
import 'login_register_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String baseUrl = "http://192.168.0.106:5000";
  bool _isDeleting = false;
  final TextEditingController _deletePasswordController = TextEditingController();

  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    String email = LoginScreen.userEmail ?? "test@example.com";
    String password = _deletePasswordController.text;

    if (password.isEmpty) {
      _showSnackBar("Please enter your password", Colors.red);
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delete_account"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == "success") {
        _showSnackBar("Account deleted successfully", Colors.green);
        
        // Clear user data
        LoginScreen.userEmail = null;
        globalTotalBudget = 0.0;

        // Navigate to login screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
              (route) => false,
            );
          }
        });
      } else {
        _showSnackBar(data["message"] ?? "Failed to delete account", Colors.red);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar("Error deleting account: $e", Colors.red);
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // বর্তমান থিম (ডার্ক/লাইট) চেক করার জন্য
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Settings",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- ACCOUNT SETTINGS ---
          _buildSectionHeader("Account Settings"),

          // Account Information
          _buildSettingItem(Icons.person_outline, "Account Information", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountInformationScreen()),
            );
          }, iconColor, textColor),

          // ✅ Change Password কানেকশন এখানে করা হয়েছে
          _buildSettingItem(Icons.lock_reset_outlined, "Change Password", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
            );
          }, iconColor, textColor),

          const Divider(height: 40),

          // --- PRIVACY & SUPPORT ---
          _buildSectionHeader("Privacy & Support"),
          _buildSettingItem(Icons.lock_outline, "Privacy Policy", () {
            // Privacy policy logic
          }, iconColor, textColor),

          _buildSettingItem(Icons.help_outline, "Help Center", () {
            // Help center logic
          }, iconColor, textColor),

          _buildSettingItem(Icons.info_outline, "About App", () {
            // About app logic
          }, iconColor, textColor),

          const SizedBox(height: 40),

          // --- DELETE ACCOUNT BUTTON ---
          Center(
            child: TextButton(
              onPressed: () {
                // একাউন্ট ডিলিট করার আগে সাধারণত একটি কনফার্মেশন ডায়ালগ দেখানো ভালো
                _showDeleteConfirmDialog(context);
              },
              child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1CB5D1)
          )
      ),
    );
  }

  Widget _buildSettingItem(
      IconData icon, String title, VoidCallback onTap, Color iconCol, Color textCol, {String? trailingText}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconCol),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textCol)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: TextStyle(color: textCol.withOpacity(0.6))),
          Icon(Icons.arrow_forward_ios, size: 16, color: iconCol.withOpacity(0.5)),
        ],
      ),
      onTap: onTap,
    );
  }

  // একাউন্ট ডিলিট করার কনফার্মেশন ডায়ালগ
  void _showDeleteConfirmDialog(BuildContext context) {
    _deletePasswordController.clear();
    showDialog(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Are you sure you want to delete your account? This action cannot be undone.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text(
                "Enter your password to confirm:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deletePasswordController,
                obscureText: true,
                enabled: !_isDeleting,
                decoration: InputDecoration(
                  hintText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: _isDeleting ? null : () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}