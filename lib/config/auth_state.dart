/// מחזיק את ה-UID שאומת על ידי AuthWrapper.
/// משמש כ-fallback כש-Firebase Auth מחזיר null ב-Web (בעיית סנכרון).
class AuthState {
  AuthState._();

  static String? _verifiedUid;

  /// קובע את ה-UID שאומת – נקרא מ-AuthWrapper כשהמשתמש נכנס בהצלחה.
  static void setVerifiedUid(String uid) {
    _verifiedUid = uid;
  }

  /// מנקה – נקרא בהתנתקות.
  static void clear() {
    _verifiedUid = null;
  }

  /// מחזיר את ה-UID שאומת, אם קיים.
  static String? get verifiedUid => _verifiedUid;
}
