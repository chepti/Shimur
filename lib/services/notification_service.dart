import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'firestore_service.dart';

String _platformName() {
  if (kIsWeb) return 'web';
  if (defaultTargetPlatform == TargetPlatform.android) return 'android';
  return 'unknown';
}

/// שירות להתראות Push – FCM (Firebase Cloud Messaging).
/// תומך ב־Web (PWA) וב־Android.
class NotificationService {
  static const String _vapidKeyWeb =
      'BLYWxjoh8A_Au4cyDxFUDY5Eq4c_oaoVnn2qOjBtcH6zm5mailYzWeA3ozyG-IdaydlW7bQFxbC2dj4VHqifFdQ'; // לייצר ב־Firebase Console → Cloud Messaging → Web Push certificates

  final FirestoreService _firestore = FirestoreService();

  /// מאתחל FCM, מבקש הרשאה (Web/iOS), ומעדכן טוקן ב־Firestore.
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // הרשאה – נדרש ב־Web וב־iOS
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // טוקן
      String? token;
      if (kIsWeb) {
        if (_vapidKeyWeb.startsWith('REPLACE_')) {
          return; // אין מפתח VAPID – דלג
        }
        token = await messaging.getToken(vapidKey: _vapidKeyWeb);
      } else {
        token = await messaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        await _firestore.saveFcmToken(token, _platformName());
      }

      // עדכון טוקן כשמתחדש
      messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.saveFcmToken(newToken, _platformName());
      });

      // התראות במצב קדמי
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // אפשר להציג SnackBar או לעדכן UI
        // כרגע ההתראה נשלחת מהשרת עם notification payload – הדפדפן/מערכת יציגו
      });
    } catch (e) {
      // שקט – לא קריטי
    }
  }
}
