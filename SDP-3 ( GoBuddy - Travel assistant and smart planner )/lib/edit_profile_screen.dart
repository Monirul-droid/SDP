import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // আপনার Flask সার্ভারের URL (Emulator এর জন্য 10.0.2.2 ব্যবহার করুন)
  final String baseUrl = "http://192.168.0.106:5000";

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String _fullName = "Loading...";
  late String _userEmail; // Get from logged-in user
  bool _isLoading = false;
  
  // Avatar related
  List<dynamic> _avatars = [];
  int? _selectedAvatarId;
  String _selectedAvatarLink = "";
  bool _isLoadingAvatars = false;

  @override
  void initState() {
    super.initState();
    // Get the actual logged-in user's email
    _userEmail = (LoginScreen.userEmail ?? "test@example.com").toLowerCase().trim();
    _loadUserData();
    _loadAvatars();
  }

  // Load all available avatars from backend
  Future<void> _loadAvatars() async {
    setState(() => _isLoadingAvatars = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_all_avatars"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _avatars = data;
          _isLoadingAvatars = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading avatars: $e");
      setState(() => _isLoadingAvatars = false);
    }
    
    // Load user's current avatar
    _loadUserAvatar();
  }

  // Load user's currently selected avatar
  Future<void> _loadUserAvatar() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_user_avatar?email=$_userEmail"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['id'] != null) {
          setState(() {
            _selectedAvatarId = data['id'];
            _selectedAvatarLink = data['link'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user avatar: $e");
    }
  }

  // API থেকে প্রোফাইল ডেটা আনা
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_profile?email=$_userEmail"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstNameController.text = data['firstName'];
          _lastNameController.text = data['lastName'];
          _fullName = "${data['firstName']} ${data['lastName']}";
        });
      } else {
        setState(() => _fullName = "User Not Found");
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // API এর মাধ্যমে ডেটা আপডেট করা
  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    try {
      // Save profile data
      final response = await http.post(
        Uri.parse("$baseUrl/update_profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _userEmail,
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to update profile");
      }

      // Save avatar if selected
      if (_selectedAvatarId != null) {
        final avatarResponse = await http.post(
          Uri.parse("$baseUrl/save_user_avatar"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": _userEmail,
            "avatar_id": _selectedAvatarId,
          }),
        );
        if (avatarResponse.statusCode != 200) {
          debugPrint("Warning: Avatar save failed");
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
        Navigator.pop(context, true); // Return true to signal avatar was updated
      }
    } catch (e) {
      debugPrint("Error updating data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving data!")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
            children: [
              // --- HEADER SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Edit Profile",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextButton(
                      onPressed: _saveData,
                      child: const Text("Done", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // --- PROFILE PICTURE SECTION ---
                      Stack(
                        children: [
                          _selectedAvatarLink.isNotEmpty
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(_selectedAvatarLink),
                                  onBackgroundImageError: (exception, stackTrace) {
                                    debugPrint("Avatar load error: $exception");
                                  },
                                )
                              : CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[400],
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[200],
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 30),

                      // --- INPUT FIELDS ---
                      _buildInputField("First Name", _firstNameController),
                      _buildInputField("Last Name", _lastNameController),

                      const SizedBox(height: 30),

                      // --- AVATAR SELECTION ---
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Avatar",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _isLoadingAvatars
                          ? const Center(child: CircularProgressIndicator())
                          : _avatars.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No avatars available",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _avatars.length,
                                    itemBuilder: (context, index) {
                                      final avatar = _avatars[index];
                                      final isSelected = _selectedAvatarId == avatar['id'];
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedAvatarId = avatar['id'];
                                            _selectedAvatarLink = avatar['link'];
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: isSelected ? Colors.white : Colors.transparent,
                                              width: 3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: CircleAvatar(
                                            radius: 40,
                                            backgroundImage: NetworkImage(avatar['link']),
                                            onBackgroundImageError: (exception, stackTrace) {
                                              debugPrint("Avatar load error: $exception");
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                      const SizedBox(height: 30),
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

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              border: InputBorder.none,
              suffixIcon: Icon(Icons.check, color: Color(0xFF00D2A0), size: 20),
            ),
          ),
        ),
      ],
    );
  }
}