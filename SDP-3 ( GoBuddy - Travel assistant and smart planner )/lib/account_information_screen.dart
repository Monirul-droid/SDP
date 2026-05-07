import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'config.dart';
/// A screen that displays the logged-in user's account information,
/// including their fetched full name, email, and assigned avatar.
class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() => _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  String _fullName = "Loading...";
  String _email = "";
  String _avatarLink = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  /// Fetches the user's profile data (first name and last name) from the backend.
  /// Formats the result into a single full name string.
  ///
  /// Returns:
  ///   Future<void>: Completes when the network request and state update are finished.
  Future<void> _loadAccountInfo() async {
    _email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("${AppConfig.baseUrl}/get_profile?email=$_email");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            String firstName = data['firstName']?.toString().trim() ?? "";
            String lastName = data['lastName']?.toString().trim() ?? "";

            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              _fullName = "$firstName $lastName";
            } else if (firstName.isNotEmpty) {
              _fullName = firstName;
            } else if (lastName.isNotEmpty) {
              _fullName = lastName;
            } else {
              _fullName = "Not Added";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading account info: $e");
      if (mounted) {
        setState(() {
          _fullName = "Error Loading";
        });
      }
    }

    await _loadUserAvatar();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Fetches the user's custom avatar image link from the backend.
  ///
  /// Returns:
  ///   Future<void>: Completes when the avatar link is retrieved and state is updated.
  Future<void> _loadUserAvatar() async {
    try {
      final response = await http.get(Uri.parse("${AppConfig.baseUrl}/get_user_avatar?email=$_email"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['link'] != null && data['link'].toString().isNotEmpty) {
          setState(() {
            _avatarLink = data['link'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading avatar: $e");
    }
  }

  /// Builds the visual interface for the Account Information screen.
  ///
  /// Parameters:
  ///   context (BuildContext): The build context provided by Flutter.
  ///
  /// Returns:
  ///   Widget: The rendered Scaffold containing the user's details.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3285E1), Color(0xFF00D2A0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Account Information",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      _avatarLink.isNotEmpty
                          ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_avatarLink),
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint("Avatar load error: $exception");
                        },
                      )
                          : CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[400],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[200],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Full Name",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                              _fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Email Address",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1CB5D1),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          "This is your account information. To update your full name, please go to your profile and click 'Edit Account'.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}