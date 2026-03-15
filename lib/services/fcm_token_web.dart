// קובץ Web בלבד – משתמש ב־Firebase JS SDK ישירות (עוקף Flutter plugin)
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as dart_js;
import 'package:js/js_util.dart' as js_util;

/// מחזיר טוקן FCM דרך Firebase JS SDK – עוקף את Flutter plugin שזורק MissingPluginException.
/// מחזיר null או מחרוזת שגיאה (מתחילה ב-"ERR:") במקרה כשל.
Future<String?> getFcmTokenViaJs(String vapidKey) async {
  try {
    final promise = dart_js.context.callMethod('getFcmTokenJs', [vapidKey]);
    if (promise == null) return null;
    final token = await js_util.promiseToFuture(promise);
    final s = token?.toString();
    return (s != null && s.isNotEmpty) ? s : null;
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'ERR:הדפדפן חוסם או דחה הרשאה';
    }
    if (msg.contains('service-worker') || msg.contains('Service Worker')) {
      return 'ERR:ודאי ש־https://shimur.web.app/firebase-messaging-sw.js נטען כ־JavaScript (לא HTML)';
    }
    return 'ERR:$msg';
  }
}
