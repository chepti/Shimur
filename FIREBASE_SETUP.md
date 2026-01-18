# הוראות הגדרת Firebase

## שלב 1: יצירת פרויקט Firebase

1. לך ל: https://console.firebase.google.com/
2. לחץ "הוסף פרויקט" (Add project)
3. הזן שם: `shimur` (או שם אחר)
4. המשך עם ההגדרות הבסיסיות
5. לחץ "צור פרויקט" (Create project)

## שלב 2: הגדרת Authentication

1. בתפריט השמאלי, לחץ על **Authentication**
2. לחץ **Get Started**
3. לחץ על **Email/Password** (הטאב הראשון)
4. הפעל את המתג **Email/Password**
5. לחץ **שמור** (Save)

## שלב 3: הגדרת Firestore Database

1. בתפריט השמאלי, לחץ על **Firestore Database**
2. לחץ **Create database**
3. בחר **Start in test mode** (לעת עתה, לבדיקות)
4. בחר מיקום (location) - למשל: `us-central1`
5. לחץ **Enable**

## שלב 4: הגדרת Security Rules

1. בלשונית **Rules** ב-Firestore
2. העתק את התוכן מ-`firestore.rules` (בתיקיית הפרויקט)
3. הדבק בחלון ה-Rules
4. לחץ **Publish**

**חשוב**: כללי האבטחה הבסיסיים מאפשרים למנהל לראות ולעדכן רק את בית הספר שלו (לפי userId).

## שלב 5: הוספת אפליקציות (Android/iOS)

### Android:

1. בתפריט השמאלי, לחץ על האייקון **⚙️** (Settings) → **Project settings**
2. גלול למטה ל-**Your apps**
3. לחץ על האייקון **Android** (או **Add app** → **Android**)
4. הזן:
   - **Package name**: `com.example.shimur` (או שם אחר)
   - **App nickname**: `Shimur Android`
5. לחץ **Register app**
6. הורד את `google-services.json`
7. העתק את הקובץ ל: `android/app/google-services.json`

### iOS (אם צריך):

1. לחץ **Add app** → **iOS**
2. הזן:
   - **Bundle ID**: `com.example.shimur` (או שם אחר)
   - **App nickname**: `Shimur iOS`
3. לחץ **Register app**
4. הורד את `GoogleService-Info.plist`
5. העתק את הקובץ ל: `ios/Runner/GoogleService-Info.plist`

## שלב 6: התקנת FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

## שלב 7: הגדרת Firebase בפרויקט Flutter

```bash
flutterfire configure
```

בחר:
- את הפרויקט שיצרת (`shimur`)
- פלטפורמות: **Android** (חובה), **iOS** (אם צריך)

זה יוצר את `lib/firebase_options.dart` אוטומטית.

## שלב 8: בדיקה

הרץ:
```bash
flutter pub get
flutter run
```

אם הכל עובד, תראה את מסך ההתחברות!

## פתרון בעיות

### שגיאת "firebase_options.dart not found":
- ודא שרצת `flutterfire configure`
- ודא שהקובץ נוצר ב-`lib/firebase_options.dart`

### שגיאת "PlatformException: [core/no-app]":
- ודא ש-`google-services.json` קיים ב-`android/app/`
- ודא ש-`GoogleService-Info.plist` קיים ב-`ios/Runner/` (אם iOS)

### שגיאת Authentication:
- ודא ש-Authentication מופעל ב-Firebase Console
- ודא ש-Email/Password מופעל

### שגיאת Firestore:
- ודא ש-Firestore מופעל
- בדוק את Security Rules

## Security Rules - הסבר

הכללים ב-`firestore.rules` מבטיחים ש:
- כל מנהל רואה ומעדכן רק את בית הספר שלו
- `schoolId` = `userId` (ב-MVP)
- אין גישה לנתונים של מנהלים אחרים

**חשוב**: לפני הפצה, שפר את כללי האבטחה לפי הצרכים!

