import 'package:flutter/material.dart';
import 'package:travel_app/theme/theme.dart';
import 'package:travel_app/models/chat_message.dart';
import 'package:travel_app/models/itinerary_data.dart';
import 'package:travel_app/services/ai_service.dart';
import 'package:travel_app/services/chat_storage.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  // Itinerary planning state variables
  ItineraryData _itineraryData = ItineraryData();
  bool _isPlanningItinerary = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _loadChatHistory() async {
    final messages = await ChatStorage.loadMessages();
    final itineraryData = await ChatStorage.loadItineraryData();

    setState(() {
      _messages.addAll(messages);
      _itineraryData = itineraryData;
      // Check if we were in the middle of planning an itinerary
      _isPlanningItinerary =
          !_itineraryData.isComplete() && _itineraryData.destination != null;
    });

    // If no messages, add welcome message
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! I'm your AI travel assistant. How can I help you plan your trip today?",
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      );
    });
    _saveChat();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              backgroundImage: AssetImage('assets/ai_avatar.png'),
              child: Text(
                "AI",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Travel Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera, color: Colors.white70),
            onPressed: () {
              _showImageInputOptions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            onPressed: _resetConversation,
            tooltip: 'Start New Conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How may I help you today?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'I can help you plan trips, suggest destinations, create itineraries, and more!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Chat History Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Conversations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // History items
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHistoryChip('Need itinerary for 3 days in Paris'),
                      _buildHistoryChip('Beach destinations in Thailand'),
                      _buildHistoryChip('Budget hotels in Dubai'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(
            color: Colors.grey,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 16),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white70),
                  onPressed: () {
                    _showImageInputOptions();
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (value) {
                              _sendMessage();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.white70),
                          onPressed: () {
                            // Implement voice input
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: lightColorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _messageController.text = text;
          _sendMessage();
        },
        child: Chip(
          label: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2D2D2D),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              backgroundImage: AssetImage('assets/ai_avatar.png'),
              child: Text(
                "AI",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? lightColorScheme.primary
                        : const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              backgroundImage: AssetImage('assets/User.png'),
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            backgroundImage: AssetImage('assets/ai_avatar.png'),
            child: Text(
              "AI",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedDot(0),
                const SizedBox(width: 4),
                _buildAnimatedDot(1),
                const SizedBox(width: 4),
                _buildAnimatedDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + index * 0.3) % 1,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Debug print
    print("User sent: $text");
    print("Planning mode: $_isPlanningItinerary");
    print("Current itinerary data: ${_itineraryData.toMap()}");

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _messageController.clear();
      _isTyping = true;
    });

    // Auto-scroll to bottom
    _scrollToBottom();

    // Process the message with AI
    _getAIResponse(text);
  }

  void _getAIResponse(String userMessage) async {
    try {
      // Update itinerary data if we're in planning mode
      if (_isPlanningItinerary) {
        _updateItineraryData(userMessage);
      }

      // Get AI response with proper context
      final response = await AIService.getAIResponse(userMessage, {
        ..._itineraryData.toMap(),
        'isPlanningItinerary': _isPlanningItinerary,
        'conversationHistory': _messages
            .map((msg) => '${msg.isUser ? "User" : "AI"}: ${msg.text}')
            .toList()
            .join('\n'),
      });

      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );

        // Check if we should start itinerary planning
        if (!_isPlanningItinerary &&
            (userMessage.toLowerCase().contains('itinerary') ||
                userMessage.toLowerCase().contains('plan') ||
                userMessage.toLowerCase().contains('trip'))) {
          _isPlanningItinerary = true;
          print("Started itinerary planning mode");
        }

        // Check if we have all data and should generate the full itinerary
        if (_isPlanningItinerary && _itineraryData.isComplete()) {
          print("All data collected, generating full itinerary");
          _generateFullItinerary();
        }

        _scrollToBottom();
      });

      _saveChat();
    } catch (e) {
      print("Error getting AI response: $e");
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "Sorry, I'm having trouble responding right now.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _scrollToBottom();
      });
    }
  }

 void _updateItineraryData(String userMessage) {
  // Only update if we're actually in planning mode
  if (!_isPlanningItinerary) return;

  // Debug print
  print("Updating itinerary data with: $userMessage");
  print("Current itinerary state: ${_itineraryData.toMap()}");

  // Determine which field to update based on what's missing
  if (_itineraryData.destination == null) {
    // Use AIService to extract destination from message
    final destination = AIService.extractDestination(userMessage);
    if (destination != null) {
      setState(() {
        _itineraryData.destination = destination;
      });
      print("Updated destination: $destination");
    } else {
      // If no destination found, ask for clarification
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "I'd love to help plan your trip! Where would you like to go?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _saveChat();
      _scrollToBottom();
      return;
    }
  } else if (_itineraryData.days == null) {
    // Extract numbers from the message
    final numbers = userMessage.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isNotEmpty) {
      setState(() {
        _itineraryData.days = int.tryParse(numbers);
      });
      print("Updated days: ${_itineraryData.days}");
    } else {
      // Ask for days clarification
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "How many days will your trip to ${_itineraryData.destination} be?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _saveChat();
      _scrollToBottom();
      return;
    }
  } else if (_itineraryData.budget == null) {
    setState(() {
      _itineraryData.budget = userMessage;
    });
    print("Updated budget: $userMessage");
  } else if (_itineraryData.activities == null) {
    setState(() {
      _itineraryData.activities = userMessage;
    });
    print("Updated activities: $userMessage");
  } else if (_itineraryData.travelers == null) {
    // Extract numbers from the message
    final numbers = userMessage.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isNotEmpty) {
      setState(() {
        _itineraryData.travelers = int.tryParse(numbers);
      });
      print("Updated travelers: ${_itineraryData.travelers}");
    } else {
      // Ask for travelers clarification
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "How many people will be traveling to ${_itineraryData.destination}?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _saveChat();
      _scrollToBottom();
      return;
    }
  } else if (_itineraryData.dates == null) {
    setState(() {
      _itineraryData.dates = userMessage;
    });
    print("Updated dates: $userMessage");
  } else if (_itineraryData.accommodation == null) {
    setState(() {
      _itineraryData.accommodation = userMessage;
    });
    print("Updated accommodation: $userMessage");
  } else if (_itineraryData.travelStyle == null) {
    setState(() {
      _itineraryData.travelStyle = userMessage;
    });
    print("Updated travel style: $userMessage");
  }

  // Debug print to see current state
  print("Itinerary data after update: ${_itineraryData.toMap()}");
  print("Is complete: ${_itineraryData.isComplete()}");
}

  void _generateFullItinerary() async {
    setState(() {
      _isTyping = true;
    });

    try {
      final itinerary = await AIService.generateItinerary(
        _itineraryData.toMap(),
      );

      setState(() {
        _isTyping = false;
        _isPlanningItinerary = false;
        _messages.add(
          ChatMessage(
            text: itinerary,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      _saveChat();
      _scrollToBottom();
    } catch (e) {
      print("Error generating itinerary: $e");
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error generating your itinerary.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _scrollToBottom();
      });
    }
  }

  void _saveChat() async {
    await ChatStorage.saveMessages(_messages);
    await ChatStorage.saveItineraryData(_itineraryData);
  }

  void _resetConversation() async {
    await ChatStorage.clearData();
    setState(() {
      _messages.clear();
      _itineraryData = ItineraryData();
      _isPlanningItinerary = false;
    });
    _addWelcomeMessage();
  }

  void _showImageInputOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement image selection from gallery
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white70),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement camera functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

// class ChatMessage {
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;

//   ChatMessage({
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//   });
// }
