import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';
/// A screen that allows users to create a new account by providing an email and password.
/// It validates inputs in real-time and communicates with the backend API.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // States to manage password visibility toggle
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // States for real-time input validation
  bool isMinLength = false;
  bool hasNoSpace = true;
  bool isGmail = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInputs);
    _passwordController.addListener(_validateInputs);
  }

  void _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      isGmail = email.endsWith('@gmail.com') && email.length > 10;
      isMinLength = password.length >= 8;
      hasNoSpace = !password.contains(' ');
    });
  }

  Future<void> registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!isGmail || !isMinLength || !hasNoSpace) {
      _showSnackBar("Please follow all requirements", Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match!", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Endpoint URL for user registration
      final url = Uri.parse('${AppConfig.baseUrl}/register');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _showSnackBar("Registration Successful!", Colors.green);
        if (!mounted) return;
        Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
      } else {
        _showSnackBar(responseData['message'] ?? "Registration Failed", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Server Error: $e", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text("Create Account", style: TextStyle(color: Color(0xFF1CB5D1), fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),

              _buildTextField("Email", _emailController, false, false),
              _validationHint("Must be a valid @gmail.com", isGmail),

              const SizedBox(height: 20),

              // Password field with toggle
              _buildTextField("Password", _passwordController, true, _obscurePassword, onToggle: () {
                setState(() => _obscurePassword = !_obscurePassword);
              }),
              _validationHint("Minimum 8 characters", isMinLength),
              _validationHint("No spaces allowed", hasNoSpace),

              const SizedBox(height: 20),

              // Confirm Password field with toggle
              _buildTextField("Confirm Password", _confirmPasswordController, true, _obscureConfirmPassword, onToggle: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              }),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CB5D1),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign up", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _validationHint(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 10),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green : Colors.red, size: 16),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: isValid ? Colors.green : Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  // Modified TextField to support suffix icons for password toggle
  Widget _buildTextField(String hint, TextEditingController controller, bool isPasswordField, bool obscureText, {VoidCallback? onToggle}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1CB5D1).withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPasswordField ? obscureText : false,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: InputBorder.none,
          // Show the visibility icon only for password fields
          suffixIcon: isPasswordField
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF1CB5D1)),
            onPressed: onToggle,
          )
              : null,
        ),
      ),
    );
  }
}