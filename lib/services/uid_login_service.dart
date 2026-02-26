import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/admin_login_secret.dart';
import '../firebase_options.dart';

/// שירות להתחברות כמשתמש לפי UID דרך HTTP (נמנע מ-Int64 ב-Web).
class UidLoginService {
  static String get _baseUrl {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return 'https://us-central1-$projectId.cloudfunctions.net';
  }

  /// מחזיר Custom Token עבור ה-UID, או זורק שגיאה.
  static Future<String> getCustomTokenForUid(String uid) async {
    if (adminLoginSecret == null || adminLoginSecret!.isEmpty) {
      throw 'לא הוגדר סוד. בנייה: flutter build web --dart-define=ADMIN_LOGIN_SECRET=הסוד';
    }

    final url = Uri.parse('$_baseUrl/getCustomTokenForUidHttp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid.trim(),
        'secret': adminLoginSecret,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw 'הפונקציה החזירה תשובה ריקה';
      }
      return token;
    }

    final body = response.body;
    try {
      final err = jsonDecode(body) as Map<String, dynamic>;
      throw err['error'] as String? ?? body;
    } catch (_) {
      throw body.isNotEmpty ? body : 'שגיאה ${response.statusCode}';
    }
  }
}
