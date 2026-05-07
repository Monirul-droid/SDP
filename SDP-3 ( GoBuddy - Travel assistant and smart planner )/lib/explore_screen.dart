import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_register_screen.dart';
import 'config.dart';
/// A screen that serves as the visual entry point of the app, featuring a
/// continuous looping background video and a primary call-to-action button.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

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
      if (mounted) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      }
    }).catchError((error) {
      debugPrint("Video failed to load: $error");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Pauses the background video and navigates to the authentication screen.
  /// Automatically resumes video playback when the user navigates back to this screen.
  void _startExploring() {
    if (_controller.value.isInitialized) {
      _controller.pause();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginRegisterScreen()),
    ).then((_) {
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

          Container(color: Colors.black.withOpacity(0.3)),

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