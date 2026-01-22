# הוראות התקנה והגדרה - אפליקציית שימור

## שלב 0: יצירת פרויקט Flutter (אם צריך)

אם התיקייה לא מכילה פרויקט Flutter מלא (חסרים תיקיות `android/`, `ios/` וכו'), הרץ:

```bash
flutter create .
```

זה יוצר את המבנה הבסיסי של Flutter (Android, iOS, וכו').

## שלב 1: התקנת Flutter

### התקנה דרך VS Code (מומלץ):

1. **התקן את Flutter Extension:**
   - פתח את VS Code
   - לחץ על Extensions (או Ctrl+Shift+X)
   - חפש "Flutter" והתקן את ה-extension הרשמי של Flutter
   - זה יתקין גם את ה-Dart extension אוטומטית

2. **התקן את Flutter SDK דרך VS Code:**
   - פתח את Command Palette (Ctrl+Shift+P)
   - הקלד `flutter` ובחר **Flutter: New Project**
   - VS Code יבקש את מיקום ה-Flutter SDK - בחר **Download SDK**
   - בחר תיקייה להתקנה (למשל `T:\CURSOR2\Programs\flutter`)
   - לחץ **Clone Flutter** (זה יוריד את Flutter אוטומטית)
   - לחץ **Add SDK to PATH** (VS Code יוסיף את Flutter ל-PATH אוטומטית)
   
   **חשוב**: לא צריך להוסיף משתני סביבה ידנית! VS Code עושה את זה אוטומטית.

3. **הפעל מחדש את VS Code ואת כל חלונות הטרמינל**

4. **בדוק שההתקנה הצליחה:**
   ```bash
   flutter doctor
   ```
   - אם יש שגיאות, עקוב אחרי ההוראות שמופיעות
   - **הערה**: אם יש אזהרה על Android Studio, זה בסדר אם אתה מפתח רק ל-web או iOS

### התקנת Android Studio (לפיתוח Android):

1. הורד מ: https://developer.android.com/studio
2. התקן את Android Studio
3. פתח את Android Studio → More Actions → SDK Manager
4. ודא ש-Android SDK מותקן
5. פתח את Android Studio → More Actions → Virtual Device Manager
6. צור אמולטור (אם אין)

## שלב 2: הגדרת Firebase

### 1. צור פרויקט Firebase:

1. לך ל: https://console.firebase.google.com/
2. לחץ "הוסף פרויקט"
3. הזן שם לפרויקט (למשל: "shimur")
4. המשך עם ההגדרות (Google Analytics - אופציונלי)
5. לחץ "צור פרויקט"

### 2. הוסף Authentication:

1. בפרויקט Firebase, לחץ על "Authentication" בתפריט השמאלי
2. לחץ "Get Started"
3. לחץ על "Email/Password"
4. הפעל "Email/Password" ולחץ "שמור"

### 3. הוסף Firestore Database:

1. לחץ על "Firestore Database" בתפריט השמאלי
2. לחץ "Create database"
3. בחר "Start in test mode" (לעת עתה)
4. בחר מיקום (למשל: us-central1)
5. לחץ "Enable"

### 4. הגדר Security Rules:

1. בלשונית "Rules" ב-Firestore
2. העתק את התוכן מ-`firestore.rules` והדבק בחלון
3. לחץ "Publish"

### 5. התקן FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

### 6. הגדר את Firebase בפרויקט:

```bash
flutterfire configure
```

בחר:
- את הפרויקט שיצרת
- פלטפורמות: Android (חובה), iOS (אם צריך)

זה יוצר את `lib/firebase_options.dart` אוטומטית.

## שלב 3: הרצת הפרויקט

### התקן תלויות:

```bash
flutter pub get
```

### הרץ את האפליקציה:

```bash
flutter run
```

או:
- פתח את Android Studio
- פתח את הפרויקט
- לחץ על כפתור "Run"

## מבנה הפרויקט

```
lib/
├── main.dart                 # נקודת כניסה
├── models/                   # מודלים של נתונים
│   ├── teacher.dart
│   ├── action.dart
│   └── school.dart
├── services/                 # שירותים
│   ├── auth_service.dart
│   └── firestore_service.dart
├── screens/                  # מסכים
│   ├── login_screen.dart
│   ├── teachers_list_screen.dart
│   ├── add_teacher_screen.dart
│   ├── teacher_details_screen.dart
│   ├── add_action_screen.dart
│   ├── tasks_screen.dart
│   └── settings_screen.dart
└── widgets/                  # ווידג'טים
    ├── status_indicator.dart
    └── teacher_card.dart
```

## פתרון בעיות נפוצות

### שגיאת "firebase_options.dart not found":
- הרץ `flutterfire configure` שוב

### שגיאת "PlatformException":
- ודא שהגדרת את Firebase נכון
- ודא ש-`google-services.json` קיים ב-`android/app/`

### האפליקציה לא מתחברת ל-Firebase:
- ודא ש-Authentication מופעל ב-Firebase Console
- ודא ש-Firestore מופעל
- בדוק את Security Rules

## צעדים הבאים

1. הוסף לוגו אמיתי (החלף את האייקון ב-login_screen.dart)
2. שפר את תאריך עברי (הוסף ספרייה מתאימה)
3. הוסף מסך עריכה למורה
4. הוסף ספירת פעולות בכרטיס מורה
5. הוסף אנימציות ומעברים חלקים

## תמיכה

אם יש בעיות, בדוק:
- `flutter doctor` - לבדיקת סביבת הפיתוח
- לוגים בקונסול Firebase
- לוגים ב-Flutter (בטרמינל)

