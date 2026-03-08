import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'firestore_service.dart';

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
  Future<bool> enable() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return false;

      String? token;
      if (kIsWeb) {
        if (_vapidKeyWeb.startsWith('REPLACE_')) return false;
        token = await messaging.getToken(vapidKey: _vapidKeyWeb);
      } else {
        token = await messaging.getToken();
      }

      if (token != null && token.isNotEmpty) {
        await _firestore.saveFcmToken(token, _platformName());
        return true;
      }
      return false;
    } catch (_) {
      return false;
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
