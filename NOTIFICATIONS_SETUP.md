# 🔔 הגדרת התראות Push

האפליקציה תומכת בהתראות Push אמיתיות – ב־**Web (PWA)** וב־**Android**.

## מה כבר מוגדר

- ✅ `firebase_messaging` ב־Flutter
- ✅ `firebase-messaging-sw.js` ל־Web
- ✅ שמירת טוקנים ב־Firestore
- ✅ Cloud Function מתוזמנת (כל 15 דקות)
- ✅ ערוץ התראות ל־Android

## שלב חובה – Web Push (VAPID Key)

כדי שהתראות יעבדו ב־**Web** (shimur.web.app), צריך ליצור מפתח VAPID:

1. לכו ל־[Firebase Console](https://console.firebase.google.com/) → פרויקט **shimur**
2. **Settings** (⚙️) → **Project settings** → לשונית **Cloud Messaging**
3. גללו ל־**Web configuration** → **Web Push certificates**
4. לחצו **Generate key pair** (או **Import** אם יש לכם כבר)
5. העתיקו את ה־**Public key** (מחרוזת ארוכה)

### הוספת המפתח לקוד

פתחו את `lib/services/notification_service.dart` והחליפו את השורה:

```dart
static const String _vapidKeyWeb = 'REPLACE_WITH_YOUR_VAPID_KEY';
```

ב־:

```dart
static const String _vapidKeyWeb = 'המפתח_שהעתקתם';
```

### הערה

- **Android** – עובד מיד, ללא צעד נוסף.
- **Web** – דורש את מפתח ה־VAPID. בלי המפתח, ההתראות לא יעבדו בדפדפן.

## פרסום Cloud Functions

פונקציית ההתראות המתוזמנת צריכה להיות מפורסמת:

```powershell
cd t:\CURSOR2\Shimur
firebase deploy --only functions
```

הפונקציה `sendScheduledNotifications` תרוץ אוטומטית כל 15 דקות (אזור זמן: ישראל).

## זמני ההתראה

- **תחילת שבוע** – לפי `notificationStartWeekWeekday`, `Hour`, `Minute` בהגדרות
- **סוף שבוע** – לפי `notificationEndWeekWeekday`, `Hour`, `Minute` בהגדרות

המשתמש יכול לשנות את הזמנים במסך **הגדרות**.

## בדיקה

1. **Web**: פתחו את shimur.web.app, התחברו, והרשאו התראות כשהדפדפן שואל.
2. **Android**: התקינו את ה־APK והתחברו.
3. הגדירו שעה קרובה (למשל 5 דקות מעכשיו) בהגדרות.
4. חכו – ההתראה תופיע בתוך 15 דקות.

## פתרון בעיות – "לא ניתן להפעיל"

### Web (דפדפן)

1. **ההרשאה נדחתה** – לחצי על אייקון המנעול/מידע בשורת הכתובת → **התראות** → **אפשר**
2. **הדפדפן חוסם** – Chrome: Settings → Privacy → Site settings → Notifications → הוסיפי את shimur.web.app ל"Allowed"
3. **רענני את הדף** – Ctrl+F5 (ריענון מלא) ונסי שוב
4. **מצב פרטי/אינקוגניטו** – חלק מהדפדפנים מגבילים התראות; נסי בחלון רגיל
5. **ודאי HTTPS** – התראות עובדות רק ב־HTTPS (shimur.web.app תקין)

### Android

- ודאי שההתראות לא חסומות בהגדרות האפליקציה: Settings → Apps → shimur → Notifications
