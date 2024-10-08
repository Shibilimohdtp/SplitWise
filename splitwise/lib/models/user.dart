import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid; // Changed from 'id' to 'uid'
  final String name;
  final String username;
  final String email;

  User({
    required this.uid, // Changed from 'id' to 'uid'
    required this.name,
    required this.username,
    required this.email,
  });

  // Update the named constructor
  User.fromFirebase({
    required this.uid, // Changed from 'id' to 'uid'
    required this.email,
    this.name = '',
    this.username = '',
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id, // Changed from 'id' to 'uid'
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
    };
  }
}
