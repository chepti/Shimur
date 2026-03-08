// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// מבקש הרשאת התראות בדפדפן – API מקורי (Firebase Messaging לא מממש requestPermission ב־Web).
Future<bool> requestWebNotificationPermission() async {
  if (html.Notification.supported) {
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  }
  return false;
}

/// בודק אם יש הרשאת התראות – בלי לזרוק.
bool getWebNotificationPermissionGranted() {
  return html.Notification.permission == 'granted';
}
