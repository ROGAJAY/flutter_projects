import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String receiverId;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    this.read = false,
  });

  // Convert the ChatMessage object to a map for Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': Timestamp.fromDate(timestamp), // Ensure this is a Timestamp
      'read': read,
    };
  }

  // Convert the ChatMessage object to a map for SQLite
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.millisecondsSinceEpoch, // Store as integer
      'read': read ? 1 : 0, // Store as integer
    };
  }

  // Create a ChatMessage object from a Firestore document
  factory ChatMessage.fromFirestoreMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      text: map['text'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      read: map['read'] ?? false,
    );
  }

  // Create a ChatMessage object from an SQLite row
  factory ChatMessage.fromSqliteMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      text: map['text'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      read: map['read'] == 1,
    );
  }
}
