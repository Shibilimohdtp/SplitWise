import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String username;
  final String email;
  final String? profileImageUrl;

  User({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    this.profileImageUrl,
  });

  User.fromFirebase({
    required this.uid,
    required this.email,
    this.name = '',
    this.username = '',
    this.profileImageUrl,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }
}
