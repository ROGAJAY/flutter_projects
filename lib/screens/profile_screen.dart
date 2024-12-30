import 'package:flutter/material.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  ProfileScreen({required this.currentUser});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService firestoreService = FirestoreService();

  // Create controllers for the text fields
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  // Flags to check if the name/username is being edited
  bool isEditingName = false;
  bool isEditingUsername = false;

  @override
  void initState() {
    super.initState();
    // Initialize the controllers with the current values
    nameController.text = widget.currentUser.name;
    usernameController.text = widget.currentUser.username;
  }

  // Function to toggle between edit and save
  void _toggleEditMode(String field) {
    setState(() {
      if (field == 'name') {
        isEditingName = !isEditingName;
      } else if (field == 'username') {
        isEditingUsername = !isEditingUsername;
      }
    });

    if (field == 'name' && !isEditingName) {
      // Save the new name if editing is finished
      firestoreService.updateUserName(
          widget.currentUser.id, nameController.text,
          isName: true);
    } else if (field == 'username' && !isEditingUsername) {
      // Save the new username if editing is finished
      firestoreService.updateUserName(
          widget.currentUser.id, usernameController.text,
          isName: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.2),
        ),
      ),
      body: SingleChildScrollView(
        // Wrap the body with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar
              Center(
                child: CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    widget.currentUser.username[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Name Field with StreamBuilder for real-time updates
              StreamBuilder<UserModel>(
                stream: firestoreService.getUserStream(widget.currentUser.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }

                  final currentUser = snapshot.data;
                  nameController.text =
                      currentUser?.name ?? widget.currentUser.name;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      title: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: isEditingName
                          ? TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                              ),
                            )
                          : Text(currentUser?.name ?? widget.currentUser.name),
                      trailing: IconButton(
                        icon: Icon(
                          isEditingName ? Icons.check : Icons.edit,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          _toggleEditMode('name');
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Username Field with StreamBuilder for real-time updates
              StreamBuilder<UserModel>(
                stream: firestoreService.getUserStream(widget.currentUser.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }

                  final currentUser = snapshot.data;
                  usernameController.text =
                      currentUser?.username ?? widget.currentUser.username;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      title: Text(
                        'Username',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: isEditingUsername
                          ? TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your username',
                              ),
                            )
                          : Text(currentUser?.username ??
                              widget.currentUser.username),
                      trailing: IconButton(
                        icon: Icon(
                          isEditingUsername ? Icons.check : Icons.edit,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          _toggleEditMode('username');
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),

              // Email Field
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  title: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(widget.currentUser.email),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
