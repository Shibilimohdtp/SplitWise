import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitwise/models/notification.dart' as model;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // Request permission for iOS devices
    await _fcm.requestPermission();

    // Configure FCM
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
          message.notification?.title ?? '', message.notification?.body ?? '');
      _saveNotificationToFirestore(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap when the app is in the background
    });

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final notification = model.Notification(
      id: '',
      userId: message.data['userId'],
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      createdAt: DateTime.now(),
      groupId: message.data['groupId'],
    );
    await _firestore.collection('notifications').add(notification.toMap());
  }

  Stream<List<model.Notification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => model.Notification.fromFirestore(doc))
            .toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> sendNotification(String userId, String title, String body,
      {String? groupId}) async {
    // In a real app, you'd send this to your server to handle FCM sending
    if (kDebugMode) {
      print('Sending notification to user $userId: $title - $body');
    }
    // For now, we'll just save it to Firestore
    final notification = model.Notification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      groupId: groupId,
    );
    await _firestore.collection('notifications').add(notification.toMap());
  }
}
