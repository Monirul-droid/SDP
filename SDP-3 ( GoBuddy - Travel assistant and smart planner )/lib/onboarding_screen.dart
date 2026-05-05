import 'dart:ui';
import 'package:flutter/material.dart';
import 'explore_screen.dart';
import 'login_register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/discover.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Dark overlay for readability
          Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),

          // 3. Content Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Top bar: Logo and Bookmark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "GoBuddy",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.bookmark_outline, color: Colors.white),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Center Content


                  const Spacer(flex: 1),

                  // 4. Bottom Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- UPGRADED SKIP BUTTON (PILL STYLE) ---
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: InkWell( // Use InkWell for better touch feedback
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 56, // Same height as the Next button
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Skip",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Next Circular Button
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00AFA0),
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.all(16),
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ExploreScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}