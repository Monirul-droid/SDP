import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_register_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';
import 'favourite_screen.dart';
import 'chat_overlay.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  // ✅ Data Management
  List<dynamic> myTrips = [];
  bool isLoading = true;
  String _fullName = "Loading...";
  String _firstName = "";
  String _lastName = "";
  String _currentEmail = "";
  String _userAvatarLink = ""; // Store user's avatar link
  String _userAvatarName = "";
  bool _avatarUpdated = false; // Track if avatar was updated

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentEmail = LoginScreen.userEmail ?? "siam123@gmail.com";
    _loadUserProfile();
    _loadUserAvatar();
    _loadMyTrips();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh profile when app comes back to foreground
      _refreshProfileIfNeeded();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh profile if email has changed (new user logged in)
    _refreshProfileIfNeeded();
  }

  void _refreshProfileIfNeeded() {
    String newEmail = LoginScreen.userEmail ?? "siam123@gmail.com";
    if (newEmail != _currentEmail) {
      _currentEmail = newEmail;
      _loadUserProfile();
      _loadUserAvatar();
      _loadMyTrips();
    }
  }

  // ✅ FETCH USER PROFILE FROM FASTAPI BACKEND
  Future<void> _loadUserProfile() async {
    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("http://192.168.0.106:5000/get_profile?email=$email");

    debugPrint("📱 Loading profile for email: $email");

    try {
      final response = await http.get(url);
      debugPrint("📱 API Response Status: ${response.statusCode}");
      debugPrint("📱 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("📱 Parsed Data: $data");

        if (mounted) {
          setState(() {
            String firstName = data['firstName']?.toString().trim() ?? "";
            String lastName = data['lastName']?.toString().trim() ?? "";
            
            debugPrint("📱 First Name: '$firstName', Last Name: '$lastName'");
            
            // Combine first and last name
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              _fullName = "$firstName $lastName";
              debugPrint("📱 Setting fullName to: $_fullName");
            } else if (firstName.isNotEmpty) {
              _fullName = firstName;
              debugPrint("📱 Setting fullName to firstName: $_fullName");
            } else if (lastName.isNotEmpty) {
              _fullName = lastName;
              debugPrint("📱 Setting fullName to lastName: $_fullName");
            } else {
              _fullName = "Add Your Full Name";
              debugPrint("📱 No name found, showing prompt");
            }
          });
        }
      } else {
        debugPrint("❌ API Error: Status ${response.statusCode}");
        if (mounted) {
          setState(() {
            _fullName = "Add Your Full Name";
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading profile: $e");
      if (mounted) {
        setState(() {
          _fullName = "Add Your Full Name";
        });
      }
    }
  }

  // ✅ FETCH USER AVATAR FROM DATABASE
  Future<void> _loadUserAvatar() async {
    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("http://192.168.0.106:5000/get_user_avatar?email=$email");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['link'] != null && data['link'].toString().isNotEmpty) {
          setState(() {
            _userAvatarLink = data['link'];
            _userAvatarName = data['name'] ?? "User Avatar";
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading avatar: $e");
    }
  }

  // ✅ FETCH TRIPS FROM FASTAPI BACKEND (SQLite)
  Future<void> _loadMyTrips() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    String email = LoginScreen.userEmail ?? "siam123@gmail.com";
    final url = Uri.parse("http://192.168.0.106:5000/get_itineraries/$email");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            myTrips = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading trips: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGOUT BOTTOM SHEET ---
  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Logout",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Your profile information will be saved to make things easier when you return.",
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44336),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // ✅ ১. গ্লোবাল বাজেট রিসেট করা
                    globalTotalBudget = 0.0;

                    // ✅ ২. গ্লোবাল ইমেইল রিসেট করা
                    LoginScreen.userEmail = null;

                    // ✅ ৩. লগইন স্ক্রিনে পাঠিয়ে দেওয়া এবং সব রুট ক্লিয়ার করা
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
                          (route) => false,
                    );
                  },
                  child: const Text("Logout", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Pass avatar updated flag back to HomeScreen
        Navigator.pop(context, _avatarUpdated);
        return false; // Prevent default behavior since we handle it manually
      },
      child: Scaffold(
        floatingActionButton: const ChatBotButton(),
        body: Container(
          width: double.infinity,
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context, _avatarUpdated); // Return avatar update flag
                      },
                    ),
                    const Text("My Profile",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      },
                    ),
                  ],
                ),
              ),

              // Profile Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      _userAvatarLink.isNotEmpty
                          ? CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(_userAvatarLink),
                              onBackgroundImageError: (exception, stackTrace) {
                                debugPrint("Avatar load error: $exception");
                              },
                            )
                          : CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[400],
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey[200],
                              ),
                            ),
                      const SizedBox(height: 10),
                      Text(_fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(LoginScreen.userEmail ?? "siam123@gmail.com", style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                          if (result == true) {
                            // Refresh profile data after returning from edit screen
                            _loadUserProfile();
                            _loadUserAvatar();
                            _avatarUpdated = true; // Mark avatar as updated
                          }
                        },
                        icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                        label: const Text("Edit Account", style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // MAIN CONTENT AREA
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadMyTrips,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const Text("Other Info.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),

                        _buildProfileItem(Icons.favorite_border, "Favourites", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavouriteScreen()))),
                        _buildProfileItem(Icons.wallet, "My Wallet", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()))),

                        const Divider(height: 40),

                        const Text("My Saved Trips", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 10),

                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : myTrips.isEmpty
                            ? const Center(child: Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Text("No trips found in database.", style: TextStyle(color: Colors.grey)),
                        ))
                            : Column(
                          children: myTrips.map<Widget>((trip) {
                            double costValue = double.tryParse(trip['cost'].toString()) ?? 0.0;
                            return Card(
                              elevation: 1,
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFF3285E1), child: Icon(Icons.location_on, color: Colors.white, size: 20)),
                                title: Text(trip['activity'] ?? "Activity", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Day ${trip['day']} - ${trip['destination']}"),
                                trailing: Text("BDT ${costValue.toStringAsFixed(0)}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 30),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _showLogoutBottomSheet(context),
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.orangeAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}