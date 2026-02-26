import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// מחכה עד שה-auth מוכן (לאחר התחברות עם custom token עלול להיות עיכוב).
  Future<String?> ensureUserIdReady() async {
    // ניסיון ראשון – אם כבר מחובר
    if (_auth.currentUser != null) return _auth.currentUser!.uid;
    // המתנה קצרה ו-retry (פתרון ל-Web שבו currentUser עלול להיות null לרגע)
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_auth.currentUser != null) return _auth.currentUser!.uid;
    }
    // ניסיון אחרון דרך authStateChanges
    try {
      return await _auth.authStateChanges()
          .where((u) => u != null)
          .map((u) => u!.uid)
          .first
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return _auth.currentUser?.uid;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
    String schoolSymbol,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// התחברות עם Custom Token – מאפשרת להיכנס כמשתמש ספציפי לפי UID.
  /// הטוקן נוצר בצד שרת (Firebase Admin SDK / Cloud Function).
  Future<UserCredential?> signInWithCustomToken(String token) async {
    try {
      return await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'הסיסמה חלשה מדי';
      case 'email-already-in-use':
        return 'האימייל כבר רשום במערכת';
      case 'user-not-found':
        return 'משתמש לא נמצא';
      case 'wrong-password':
        return 'סיסמה שגויה';
      case 'invalid-email':
        return 'אימייל לא תקין';
      default:
        return 'שגיאה: ${e.message}';
    }
  }
}

