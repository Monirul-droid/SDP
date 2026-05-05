import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_register_screen.dart'; //

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key}); // Nam thik kora hoyeche

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/bg_video1.mp4");

    _controller.initialize().then((_) {
      // Check if the widget is still in the tree to avoid calling setState on a disposed widget
      if (mounted) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      }
    }).catchError((error) {
      print("Video failed to load: $error");
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Screen close hole memory clear korbe
    super.dispose();
  }

  // Next screen-e jaoar somoy video pause korar logic
  void _startExploring() {
    // 1. Tell the video to pause without 'awaiting' it
    // This prevents the UI thread from hanging.
    if (_controller.value.isInitialized) {
      _controller.pause();
    }

    // 2. Immediate navigation
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
    ).then((_) {
      // 3. This runs when you come BACK to this screen
      if (mounted && _controller.value.isInitialized) {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Video Layer
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
            )
          else
            Container(color: Colors.black),

          // Dark Overlay
          Container(color: Colors.black.withOpacity(0.3)),

          // 2. Let's Explore Button
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 50.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _startExploring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        "Let's Explore",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}