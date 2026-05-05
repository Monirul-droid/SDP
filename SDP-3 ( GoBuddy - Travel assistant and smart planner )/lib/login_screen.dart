import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  // ✅ Static variable jeta puro app theke LoginScreen.userEmail diye access kora jabe
  static String? userEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Logic control variables
  bool isForgotPasswordMode = false;
  bool isLoading = false;
  bool _obscureText = true; // Password hide/show control er jonno

  // Controllers for input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- BACKEND CONNECTION FUNCTION ---
  Future<void> loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ Emulator support er jonno 10.0.2.2 athoba apnar PC IP
      final url = Uri.parse('http://192.168.0.106:5000/login');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        _showSnackBar("Login Successful!", const Color(0xFF00D2A0));

        // ✅ UPDATE: LoginScreen er static variable-e email save kora
        LoginScreen.userEmail = email;

        // Global variable (main.dart e thakle) update
        loggedInUserEmail = email;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showSnackBar(responseData['message'] ?? "Login Failed", Colors.red);
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              Text(
                isForgotPasswordMode ? "Reset Password" : "Login here",
                style: const TextStyle(
                  color: Color(0xFF1CB5D1),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                isForgotPasswordMode
                    ? "Enter your email to receive\na reset link"
                    : "Welcome back you’ve\nbeen missed!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 50),

              // Email TextField
              _buildTextField("Email", _emailController, false),

              if (!isForgotPasswordMode) ...[
                const SizedBox(height: 20),
                // Password TextField with Eye Button
                _buildTextField("Password", _passwordController, true),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() => isForgotPasswordMode = true);
                    },
                    child: const Text(
                      "Forgot your password?",
                      style: TextStyle(
                        color: Color(0xFF1CB5D1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () {
                    if (isForgotPasswordMode) {
                      print("Reset Link Logic Here");
                    } else {
                      loginUser();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CB5D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isForgotPasswordMode ? "Send Reset Link" : "Sign in",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (isForgotPasswordMode)
                TextButton(
                  onPressed: () => setState(() => isForgotPasswordMode = false),
                  child: const Text("Back to Login", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),

              if (!isForgotPasswordMode) ...[
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                  },
                  child: const Text("Create new account", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 50),
                const Text("Or continue with", style: TextStyle(color: Color(0xFF1CB5D1), fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialIcon(Icons.g_mobiledata),
                    const SizedBox(width: 20),
                    _socialIcon(Icons.facebook),
                    const SizedBox(width: 20),
                    _socialIcon(Icons.apple),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF1CB5D1).withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF1CB5D1),
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F4FF), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 30, color: Colors.black),
    );
  }
}