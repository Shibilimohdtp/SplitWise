import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final List<String> invitedEmails;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    this.memberIds = const [],
    this.invitedEmails = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'invitedEmails': invitedEmails,
    };
  }

  factory Group.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    if (kDebugMode) {
      print('Group data from Firestore: $data');
    } // Debug print
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      invitedEmails: List<String>.from(data['invitedEmails'] ?? []),
    );
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      creatorId: map['creatorId'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      invitedEmails: List<String>.from(map['invitedEmails'] ?? []),
    );
  }
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    List<String>? invitedEmails,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      invitedEmails: invitedEmails ?? this.invitedEmails,
    );
  }
}
