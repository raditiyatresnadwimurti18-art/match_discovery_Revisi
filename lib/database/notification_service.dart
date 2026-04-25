import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isListening = false;
  static bool _isFirstLoad = true;

  static Future<void> init() async {
    // 1. Request Permission FCM
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // 2. Request Permission Local Notifications (Android 13+)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(settings: initializationSettings);

    // 4. Create Notification Channel (Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'lomba_channel',
      'Lomba Notifications',
      description: 'Notifikasi untuk update lomba terbaru',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Listen for Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification?.title ?? 'Notifikasi',
          body: message.notification?.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Memantau koleksi 'notifications' untuk user tertentu
  static void listenToUserNotifications(String userId) {
    print("NotificationService: Mulai memantau notifikasi untuk user $userId...");

    FirebaseFirestore.instance
        .collection('notifications')
        .where('targetId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            // Konversi Timestamp ke String agar bisa di-encode ke JSON
            Map<String, dynamic> serializableData = Map.from(data);
            serializableData.forEach((key, value) {
              if (value is Timestamp) {
                serializableData[key] = value.toDate().toIso8601String();
              }
            });

            _showLocalNotification(
              title: data['title'] ?? 'Notifikasi Baru',
              body: data['body'] ?? '',
              payload: jsonEncode(serializableData),
            );
            // Tandai sudah dibaca agar tidak muncul lagi saat app restart
            change.doc.reference.update({'isRead': true});
          }
        }
      }
    });
  }

  /// Memantau koleksi 'lomba' di Firestore untuk notifikasi real-time
  static void listenToNewLomba() {
    if (_isListening) return;
    _isListening = true;
    _isFirstLoad = true; // Reset flag

    print("NotificationService: Mulai memantau lomba baru...");

    FirebaseFirestore.instance
        .collection('lomba')
        .snapshots()
        .listen((snapshot) {
      // Jika baru pertama kali load, jangan munculkan notifikasi untuk data lama
      if (_isFirstLoad) {
        _isFirstLoad = false;
        print("NotificationService: Load data awal selesai, mengabaikan notifikasi lama.");
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            _showLocalNotification(
              title: '🏆 Lomba Baru Tersedia!',
              body: 'Lomba: ${data['judul'] ?? '-'} di ${data['lokasi'] ?? '-'}',
              payload: jsonEncode(data),
            );
          }
        }
      }
    });
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'lomba_channel',
      'Lomba Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      id: DateTime.now().microsecondsSinceEpoch % 100000, // ID unik
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> subscribeToLombaTopic() async {
    try {
      await _messaging.subscribeToTopic('lomba');
      print('Subscribed to lomba topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
}
