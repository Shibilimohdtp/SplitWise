import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/database_helper.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:splitwise/services/notification_service.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();

  Future<Group?> createGroup(
      String name, String description, String creatorId) async {
    try {
      // Validate inputs
      if (name.isEmpty) {
        throw Exception('Group name cannot be empty');
      }
      if (description.isEmpty) {
        throw Exception('Group description cannot be empty');
      }

      final group = Group(
        id: '', // Firestore will generate this
        name: name,
        description: description,
        creatorId: creatorId,
        members: [creatorId], // Ensure the creator is added to the members list
      );

      final bool hasConnection =
          await InternetConnectionChecker().hasConnection;
      if (!hasConnection) {
        // Offline: Save to local database
        await _databaseHelper.insertGroup(group);
        return group;
      } else {
        // Online: Save to Firestore
        try {
          final docRef =
              await _firestore.collection('groups').add(group.toMap());
          final newGroup = group.copyWith(id: docRef.id);
          await docRef.update({'id': docRef.id});
          return newGroup;
        } catch (firestoreError) {
          if (kDebugMode) {
            print('Firestore error in createGroup: $firestoreError');
          }
          throw Exception(
              'Failed to save group to Firestore: ${firestoreError.toString()}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in createGroup: $e');
      }
      throw Exception('Failed to create group: ${e.toString()}');
    }
  }

  Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList());
  }

  Future<void> inviteMember(String groupId, String email) async {
    try {
      // First, find the user with the given email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception(
            'User with email $email not found. Make sure they have registered.');
      }

      final userId = userQuery.docs.first.id;

      // Add the user to the group's members list
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });

      // Get the group details
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Send a notification to the invited user
      await _notificationService.sendNotification(
        userId,
        'Group Invitation',
        'You have been invited to join $groupName',
        groupId: groupId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in inviteMember: $e');
      }
      throw Exception('Failed to invite member: ${e.toString()}');
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> updateGroup(Group group) async {
    await _firestore.collection('groups').doc(group.id).update(group.toMap());
  }

  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }

  Future<void> syncOfflineGroups() async {
    final offlineGroups = await _databaseHelper.getOfflineGroups();
    for (var group in offlineGroups) {
      await _firestore.collection('groups').add(group.toMap());
      await _databaseHelper.deleteGroup(group.id);
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    // Remove the user from all expense split details in this group
    final expenses = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (var doc in expenses.docs) {
      final expenseData = doc.data();
      final splitDetails =
          Map<String, double>.from(expenseData['splitDetails']);
      splitDetails.remove(userId);
      await doc.reference.update({'splitDetails': splitDetails});
    }
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }
}
