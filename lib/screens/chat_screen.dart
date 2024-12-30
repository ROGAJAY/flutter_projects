import 'dart:async';
import 'package:chat_app/utils/chat_header.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/utils/chat_input.dart';
import 'package:chat_app/utils/chat_message_list.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/services/local_database_helper.dart';

class ChatScreen extends StatefulWidget
    with WidgetsBindingObserver, RouteAware {
  final UserModel currentUser;
  final UserModel otherUser;

  ChatScreen({required this.currentUser, required this.otherUser});

  @override
  _ChatScreenState createState() => _ChatScreenState();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      FirestoreService().updateTypingStatus(currentUser.id, false);
      FirestoreService().updateOnlineStatus(currentUser.id, false);
    } else if (state == AppLifecycleState.resumed) {
      FirestoreService().updateOnlineStatus(currentUser.id, true);
    }
  }

  @override
  void didPush() {
    super.didPush();
    FirestoreService().updateTypingStatus(currentUser.id, true);
  }

  @override
  void didPop() {
    super.didPop();
    FirestoreService().updateTypingStatus(currentUser.id, false);
  }

  @override
  void didPushNext() {
    super.didPushNext();
    FirestoreService().updateTypingStatus(currentUser.id, false);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    FirestoreService().updateTypingStatus(currentUser.id, true);
  }
}

class _ChatScreenState extends State<ChatScreen> with RouteAware {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;
  bool _isTyping = false;
  FocusNode _focusNode = FocusNode();
  ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  late List<ChatMessage> _messages = [];
  List<ChatMessage> _selectedMessages = [];
  Timer? _typingTimer;
  late Stream<List<ChatMessage>> _messagesStream;
  late Future<List<ChatMessage>> _localMessagesFuture;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    FirestoreService().updateOnlineStatus(widget.currentUser.id, true);
    _focusNode.addListener(_onFocusChange);

    _scrollController.addListener(_scrollListener);

    _messagesStream = FirestoreService()
        .getMessages(widget.currentUser.id, widget.otherUser.id);
    _localMessagesFuture = LocalDatabaseHelper()
        .getMessages(widget.currentUser.id, widget.otherUser.id);

    _messagesStream.listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        if (_isAtBottom) {
          _scrollToBottom();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Update read status when the recipient views the message
    _messagesStream.listen((messages) {
      updateReadStatusForMessages(messages, widget.currentUser.id);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _typingTimer?.cancel();
    FirestoreService().updateOnlineStatus(widget.currentUser.id, false);
    super.dispose();
  }

  void _onTextChanged() {
    final isTyping = _controller.text.isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      FirestoreService().updateTypingStatus(widget.currentUser.id, isTyping);
    }

    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(Duration(seconds: 2), () {
        if (_controller.text.isEmpty) {
          FirestoreService().updateTypingStatus(widget.currentUser.id, false);
        }
      });
    } else {
      _typingTimer?.cancel();
      FirestoreService().updateTypingStatus(widget.currentUser.id, false);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {});
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _isAtBottom = true;
      });
    } else {
      setState(() {
        _isAtBottom = false;
      });
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _isSending = true;
      });

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _controller.text,
        senderId: widget.currentUser.id,
        receiverId: widget.otherUser.id,
        timestamp: DateTime.now(),
      );

      try {
        await FirestoreService().sendMessage(message);
        await LocalDatabaseHelper().insertMessage(message);
        _controller.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
          if (_isAtBottom) {
            _scrollToBottom();
          }
        }
      }
    }
  }

  void _clearChat() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Chat'),
          content: Text('Are you sure you want to clear the chat?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirestoreService().clearChatMessages(
                  widget.currentUser.id,
                  widget.otherUser.id,
                );
                await LocalDatabaseHelper().clearChatMessages(
                  widget.currentUser.id,
                  widget.otherUser.id,
                );
                setState(() {
                  _messages.clear();
                });
                _scrollToBottom(); // Ensure the scroll position is updated
              },
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedMessages() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Messages'),
          content:
              Text('Are you sure you want to delete the selected messages?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                for (var message in _selectedMessages) {
                  try {
                    await FirestoreService().deleteMessage(message.id);
                    await LocalDatabaseHelper().deleteMessage(message.id);
                    setState(() {
                      _messages.remove(message);
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete message: $e')),
                    );
                  }
                }
                setState(() {
                  _selectedMessages.clear();
                });
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _selectMessage(ChatMessage message) {
    setState(() {
      if (_selectedMessages.contains(message)) {
        _selectedMessages.remove(message);
      } else {
        _selectedMessages.add(message);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void updateReadStatusForMessages(
      List<ChatMessage> messages, String currentUserId) {
    for (var message in messages) {
      if (message.receiverId == currentUserId && !message.read) {
        FirestoreService().updateReadStatus(message.id, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatHeader(
        otherUser: widget.otherUser,
        selectedMessages: _selectedMessages,
        onDeleteSelectedMessages: _deleteSelectedMessages,
        onClearChat: _clearChat,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Container());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return FutureBuilder<List<ChatMessage>>(
                    future: _localMessagesFuture,
                    builder: (context, localSnapshot) {
                      if (localSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: Container());
                      }
                      if (localSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${localSnapshot.error}'));
                      }
                      if (!localSnapshot.hasData ||
                          localSnapshot.data!.isEmpty) {
                        return Center(child: Text('No messages'));
                      }
                      return ChatMessageList(
                        messages: localSnapshot.data!,
                        currentUser: widget.currentUser,
                        otherUser: widget.otherUser,
                        scrollController: _scrollController,
                        selectedMessages: _selectedMessages,
                        onSelectMessage: _selectMessage,
                        onDeleteMessage: (ChatMessage message) {
                          _deleteSelectedMessages();
                        },
                      );
                    },
                  );
                }
                return ChatMessageList(
                  messages: snapshot.data!,
                  currentUser: widget.currentUser,
                  otherUser: widget.otherUser,
                  scrollController: _scrollController,
                  selectedMessages: _selectedMessages,
                  onSelectMessage: _selectMessage,
                  onDeleteMessage: (ChatMessage message) {
                    _deleteSelectedMessages();
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _controller,
            focusNode: _focusNode,
            isSending: _isSending,
            onSendPressed: _sendMessage,
            onEmojiPickerToggle: (bool value) {
              // No need to handle emoji picker here
            },
          ),
        ],
      ),
    );
  }
}
