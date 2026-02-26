/// סוד להתחברות כמשתמש אחר (לפי UID) – לאדמין בלבד.
///
/// לא נשמר ב-Git. מועבר בזמן הבנייה:
///   flutter build web --dart-define=ADMIN_LOGIN_SECRET=הסוד-שלך
///
/// חייב להתאים ל-Firebase: firebase functions:config:set admin.login_secret="הסוד"
String? get adminLoginSecret {
  const v = String.fromEnvironment('ADMIN_LOGIN_SECRET', defaultValue: '');
  return v.isEmpty ? null : v;
}
