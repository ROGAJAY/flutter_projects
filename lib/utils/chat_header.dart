import 'package:chat_app/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/theme_provider.dart'; // Import your ThemeProvider

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final UserModel otherUser;
  final List<ChatMessage> selectedMessages;
  final VoidCallback onDeleteSelectedMessages;
  final VoidCallback onClearChat;

  const ChatHeader({
    Key? key,
    required this.otherUser,
    required this.selectedMessages,
    required this.onDeleteSelectedMessages,
    required this.onClearChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current theme from the ThemeProvider
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return AppBar(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Match the theme
      elevation: 1, // Subtle shadow for depth
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            otherUser.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          StreamBuilder<bool>(
            stream: FirestoreService().listenForOnlineStatus(otherUser.id),
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? false;
              return Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        // Show delete button only if there are selected messages
        if (selectedMessages.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.delete_forever,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: onDeleteSelectedMessages,
          ),
        // Popup menu for clearing chat
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onSelected: (String result) {
            if (result == 'clear_chat') {
              onClearChat();
            }
          },
          itemBuilder: (BuildContext context) {
            return {'clear_chat'}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text('Clear Chat'),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
