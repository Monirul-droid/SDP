import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart'; // Standardized configuration import

/// A floating action button featuring a continuous glowing animation.
class ChatBotButton extends StatefulWidget {
  const ChatBotButton({super.key});

  @override
  State<ChatBotButton> createState() => _ChatBotButtonState();
}

class _ChatBotButtonState extends State<ChatBotButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showChatInterface(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20, right: 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2A0).withOpacity(0.3 + (_animationController.value * 0.2)),
                      blurRadius: 15 + (_animationController.value * 10),
                      spreadRadius: 1 + (_animationController.value * 2),
                    ),
                  ],
                ),
              ),
              FloatingActionButton(
                onPressed: () => _showChatInterface(context),
                backgroundColor: const Color(0xFF3285E1),
                elevation: 8,
                shape: const CircleBorder(),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatBottomSheet extends StatefulWidget {
  const ChatBottomSheet({super.key});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// FIXED: Using AppConfig instead of hardcoded strings
  List<String> get _backendHosts {
    return [
      AppConfig.chatBaseUrl, // Tries Port 8000 (main.py) first
      AppConfig.baseUrl,     // Falls back to Port 5000 (app.py) if needed
    ];
  }

  /// FIXED: Clean URL parsing using the config variables
  Future<http.Response> _fetchBackendResponse(List<Map<String, String>> conversationHistory) async {
    Exception? lastError;
    for (final host in _backendHosts) {
      // Constructs the full URL dynamically
      final url = Uri.parse('$host/ask-gobuddy');
      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"messages": conversationHistory}),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          return response;
        }
        lastError = Exception('HTTP ${response.statusCode} from $host');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastError ?? Exception('No backend host available');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final String input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": input});
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      List<Map<String, String>> conversationHistory = [
        {
          "role": "system",
          "content": "You are GoBuddy, a helpful travel assistant. Provide clear, detailed travel answers."
        }
      ];

      for (var msg in _messages) {
        conversationHistory.add({
          "role": msg["role"] ?? "user",
          "content": msg["content"] ?? ""
        });
      }

      final response = await _fetchBackendResponse(conversationHistory);
      final data = jsonDecode(response.body);
      final botResponse = data['reply'] ?? data['error'] ?? 'No response from AI.';

      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "content": botResponse});
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "content": "Connection Error: Ensure your Python backend is running."});
          _isTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // UI code remains the same as your original premium design...
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3285E1), Color(0xFF00D2A0)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: const Center(
              child: Text("GoBuddy Guide", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3285E1) : const Color(0xFFEEF7FF),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      msg["content"] ?? "",
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input Area
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Color(0xFF3285E1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}