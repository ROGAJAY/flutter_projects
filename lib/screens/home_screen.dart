import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/search_screen.dart';
import 'package:chat_app/screens/setting_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/theme_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;

  HomeScreen({required this.currentUser});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<UserModel>> _usersStream;
  bool _isDeleting = false;
  List<UserModel> _selectedUsers = [];
  final GlobalKey _moreIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _usersStream = FirestoreService()
        .getUsersWithConversations(widget.currentUser.id)
        .asyncMap((users) async {
      List<UserModel> updatedUsers = [];
      for (var user in users) {
        final lastMessage = await _getLastMessage(user.id);
        updatedUsers.add(user.copyWith(lastMessage: lastMessage));
      }
      return updatedUsers;
    });
    FirestoreService().updateOnlineStatus(widget.currentUser.id, true);
  }

  @override
  void dispose() {
    FirestoreService().updateOnlineStatus(widget.currentUser.id, false);
    super.dispose();
  }

  Future<String> _getLastMessage(String userId) async {
    try {
      final messages = await FirestoreService()
          .getMessages(widget.currentUser.id, userId)
          .first;
      if (messages.isNotEmpty) {
        return messages.last.text;
      }
    } catch (e) {
      print('Error fetching last message: $e');
    }
    return '';
  }

  Future<DateTime?> _getLastMessageTime(String userId) async {
    try {
      final messages = await FirestoreService()
          .getMessages(widget.currentUser.id, userId)
          .first;
      if (messages.isNotEmpty) {
        return messages.last.timestamp;
      }
    } catch (e) {
      print('Error fetching last message time: $e');
    }
    return null;
  }

  void _navigateToChat(UserModel otherUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: widget.currentUser,
          otherUser: otherUser,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await Provider.of<AuthService>(context, listen: false).signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void _showMenu(BuildContext context, Offset tapPosition) {
    final RenderBox renderBox =
        _moreIconKey.currentContext?.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final appBarHeight = AppBar().preferredSize.height;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        appBarHeight + 50,
        0.0,
        0.0,
      ),
      items: [
        _buildPopupMenuItem('profile', Icons.person, 'Profile'),
        _buildPopupMenuItem('settings', Icons.settings, 'Settings'),
        _buildPopupMenuItem('logout', Icons.logout, 'Logout'),
      ],
      elevation: 8.0,
    ).then((value) {
      _handleMenuSelection(value);
    });
  }

  PopupMenuItem _buildPopupMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 28),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String? value) {
    if (value == 'logout') {
      _logout();
    } else if (value == 'settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    } else if (value == 'profile') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(currentUser: widget.currentUser),
        ),
      );
    }
  }

  void _confirmDeleteConversation(UserModel user) {
    setState(() {
      _isDeleting = true;
      if (!_selectedUsers.contains(user)) {
        _selectedUsers.add(user);
      } else {
        _selectedUsers.remove(user);
      }
    });
  }

  Future<void> _deleteConversation() async {
    for (var user in _selectedUsers) {
      try {
        await FirestoreService()
            .clearChatMessages(widget.currentUser.id, user.id);
      } catch (e) {
        print('Error deleting conversation: $e');
      }
    }
    setState(() {
      _isDeleting = false;
      _selectedUsers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isDeleting
            ? null
            : Text('ChatApp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        leading: _isDeleting
            ? Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _isDeleting = false;
                        _selectedUsers.clear();
                      });
                    },
                  ),
                ],
              )
            : null,
        actions: [
          if (!_isDeleting)
            IconButton(
              key: _moreIconKey,
              icon: Icon(Icons.more_vert, size: 30),
              onPressed: () {
                final RenderBox renderBox = _moreIconKey.currentContext
                    ?.findRenderObject() as RenderBox;
                final position = renderBox.localToGlobal(Offset.zero);
                _showMenu(context, position);
              },
            ),
          if (_isDeleting)
            IconButton(
              icon: Icon(Icons.delete, size: 30),
              onPressed: _deleteConversation,
            ),
        ],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Container());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserListTile(user);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
        child: Icon(Icons.search),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildUserListTile(UserModel user) {
    bool isSelected = _selectedUsers.contains(user);
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8.0),
        leading: CircleAvatar(
          radius: 30.0,
          backgroundColor: Colors.blueAccent,
          child: Text(
            user.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            FutureBuilder<DateTime?>(
              future: _getLastMessageTime(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container();
                }
                if (snapshot.hasError) {
                  return Text('Error');
                }
                final lastMessageTime = snapshot.data;
                if (lastMessageTime != null) {
                  final now = DateTime.now();
                  final yesterday = now.subtract(Duration(days: 1));
                  final isYesterday = lastMessageTime.year == yesterday.year &&
                      lastMessageTime.month == yesterday.month &&
                      lastMessageTime.day == yesterday.day;
                  final isOlder = lastMessageTime.isBefore(yesterday);

                  String formattedTime;
                  if (isYesterday) {
                    formattedTime = 'Yesterday';
                  } else if (isOlder) {
                    formattedTime =
                        DateFormat('dd/MM/yyyy').format(lastMessageTime);
                  } else {
                    formattedTime = DateFormat.jm().format(lastMessageTime);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Provider.of<ThemeProvider>(context).isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ],
        ),
        subtitle: Text(
          user.lastMessage ?? '',
          style: TextStyle(
            fontSize: 14,
            color: Provider.of<ThemeProvider>(context).isDarkMode
                ? Colors.grey
                : Colors.grey[600],
          ),
        ),
        onTap: () => _navigateToChat(user),
        onLongPress: () {
          // Add haptic feedback
          HapticFeedback.lightImpact();
          _confirmDeleteConversation(user);
        },
        selected: isSelected,
        selectedTileColor: Colors.blue.withOpacity(0.3),
      ),
    );
  }
}
