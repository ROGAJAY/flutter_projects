import 'package:flutter/material.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'chat_message_tile.dart'; // Import the message tile file

class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final UserModel currentUser;
  final UserModel otherUser; // Add otherUser to listen for their typing status
  final ScrollController scrollController;
  final List<ChatMessage> selectedMessages;
  final Function(ChatMessage) onSelectMessage;
  final Function(ChatMessage) onDeleteMessage;

  ChatMessageList({
    required this.messages,
    required this.currentUser,
    required this.otherUser, // Pass otherUser
    required this.scrollController,
    required this.selectedMessages,
    required this.onSelectMessage,
    required this.onDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            reverse: true, // Reverse the order of the messages
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message =
                  messages[messages.length - 1 - index]; // Reverse the index
              final isSelected = selectedMessages.contains(message);
              return ChatMessageTile(
                message: message,
                currentUser: currentUser,
                isSelected: isSelected,
                onSelectMessage: onSelectMessage,
                onDeleteMessage: onDeleteMessage,
                isTyping: false, // Pass isTyping to ChatMessageTile
              );
            },
          ),
        ),
        // Typing indicator based on the stream of the other user's typing status
        StreamBuilder<bool>(
          stream: FirestoreService().listenForTypingStatus(otherUser.id),
          builder: (context, snapshot) {
            final isTyping = snapshot.data ?? false;
            return isTyping
                ? ChatMessageTile(
                    message: ChatMessage(
                      id: 'typing_indicator',
                      text: '',
                      senderId: otherUser.id,
                      receiverId: currentUser.id,
                      timestamp: DateTime.now(),
                    ),
                    currentUser: currentUser,
                    isSelected: false,
                    onSelectMessage: onSelectMessage,
                    onDeleteMessage: onDeleteMessage,
                    isTyping: true, // Pass isTyping to ChatMessageTile
                  )
                : SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
