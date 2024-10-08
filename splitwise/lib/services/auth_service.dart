import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitwise/models/user.dart';

class AuthService with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _userFromFirebaseUser(auth.User? user) {
    if (user == null) return null;
    return User(uid: user.uid, name: '', username: '', email: user.email!);
  }

  User? get currentUser {
    final firebaseUser = _auth.currentUser;
    return firebaseUser != null ? _userFromFirebaseUser(firebaseUser) : null;
  }

  Stream<User?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  Future<User?> signUp(
      String name, String username, String email, String password) async {
    try {
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      auth.User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // Create a new document for the user with the uid
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'name': name,
          'username': username,
          'email': email,
        });

        User newUser = User(
          uid: firebaseUser.uid,
          name: name,
          username: username,
          email: email,
        );

        notifyListeners();
        return newUser;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
    return null;
  }

  Future<User?> signIn(String email, String password) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      auth.User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // Fetch the user document from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        return User.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> updateUserProfile(User updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.uid).update({
        'name': updatedUser.name,
        'username': updatedUser.username,
      });
      notifyListeners();
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }
}
