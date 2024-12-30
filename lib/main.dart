import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/theme_provider.dart'; // Import the theme provider
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  // Initialize sqflite for desktop support
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(
            create: (context) => ThemeProvider()), // Provide ThemeProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Chat App',
            theme: themeProvider.isDarkMode
                ? ThemeData.dark().copyWith(
                    scaffoldBackgroundColor: Color(0xFF121212),
                    appBarTheme: AppBarTheme(
                      backgroundColor: Color(0xFF121212),
                      iconTheme: IconThemeData(color: Colors.white),
                      titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    drawerTheme: DrawerThemeData(
                      backgroundColor: Color(0xFF121212),
                    ),
                    cardTheme: CardTheme(
                      color: Colors.grey.shade900,
                    ),
                    listTileTheme: ListTileThemeData(
                      iconColor: Colors.white,
                      textColor: Colors.white,
                    ),
                  )
                : ThemeData.light().copyWith(
                    scaffoldBackgroundColor: Colors.white,
                    appBarTheme: AppBarTheme(
                      backgroundColor: Colors.white,
                      iconTheme: IconThemeData(color: Colors.black),
                      titleTextStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    drawerTheme: DrawerThemeData(
                      backgroundColor: Colors.white,
                    ),
                    cardTheme: CardTheme(
                      color: Colors.white,
                    ),
                    listTileTheme: ListTileThemeData(
                      iconColor: Colors.black,
                      textColor: Colors.black,
                    ),
                  ),
            home: AuthWrapper(),
            routes: {
              '/login': (context) => LoginScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          return FutureBuilder<UserModel?>(
            future: FirestoreService().getUserById(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }
              if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }
              final user = userSnapshot.data;
              if (user != null) {
                return HomeScreen(currentUser: user);
              } else {
                return Center(child: Text('User data not found.'));
              }
            },
          );
        }
        return LoginScreen();
      },
    );
  }
}
