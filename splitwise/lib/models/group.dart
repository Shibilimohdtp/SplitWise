import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class Group {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> members;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.members,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'members': jsonEncode(members),
    };
  }

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
    );
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      creatorId: map['creatorId'],
      members: List<String>.from(jsonDecode(map['members'])),
    );
  }
}
