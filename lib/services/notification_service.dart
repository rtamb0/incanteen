import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static void setupFcmListener() {
    try {
      FirebaseMessaging.onMessage.listen((message) {
        // Use debugPrint instead of print to satisfy avoid_print lint.
        debugPrint(
          'Foreground FCM message: ${message.messageId} title=${message.notification?.title}',
        );
      });
    } catch (e) {
      debugPrint('NotificationService.setupFcmListener error: $e');
    }
  }
}
