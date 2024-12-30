import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'local_database_helper.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseHelper _localDb = LocalDatabaseHelper();

  // Create or update a user in the 'users' collection
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      print("Error creating user: $e");
    }
  }

  // Get a user by their ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  // Get all users except the current one
  Stream<List<UserModel>> getUsersExceptCurrentUser(String currentUserId) {
    return _db
        .collection('users')
        .where('id', isNotEqualTo: currentUserId) // Exclude current user
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Send a message
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await _db.collection('messages').add(message.toFirestoreMap());
      await _localDb.insertMessage(message);
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Get messages between two users
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    return _db
        .collection('messages')
        .where('senderId', whereIn: [userId1, userId2])
        .where('receiverId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestoreMap(doc.data()))
            .toList());
  }

  // Search users by email (new method)
  Future<List<UserModel>> searchUserByEmail(String email) async {
    try {
      final querySnapshot =
          await _db.collection('users').where('email', isEqualTo: email).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error in searchUserByEmail: $e");
      return [];
    }
  }

  // Clear chat messages between two users
  Future<void> clearChatMessages(String userId1, String userId2) async {
    try {
      final querySnapshot = await _db
          .collection('messages')
          .where('senderId', whereIn: [userId1, userId2]).where('receiverId',
              whereIn: [userId1, userId2]).get();

      final batch = _db.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _localDb.clearChatMessages(userId1, userId2);
    } catch (e) {
      print("Error clearing chat messages: $e");
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final querySnapshot = await _db
          .collection('messages')
          .where('id', isEqualTo: messageId)
          .get();

      final batch = _db.batch();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      await _localDb.deleteMessage(messageId);
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  // Update typing status
  Future<void> updateTypingStatus(String userId, bool isTyping) async {
    try {
      await _db.collection('users').doc(userId).update({'isTyping': isTyping});
    } catch (e) {
      print("Error updating typing status: $e");
    }
  }

  // Listen for typing status
  Stream<bool> listenForTypingStatus(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.data()?['isTyping'] ?? false;
    });
  }

  // Update read status
  Future<void> updateReadStatus(String messageId, bool read) async {
    try {
      final docRef = _db.collection('messages').doc(messageId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        await docRef.update({'read': read});
      } else {
        print("Document does not exist: $messageId");
      }
    } catch (e) {
      print("Error updating read status: $e");
    }
  }

  // Listen for read status
  Stream<bool> listenForReadStatus(String messageId) {
    return _db
        .collection('messages')
        .doc(messageId)
        .snapshots()
        .map((snapshot) {
      return snapshot.data()?['read'] ?? false;
    });
  }

  // Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _db.collection('users').doc(userId).update({'isOnline': isOnline});
    } catch (e) {
      print("Error updating online status: $e");
    }
  }

  // Listen for online status
  Stream<bool> listenForOnlineStatus(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.data()?['isOnline'] ?? false;
    });
  }

  // Update user's name or username
  Future<void> updateUserName(String userId, String newValue,
      {required bool isName}) async {
    try {
      if (isName) {
        await _db.collection('users').doc(userId).update({
          'name': newValue,
        });
      } else {
        await _db.collection('users').doc(userId).update({
          'username': newValue,
        });
      }
    } catch (e) {
      print("Error updating user name/username: $e");
    }
  }

  // Get a stream of the user data for real-time updates
  Stream<UserModel> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snapshot) {
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Get users who have had conversations with the current user
  Stream<List<UserModel>> getUsersWithConversations(String currentUserId) {
    return _db
        .collection('messages')
        .where('senderId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> users = [];
      Set<String> userIds = {};
      for (var doc in snapshot.docs) {
        String receiverId = doc.data()['receiverId'];
        if (!userIds.contains(receiverId)) {
          userIds.add(receiverId);
          DocumentSnapshot userDoc =
              await _db.collection('users').doc(receiverId).get();
          if (userDoc.exists) {
            final lastMessage =
                await _getLastMessage(currentUserId, receiverId);
            users.add(UserModel.fromMap(userDoc.data() as Map<String, dynamic>)
                .copyWith(lastMessage: lastMessage));
          }
        }
      }
      return users;
    });
  }

  // Fetch the last message between two users
  Future<String> _getLastMessage(String userId1, String userId2) async {
    try {
      final messages = await getMessages(userId1, userId2).first;
      if (messages.isNotEmpty) {
        return messages.last.text;
      }
    } catch (e) {
      print('Error fetching last message: $e');
    }
    return '';
  }
}
