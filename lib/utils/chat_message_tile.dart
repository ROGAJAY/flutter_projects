import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import the services package for haptic feedback
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:intl/intl.dart';
import 'typing_indicator.dart'; // Import the typing indicator file

class ChatMessageTile extends StatefulWidget {
  final ChatMessage message;
  final UserModel currentUser;
  final bool isSelected;
  final Function(ChatMessage) onSelectMessage;
  final Function(ChatMessage) onDeleteMessage;
  final bool isTyping; // Add isTyping parameter

  ChatMessageTile({
    required this.message,
    required this.currentUser,
    required this.isSelected,
    required this.onSelectMessage,
    required this.onDeleteMessage,
    required this.isTyping, // Pass isTyping parameter
    Key? key,
  }) : super(key: key);

  @override
  _ChatMessageTileState createState() => _ChatMessageTileState();
}

class _ChatMessageTileState extends State<ChatMessageTile> {
  @override
  Widget build(BuildContext context) {
    final isSentByCurrentUser =
        widget.message.senderId == widget.currentUser.id;
    final timestamp = DateFormat('h:mm a').format(widget.message.timestamp);

    return GestureDetector(
      onLongPress: () {
        // Trigger selection on long press
        if (!widget.isSelected) {
          widget.onSelectMessage(widget.message);
          // Add haptic feedback for selection
          HapticFeedback.mediumImpact();
        }
      },
      onTap: () {
        // Toggle selection on tap if already selected
        if (widget.isSelected) {
          widget.onSelectMessage(widget.message);
        }
      },
      child: Container(
        width: double.infinity, // Full width of the screen
        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        color: widget.isSelected
            ? Colors.blue
                .withOpacity(0.1) // Highlight color for selected messages
            : Colors.transparent,
        child: Row(
          mainAxisAlignment: isSentByCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
              decoration: BoxDecoration(
                color: isSentByCurrentUser
                    ? Color(0xFF0084FF) // Blue for sent messages
                    : Color(0xFFEAEAEA), // Light grey for received messages
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft:
                      isSentByCurrentUser ? Radius.circular(20) : Radius.zero,
                  bottomRight:
                      isSentByCurrentUser ? Radius.zero : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 80.0), // Increase spacing
                    child: Text(
                      widget.message.text,
                      style: TextStyle(
                        color: isSentByCurrentUser
                            ? Colors.white // White text for sent messages
                            : Colors.black, // Black text for received messages
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Only show timestamp and read status if not typing
                  if (!widget.isTyping)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.0), // Add spacing
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timestamp,
                              style: TextStyle(
                                color: isSentByCurrentUser
                                    ? Colors.white70
                                    : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 8), // Increase spacing
                            if (isSentByCurrentUser)
                              StreamBuilder<bool>(
                                // Read status stream for current user
                                stream: FirestoreService()
                                    .listenForReadStatus(widget.message.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(); // Show a loading indicator while waiting for data
                                  }
                                  final isRead = snapshot.data ?? false;
                                  return Icon(
                                    isRead ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color:
                                        isRead ? Colors.blue : Colors.white70,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  // Show typing indicator if not sent by the current user
                  if (!isSentByCurrentUser && widget.isTyping)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: TypingIndicator(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
