/// הגדרת משתמשים מורשים בלבד.
///
/// אם [allowedUids] ריק או null – כל משתמש מחובר יכול להיכנס (התנהגות רגילה).
/// אם מוגדר ולא ריק – רק UID-ים ברשימה יכולים להשתמש באפליקציה.
///
/// להגדרת משתמש יחיד: הזיני את ה-UID מפיירבייס כאן.
/// לדוגמה: const List<String>? allowedUids = ['abc123xyz'];
/// null = כל משתמש מחובר מורשה. להפעלת הגבלה: ['uid1','uid2']
/// UID מפיירבייס: Firebase Console → Authentication → Users
const List<String>? allowedUids = null;

/// האם יש הגבלת גישה למשתמשים מסוימים בלבד.
bool get isRestrictedToAllowedUsers =>
    allowedUids != null && allowedUids!.isNotEmpty;

/// בודק אם ה-UID מורשה.
bool isUserAllowed(String? uid) {
  if (uid == null) return false;
  if (allowedUids == null || allowedUids!.isEmpty) return true;
  return allowedUids!.contains(uid);
}
