import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static void setupFcmListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        'New notification: ${message.notification?.title} - ${message.notification?.body}',
      );
      // show local notification or update UI
    });
  }
}
