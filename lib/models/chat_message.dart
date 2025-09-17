class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType; // text, image, suggestion

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.messageType = 'text',
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'],
      isUser: map['isUser'],
      timestamp: DateTime.parse(map['timestamp']),
      messageType: map['messageType'],
    );
  }
}