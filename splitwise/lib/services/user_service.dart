import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitwise/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getUserNames(List<String> userIds) async {
    List<String> names = [];
    for (String userId in userIds) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        names.add(userData['name'] ?? 'Unknown User');
      } else {
        names.add('Unknown User');
      }
    }
    return names;
  }

  Future<String> getUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['name'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  Future<List<String>> getUserNamesList(List<String> userIds) async {
    List<String> names = [];
    for (String userId in userIds) {
      String name = await getUserName(userId);
      names.add(name);
    }
    return names;
  }

  Future<Map<String, String>> getUserNamesMap(List<String> userIds) async {
    Map<String, String> userNames = {};
    for (String userId in userIds) {
      userNames[userId] = await getUserName(userId);
    }
    return userNames;
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> updateUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).update({
      'name': user.name,
      'username': user.username,
    });
  }

  Future<List<User>> getGroupMembers(List<String> userIds) async {
    List<User> users = [];
    for (String userId in userIds) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        users.add(User.fromFirestore(userDoc));
      }
    }
    return users;
  }
}
