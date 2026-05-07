import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'search_screen.dart';
import 'trip_planning_screen.dart';
import 'budget_planner_screen.dart';
import 'profile_screen.dart';
import 'Notification_Screen.dart';
import 'chat_overlay.dart';
import 'tour_package_screen.dart';
import 'login_screen.dart';
import 'config.dart';
/// The main dashboard screen of the application.
/// Displays a personalized greeting, an animated clock, weather information,
/// a calendar widget, and provides navigation to primary app features.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentBottomIndex = 0;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _clockSlideController;
  late AnimationController _weatherScaleController;
  late AnimationController _dateSlideController;
  late AnimationController _packageBounceController;

  late DateTime _currentTime;
  Timer? _timer;
  String? _userAvatarLink;
  final String baseUrl = "${AppConfig.baseUrl}";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _rotateController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _clockSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _weatherScaleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _dateSlideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _packageBounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _loadUserAvatar();
  }

  /// Fetches the current user's profile avatar link from the backend.
  /// Falls back to a default test email if no user is authenticated.
  Future<void> _loadUserAvatar() async {
    String emailRaw = LoginScreen.userEmail ?? FirebaseAuth.instance.currentUser?.email ?? "test@example.com";
    String userEmail = emailRaw.toLowerCase().trim();

    try {
      final response = await http.get(Uri.parse("$baseUrl/get_user_avatar?email=$userEmail"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['link'] != null && mounted) {
          setState(() {
            _userAvatarLink = data['link'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading avatar: $e");
    }
  }

  /// Returns the current date formatted as 'DD Mon YYYY' (e.g., '12 Jan 2026').
  String _getFormattedDate() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_currentTime.day} ${months[_currentTime.month - 1]} ${_currentTime.year}';
  }

  /// Returns the abbreviated name of the current month.
  String _getMonthName() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[_currentTime.month - 1];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _rotateController.dispose();
    _pulseController.dispose();
    _clockSlideController.dispose();
    _weatherScaleController.dispose();
    _dateSlideController.dispose();
    _packageBounceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String userEmail = LoginScreen.userEmail ?? user?.email ?? "traveler@gmail.com";
    String displayName = userEmail.contains('@') ? userEmail.split('@')[0] : userEmail;

    const Color primaryColor = Color(0xFF00ACC1);
    const Color secondaryColor = Color(0xFF00ACC1);

    return Scaffold(
      floatingActionButton: const ChatBotButton(),
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: _userAvatarLink != null
                        ? NetworkImage(_userAvatarLink!)
                        : null,
                    child: _userAvatarLink == null
                        ? Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white.withOpacity(0.7),
                    )
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $displayName 👋",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          "Explore The World",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: _clockSlideController, curve: Curves.easeOut)),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: Column(
                      children: [
                        _buildClockCard(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildWeatherCardLarge()),
                            const SizedBox(width: 15),
                            Expanded(child: _buildCalendarCard()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTourPackagesButton(),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _currentBottomIndex = index);
          } else {
            Widget nextScreen;
            switch (index) {
              case 1: nextScreen = const TripPlanningScreen(); break;
              case 2: nextScreen = const BudgetPlannerScreen(); break;
              case 3: nextScreen = const NotificationScreen(); break;
              case 4:
                nextScreen = const ProfileScreen();
                Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen)).then((result) {
                  if (result == true) {
                    _loadUserAvatar();
                  }
                });
                return;
              default: nextScreen = const HomeScreen();
            }
            Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen));
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Plan Trip"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Budget"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  /// Builds a card displaying the current time and an animated analog clock.
  Widget _buildClockCard() {
    final Color blockBackgroundColor = Colors.grey.shade100;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _clockSlideController, curve: Curves.easeOut)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: blockBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(_currentTime.hour % 12 == 0 ? 12 : _currentTime.hour % 12).toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')} ${_currentTime.hour >= 12 ? 'PM' : 'AM'}',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFormattedDate(),
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live analog clock',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            _buildAnalogClock(),
          ],
        ),
      ),
    );
  }

  /// Helper widget that renders the analog clock view using CustomPaint.
  Widget _buildAnalogClock() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _AnalogClockPainter(_currentTime),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.cyan,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a scaled-animated card displaying current weather information.
  Widget _buildWeatherCardLarge() {
    final Color blockBackgroundColor = Colors.grey.shade100;

    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _weatherScaleController, curve: Curves.elasticOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: blockBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wb_sunny, color: Color(0xFFFFA500), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              "Weather",
              style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            const Text(
              "28°C - Sunny",
              style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a slide-animated interactive calendar card.
  Widget _buildCalendarCard() {
    final Color blockBackgroundColor = Colors.grey.shade100;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _dateSlideController, curve: Curves.easeOut)),
      child: GestureDetector(
        onTap: () async {
          await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: Colors.cyan),
                ),
                child: child!,
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: blockBackgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.12),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.cyan, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Calendar",
                style: TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                _currentTime.day.toString().padLeft(2, '0'),
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                _getMonthName(),
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a prominent gradient button for navigating to the Tour Packages screen.
  Widget _buildTourPackagesButton() {
    const Color buttonColor = Colors.cyan;
    const Color buttonSecondaryColor = Color(0xFF00ACC1);

    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _packageBounceController, curve: Curves.easeOut),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TourPackageScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [buttonColor, buttonSecondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.card_travel, color: Colors.white, size: 28),
              SizedBox(width: 14),
              Text(
                "Explore Tour Packages",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom painter that draws a live analog clock based on the provided [DateTime].
class _AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;
  _AnalogClockPainter(this.dateTime);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);

    final tickPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180;
      final tickLength = i % 5 == 0 ? 12.0 : 6.0;
      final start = Offset(
        center.dx + math.cos(angle) * (radius - tickLength),
        center.dy + math.sin(angle) * (radius - tickLength),
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(start, end, tickPaint);
    }

    final hourAngle = ((dateTime.hour % 12 + dateTime.minute / 60) * 30 - 90) * math.pi / 180;
    final minuteAngle = ((dateTime.minute + dateTime.second / 60) * 6 - 90) * math.pi / 180;
    final secondAngle = ((dateTime.second + dateTime.millisecond / 1000) * 6 - 90) * math.pi / 180;

    final hourPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final minutePaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final secondPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final hourHand = Offset(
      center.dx + math.cos(hourAngle) * radius * 0.5,
      center.dy + math.sin(hourAngle) * radius * 0.5,
    );
    final minuteHand = Offset(
      center.dx + math.cos(minuteAngle) * radius * 0.72,
      center.dy + math.sin(minuteAngle) * radius * 0.72,
    );
    final secondHand = Offset(
      center.dx + math.cos(secondAngle) * radius * 0.85,
      center.dy + math.sin(secondAngle) * radius * 0.85,
    );

    canvas.drawLine(center, hourHand, hourPaint);
    canvas.drawLine(center, minuteHand, minutePaint);
    canvas.drawLine(center, secondHand, secondPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.dateTime != dateTime;
  }
}