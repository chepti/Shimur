import 'dart:typed_data';

/// Stub - לפלטפורמות שאינן Web (למשל מובייל) - יישום בסיסי
void downloadBytes(Uint8List bytes, String fileName) {
  // במובייל אפשר להשתמש ב-share_plus או path_provider
  // כרגע נזרוק - האפליקציה כנראה רצה על Web
  throw UnsupportedError('הורדה לא נתמכת בפלטפורמה זו');
}
