import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'firestore_service.dart';

import 'notification_permission_stub.dart'
  if (dart.library.html) 'notification_permission_web.dart' as web_perm;
import 'fcm_token_stub.dart'
  if (dart.library.html) 'fcm_token_web.dart' as fcm_token;

String _platformName() {
  if (kIsWeb) return 'web';
  if (defaultTargetPlatform == TargetPlatform.android) return 'android';
  return 'unknown';
}

/// סטטוס התראות Push
class NotificationStatus {
  const NotificationStatus({
    required this.authorized,
    required this.hasToken,
  });
  final bool authorized;
  final bool hasToken;
}

/// שירות להתראות Push – FCM (Firebase Cloud Messaging).
/// תומך ב־Web (PWA) וב־Android.
class NotificationService {
  static const String _vapidKeyWeb =
      'BLYWxjoh8A_Au4cyDxFUDY5Eq4c_oaoVnn2qOjBtcH6zm5mailYzWeA3ozyG-IdaydlW7bQFxbC2dj4VHqifFdQ';

  final FirestoreService _firestore = FirestoreService();

  /// מחזיר סטטוס נוכחי – האם יש הרשאה והאם יש טוקן.
  Future<NotificationStatus> getStatus() async {
    try {
      if (kIsWeb) {
        // ב־Web אין getNotificationSettings – בודקים הרשאה דרך הדפדפן
        if (_vapidKeyWeb.startsWith('REPLACE_')) {
          return const NotificationStatus(authorized: false, hasToken: false);
        }
        if (!web_perm.getWebNotificationPermissionGranted()) {
          return const NotificationStatus(authorized: false, hasToken: false);
        }
        final token = await fcm_token.getFcmTokenViaJs(_vapidKeyWeb);
        return NotificationStatus(
          authorized: true,
          hasToken: token != null && token.isNotEmpty,
        );
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) return const NotificationStatus(authorized: false, hasToken: false);

      String? token;
      if (kIsWeb) {
        if (!_vapidKeyWeb.startsWith('REPLACE_')) {
          token = await messaging.getToken(vapidKey: _vapidKeyWeb);
        }
      } else {
        token = await messaging.getToken();
      }
      return NotificationStatus(authorized: true, hasToken: token != null && token.isNotEmpty);
    } catch (_) {
      return const NotificationStatus(authorized: false, hasToken: false);
    }
  }

  /// מבקש הרשאה ושומר טוקן – לשימוש מכפתור "הפעל התראות".
  /// מחזיר null בהצלחה, או הודעת שגיאה.
  Future<String?> enable() async {
    try {
      if (kIsWeb) {
        // ב־Web: Firebase Messaging לא מממש requestPermission – משתמשים ב־API של הדפדפן
        final granted = await web_perm.requestWebNotificationPermission();
        if (!granted) {
          return 'ההרשאה נדחתה – בדקי בהגדרות הדפדפן שהאתר מורשה להתראות';
        }
      } else {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return 'ההרשאה נדחתה – בדקי בהגדרות שהאפליקציה מורשית להתראות';
        }
        if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
          return 'לא התקבלה תשובה – נסי שוב';
        }
      }

      String? token;
      if (kIsWeb) {
        if (_vapidKeyWeb.startsWith('REPLACE_')) {
          return 'מפתח VAPID חסר – ראי NOTIFICATIONS_SETUP.md';
        }
        final result = await fcm_token.getFcmTokenViaJs(_vapidKeyWeb);
        if (result != null && result.startsWith('ERR:')) {
          return result.substring(4);
        }
        token = result;
        if (token == null || token.isEmpty) {
          return 'לא התקבל טוקן – ודאי ש־https://shimur.web.app/firebase-messaging-sw.js נטען (פתחי את הקישור ובדקי שמוצג קוד JavaScript)';
        }
      } else {
        final messaging = FirebaseMessaging.instance;
        token = await messaging.getToken();
      }

      if (token == null || token.isEmpty) {
        return 'לא התקבל טוקן – ודאי שההרשאה אושרה';
      }

      await _firestore.saveFcmToken(token, _platformName());
      return null;
    } catch (e) {
      // debugPrint('NotificationService.enable: $e');
      final msg = e.toString();
      if (msg.contains('messaging/permission-blocked')) {
        return 'הדפדפן חוסם התראות – בדקי בהגדרות';
      }
      return 'שגיאה: ${msg.length > 80 ? msg.substring(0, 80) : msg}';
    }
  }

  /// שולח התראת בדיקה – קורא ל־Cloud Function.
  /// מחזיר הודעת שגיאה או null בהצלחה.
  Future<String?> sendTestNotification() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('sendTestNotification')
          .call<Map<String, dynamic>>();
      final sent = result.data['sent'] as int? ?? 0;
      if (sent > 0) return null;
      return 'לא נשלחה התראה – ודאי שההתראות מופעלות';
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'שגיאה בשליחת בדיקה';
    } catch (e) {
      return e.toString();
    }
  }

  /// מאתחל FCM – ב־Web לא מבקשים הרשאה אוטומטית (המשתמש לוחץ "הפעל" בהגדרות).
  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        if (_vapidKeyWeb.startsWith('REPLACE_')) return;
        if (!web_perm.getWebNotificationPermissionGranted()) return;
        final token = await fcm_token.getFcmTokenViaJs(_vapidKeyWeb);
        if (token != null && token.isNotEmpty) {
          await _firestore.saveFcmToken(token, _platformName());
        }
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _firestore.saveFcmToken(token, _platformName());
      }
      messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.saveFcmToken(newToken, _platformName());
      });
      FirebaseMessaging.onMessage.listen((_) {});
    } catch (_) {}
  }
}
