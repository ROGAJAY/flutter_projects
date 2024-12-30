import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/theme_provider.dart'; // Import the theme provider

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  List<UserModel> _searchResults = [];
  bool _showClearIcon = false;

  // Search users by email
  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
      _showClearIcon = true; // Show the clear icon when search starts
    });

    try {
      final users = await FirestoreService()
          .searchUserByEmail(_searchController.text.trim());

      if (users.isNotEmpty) {
        setState(() {
          _searchResults = users;
        });
      } else {
        setState(() {
          _errorMessage = 'No users found with this email.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clear the search field and close the keyboard
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showClearIcon = false; // Hide the clear icon
      _searchResults = [];
      _errorMessage = '';
    });
    FocusScope.of(context).unfocus();
  }

  // Navigate to the Chat Screen
  void _navigateToChat(UserModel otherUser) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId != null) {
      final currentUser = await FirestoreService().getUserById(currentUserId);
      if (currentUser != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUser: currentUser,
              otherUser: otherUser,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Users',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Email',
                filled: true,
                fillColor:
                    themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showClearIcon ? Icons.clear : Icons.search,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.blueAccent,
                  ),
                  onPressed: _showClearIcon ? _clearSearch : _searchUsers,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: Container())
                : SizedBox.shrink(), // Show loading indicator if loading
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? SizedBox
                      .shrink() // While loading, show nothing in the list area
                  : _searchResults.isNotEmpty
                      ? ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16.0),
                                leading: CircleAvatar(
                                  backgroundColor: themeProvider.isDarkMode
                                      ? Colors.blueAccent
                                      : Colors.blueAccent,
                                  child: Text(
                                    user.username[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.username,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chat,
                                  color: themeProvider.isDarkMode
                                      ? Colors.blueAccent
                                      : Colors.blueAccent,
                                ),
                                onTap: () => _navigateToChat(user),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: _errorMessage.isNotEmpty
                              ? Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : Text(
                                  'Search For Users Using Email Address',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
