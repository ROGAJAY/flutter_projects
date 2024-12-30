import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to the authentication state (logged in/logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up method
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the created user
      User? user = userCredential.user;

      if (user != null) {
        // Create user profile in Firestore
        UserModel newUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          username: username,
        );
        await FirestoreService().createUser(newUser);
      }

      return user;
    } catch (e) {
      print("Error in sign up: $e");
      return null;
    }
  }

  // Sign in method
  Future<User?> signIn(
      {required String email, required String password}) async {
    try {
      // Sign in the user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the signed-in user
      User? user = userCredential.user;
      return user;
    } on FirebaseAuthException catch (e) {
      // Throw the error to the UI layer
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'An error occurred during sign-in.',
      );
    } catch (e) {
      // Handle any other errors and throw a generic error
      throw Exception('An unknown error occurred: $e');
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset method
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error in password reset: $e");
    }
  }
}
