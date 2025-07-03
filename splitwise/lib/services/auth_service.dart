import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/services/group_service.dart';

class AuthService with ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final GroupService _groupService = GroupService();

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

        await _groupService.convertInvitedUser(firebaseUser.uid, email);

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
      if (kDebugMode) {
        print(e.toString());
      }
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
      if (kDebugMode) {
        print(e.toString());
      }
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
      if (kDebugMode) {
        print(e.toString());
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: ${e.toString()}');
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Always sign out from Google first to force the account selection dialog
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }

      // Trigger the authentication flow with account selection prompt
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Check if the user already exists in Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          // Create a new user document if it doesn't exist
          String displayName = firebaseUser.displayName ?? '';
          String email = firebaseUser.email ?? '';
          String username = email.split('@')[0]; // Create a username from email

          await _firestore.collection('users').doc(firebaseUser.uid).set({
            'name': displayName,
            'username': username,
            'email': email,
            'profileImageUrl': firebaseUser.photoURL,
          });

          await _groupService.convertInvitedUser(firebaseUser.uid, email);

          User newUser = User(
            uid: firebaseUser.uid,
            name: displayName,
            username: username,
            email: email,
            profileImageUrl: firebaseUser.photoURL,
          );

          notifyListeners();
          return newUser;
        } else {
          // Return existing user
          return User.fromFirestore(userDoc);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Google sign in error: ${e.toString()}');
      }
      return null;
    }
  }
}
