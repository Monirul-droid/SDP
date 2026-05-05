import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ✨ Premium Animated Bot Button
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
              // Glowing shadow animation
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2A0).withValues(alpha: 0.3 + (_animationController.value * 0.2)),
                      blurRadius: 15 + (_animationController.value * 10),
                      spreadRadius: 1 + (_animationController.value * 2),
                    ),
                    BoxShadow(
                      color: const Color(0xFF3285E1).withValues(alpha: 0.2 + (_animationController.value * 0.15)),
                      blurRadius: 8 + (_animationController.value * 6),
                      spreadRadius: 0.5 + (_animationController.value * 1),
                    ),
                  ],
                ),
              ),
              // Premium Button (fixed position)
              FloatingActionButton(
                onPressed: () => _showChatInterface(context),
                backgroundColor: const Color(0xFF3285E1),
                elevation: 8,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Premium Chat Interface
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

  List<String> get _backendHosts {
    if (Platform.isAndroid) {
      return ['http://192.168.0.106:8000', 'http://192.168.0.106:5000'];
    } else if (Platform.isIOS) {
      return ['http://localhost:8000', 'http://localhost:5000'];
    }
    return ['http://192.168.0.106:8000', 'http://192.168.0.106:5000'];
  }

  Future<http.Response> _fetchBackendResponse(List<Map<String, String>> conversationHistory) async {
    Exception? lastError;
    for (final host in _backendHosts) {
      final url = Uri.parse('$host/ask-gobuddy');
      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"messages": conversationHistory}),
        ).timeout(const Duration(seconds: 12));
        
        debugPrint("📤 Response status: ${response.statusCode}");
        
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
      // ⚡ Build conversation history with system context
      List<Map<String, String>> conversationHistory = [
        {
          "role": "system",
          "content": "You are GoBuddy, a helpful travel assistant for Bangladesh and South Asia. Provide clear, detailed answers with practical suggestions. Keep responses concise but comprehensive. Remember previous context from this conversation."
        }
      ];
      
      // Add all previous messages
      for (var msg in _messages) {
        conversationHistory.add({
          "role": msg["role"] ?? "user",
          "content": msg["content"] ?? msg["text"] ?? ""
        });
      }

      final response = await _fetchBackendResponse(conversationHistory);
      final data = jsonDecode(response.body);
      final botResponse = data['reply'] ?? data['error'] ?? 'Sorry, I could not get a response.';

      if (mounted) {
        setState(() {
          _messages.add({"role": "bot", "content": botResponse});
          _isTyping = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          String errorMsg = "Connection Error: Unable to reach backend";
          if (e.toString().contains("TimeoutException")) {
            errorMsg = "Backend is taking longer than expected, please try again.";
          }
          _messages.add({"role": "bot", "content": errorMsg});
          _isTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3285E1),
            blurRadius: 30,
            spreadRadius: -10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3285E1), Color(0xFF00D2A0)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.travel_explore_outlined, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        "GoBuddy Guide",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Your Travel & Trip Planning Assistant",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Chat Messages Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["role"] == "user";
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? const LinearGradient(
                                  colors: [Color(0xFF3285E1), Color(0xFF1F5AA8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFEEF7FF), Color(0xFFE0F2FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isUser ? 20 : 8),
                            topRight: Radius.circular(isUser ? 8 : 20),
                            bottomLeft: const Radius.circular(20),
                            bottomRight: const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUser
                                  ? const Color(0xFF3285E1).withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg["content"] ?? msg["text"] ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isUser ? Colors.white : const Color(0xFF2C3E50),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF7FF), Color(0xFFE0F2FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "GoBuddy is thinking",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3285E1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        height: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            3,
                            (i) => AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, _) {
                                final value = _animationController.value;
                                final delay = i * 0.1;
                                final animated = (value - delay) % 1;
                                final yOffset = (animated < 0.5)
                                    ? (animated * 8)
                                    : ((1 - animated) * 8);
                                return Transform.translate(
                                  offset: Offset(0, yOffset),
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3285E1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Premium Input Section
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                          color: Color(0xFF3285E1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3285E1), Color(0xFF00D2A0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3285E1),
                        blurRadius: 15,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
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
