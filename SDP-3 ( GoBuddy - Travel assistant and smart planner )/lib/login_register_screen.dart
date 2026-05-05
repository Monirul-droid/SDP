import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart'; // Add this
import 'login_screen.dart';
import 'register_screen.dart';
import 'profile_screen.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  late VideoPlayerController _controller;
  bool _isScreenVisible = true; // Screen visible ache kina track rakhar jonno

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/bg_video.mp4")
      ..initialize().then((_) {
        _controller.play();
        _controller.setLooping(true);
        _controller.setVolume(1.0);
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose(); //
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // VisibilityDetector screen er visibility check kore
    return VisibilityDetector(
      key: const Key('login-register-key'),
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;

        // Jodi screen 100% visible na thake (mane onno screen e geche), tobe pause koro
        if (visiblePercentage < 1) {
          if (mounted) {
            _controller.pause();
            print("Video Paused - Screen Hidden");
          }
        } else {
          // Jodi user back ashe ebong screen dekha jay, tobe play koro
          if (mounted) {
            _controller.play();
            print("Video Playing - Screen Visible");
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Video
            if (_controller.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),

            Container(color: Colors.black.withOpacity(0.3)), //

            Column(
              children: [

                const Spacer(),

                // Bottom UI Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your Ultimate\nTravel Companion!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1CB5D1),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: _buildButton(
                              text: "Login",
                              bgColor: const Color(0xFF1CB5D1),
                              textColor: Colors.white,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildButton(
                              text: "Register",
                              bgColor: const Color(0xFFF3F5F9),
                              textColor: Colors.black,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String text, required Color bgColor, required Color textColor, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0, //
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildImageCard(String path) {
    return Container(
      width: 300,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
      ),
    );
  }
}