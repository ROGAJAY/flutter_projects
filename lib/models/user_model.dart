class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final bool isOnline;
  final bool isTyping;
  final String? lastMessage;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.isOnline = false,
    this.isTyping = false,
    this.lastMessage,
  });

  // Convert UserModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'isOnline': isOnline,
      'isTyping': isTyping,
      'lastMessage': lastMessage,
    };
  }

  // Convert a Map to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      email: map['email'],
      isOnline: map['isOnline'] ?? false,
      isTyping: map['isTyping'] ?? false,
      lastMessage: map['lastMessage'],
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    bool? isOnline,
    bool? isTyping,
    String? lastMessage,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      isTyping: isTyping ?? this.isTyping,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
