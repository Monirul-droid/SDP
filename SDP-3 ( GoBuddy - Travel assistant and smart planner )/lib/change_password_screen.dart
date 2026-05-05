import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final String baseUrl = "http://192.168.0.106:5000";

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Validate inputs
    if (_currentPasswordController.text.isEmpty) {
      _showSnackBar("Please enter current password", Colors.red);
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      _showSnackBar("Please enter new password", Colors.red);
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showSnackBar("Please confirm new password", Colors.red);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("New passwords do not match", Colors.red);
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showSnackBar("Password must be at least 8 characters", Colors.red);
      return;
    }

    if (_newPasswordController.text.contains(" ")) {
      _showSnackBar("Password cannot contain spaces", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String email = LoginScreen.userEmail ?? "test@example.com";

      final response = await http.post(
        Uri.parse("$baseUrl/change_password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "current_password": _currentPasswordController.text,
          "new_password": _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == "success") {
        _showSnackBar(data["message"], Colors.green);
        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        // Go back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showSnackBar(data["message"] ?? "Failed to change password", Colors.red);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar("Error changing password: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background behind the card
      appBar: AppBar(
        backgroundColor: const Color(0xFF3285E1), // Blue header to match theme
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Top Blue Background Section
          Container(
            height: 150, // Height ektu bariyechi jate background chobi-ti bhalo bojha jay
            width: double.infinity,
            decoration: BoxDecoration(

              image: DecorationImage(
                image: const AssetImage("assets/header_bg.jpg"), // Apnar background image path
                fit: BoxFit.cover,
                opacity: 0.3, // Image-er upor blue tint rakhar jonno opacity koman thakbe
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                // --- LOGO SECTION (Updated with Image) ---
                const SizedBox(height: 100),
                Center(
                  child: Image.asset(
                    "assets/logo2.png", // Apnar logo image-er path eikhane thakbe
                    height: 60,        // Design onujayi height adjust kora hoyeche
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Jodi chobi na pay, tobe eiti back-up hishabe purono text logo dekhabe
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("G", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                          const Icon(Icons.travel_explore, color: Color(0xFF00D2A0), size: 35),
                          const Text("Buddy", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // --- MAIN WHITE CARD ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Change Password",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),

                      // --- CURRENT PASSWORD FIELD ---
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: "Current Password",
                        icon: Icons.lock_outline,
                        isObscure: true,
                        showSuffix: false,
                      ),

                      // --- NEW PASSWORD FIELD ---
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: "New Password",
                        icon: Icons.lock_outline,
                        isObscure: !_isNewPasswordVisible,
                        showSuffix: true,
                        onSuffixTap: () {
                          setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                        },
                      ),

                      // --- CONFIRM PASSWORD FIELD ---
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: "Confirm New Password",
                        icon: Icons.lock_outline,
                        isObscure: !_isConfirmPasswordVisible,
                        showSuffix: true,
                        onSuffixTap: () {
                          setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                        },
                      ),

                      const SizedBox(height: 20),

                      // --- UPDATE BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D2A0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Update Password",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE INPUT FIELD BUILDER ---
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isObscure,
    bool showSuffix = false,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, spreadRadius: 1)
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        enabled: !_isLoading,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: showSuffix
              ? IconButton(
                  icon: Icon(isObscure ? Icons.toggle_off : Icons.toggle_on, color: Colors.grey, size: 30),
                  onPressed: onSuffixTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}