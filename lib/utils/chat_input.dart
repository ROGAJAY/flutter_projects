import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/theme_provider.dart'; // Assuming ThemeProvider is in this file

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSendPressed;
  final ValueChanged<bool> onEmojiPickerToggle;

  ChatInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSendPressed,
    required this.onEmojiPickerToggle,
  });

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showEmojiPicker = false;

  @override
  Widget build(BuildContext context) {
    // Get the current theme from the ThemeProvider
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      children: [
        // Chat input without opacity
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              // Text Input with Emoji Button inside
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  onTap: () {
                    if (_showEmojiPicker) {
                      widget.focusNode.requestFocus();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    prefixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                        widget.onEmojiPickerToggle(_showEmojiPicker);
                        if (_showEmojiPicker) {
                          widget.focusNode.unfocus();
                        } else {
                          widget.focusNode.requestFocus();
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: Duration(
                            milliseconds: 300), // Smooth transition duration
                        child: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard
                              : Icons.emoji_emotions,
                          key: ValueKey<bool>(
                              _showEmojiPicker), // Key helps AnimatedSwitcher track changes
                          color: isDarkMode ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Send Button with Teal Blue Color
              GestureDetector(
                onTap: widget.isSending ? null : widget.onSendPressed,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isSending
                        ? Colors.grey.withOpacity(0.5)
                        : isDarkMode
                            ? Colors.blueAccent // Dark Mode: Teal Blue 700
                            : Colors.blueAccent, // Light Mode: Teal Blue 400
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white, // Icon color
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Emoji Picker
        Offstage(
          offstage: !_showEmojiPicker,
          child: SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                widget.controller.text += emoji.emoji;
              },
            ),
          ),
        ),
      ],
    );
  }
}
