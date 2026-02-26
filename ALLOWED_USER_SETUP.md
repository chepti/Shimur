# התחברות כאדמין כמשתמש אחר (לפי UID)

## כפתור "Login as..." במסך ההתחברות

בתחתית מסך ההתחברות יש כפתור קטן **"Login as..."**. לחיצה פותחת חלון להדבקת UID והתחברות כמשתמש אחר. לאדמין בלבד.

## הגדרה חד־פעמית

### 1. סוד ב-Firebase (הסוד לא נשמר ב-Git)

```bash
firebase functions:config:set admin.login_secret="הסוד-שלך"
firebase deploy --only functions
```

### 2. בנייה עם הסוד

```bash
flutter build web --dart-define=ADMIN_LOGIN_SECRET=הסוד-שלך
firebase deploy --only hosting
```

## שימוש

1. פתחי את מסך ההתחברות
2. גללי למטה ולחצי על "Login as..."
3. הדביקי את ה-UID (מ-Firebase Console → Authentication → Users)
4. לחצי "התחבר"

---

## הגבלה למשתמש יחיד (אופציונלי)

אם רוצים לאפשר רק למשתמש מסוים – עדכני את `lib/config/allowed_users.dart`:

```dart
const List<String>? allowedUids = ['ה-UID-המורשה'];
```

רק המשתמש עם ה-UID הזה יוכל להיכנס (גם בהתחברות רגילה וגם דרך "התחבר כ...").
