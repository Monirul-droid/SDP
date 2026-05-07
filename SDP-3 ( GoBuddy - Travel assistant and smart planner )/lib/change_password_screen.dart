import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'config.dart';

/// A screen that allows users to securely change their account password.
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

  final String baseUrl = "${AppConfig.baseUrl}";

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates user input and sends a request to the backend API
  /// to update the user's password.
  ///
  /// Returns:
  ///   Future<void>: Completes when the password change network request is finished.
  Future<void> _changePassword() async {
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
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
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

  /// Displays a brief message at the bottom of the screen.
  ///
  /// Parameters:
  ///   message (String): The text to be displayed.
  ///   color (Color): The background color of the snackbar.
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3285E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/header_bg.jpg"),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Image.asset(
                    "assets/logo2.png",
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("G", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                          Icon(Icons.travel_explore, color: Color(0xFF00D2A0), size: 35),
                          Text("Buddy", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
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
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: "Current Password",
                        icon: Icons.lock_outline,
                        isObscure: true,
                        showSuffix: false,
                      ),
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

  /// Builds a standardized custom text field widget used for password inputs.
  ///
  /// Parameters:
  ///   controller (TextEditingController): The controller for the text field.
  ///   label (String): The placeholder hint text.
  ///   icon (IconData): The leading icon for the field.
  ///   isObscure (bool): Whether the text should be hidden (for passwords).
  ///   showSuffix (bool): Whether to show the visibility toggle icon.
  ///   onSuffixTap (VoidCallback?): The action to perform when the suffix icon is tapped.
  ///
  /// Returns:
  ///   Widget: A styled container housing the text input field.
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