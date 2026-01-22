# צעדים לביצוע לאחר התקנת Flutter

## ✅ בדיקות ראשוניות

### 1. תיקון PATH (אם Flutter לא מזוהה)

**אם הפקודה `flutter` לא עובדת ב-PowerShell:**

#### אופציה א': הפעל מחדש את VS Code
- סגור את VS Code לחלוטין
- פתח מחדש
- זה אמור לטעון את משתני הסביבה המעודכנים

#### אופציה ב': הרץ את הסקריפט
```powershell
.\fix_flutter_path.ps1
```
זה יוסיף את Flutter ל-PATH ויבדוק שהכל עובד.

#### אופציה ג': הוסף ידנית לסשן הנוכחי
```powershell
$env:PATH += ";T:\CURSOR2\Programs\flutter\bin"
```

### 2. בדיקת התקנת Flutter
```bash
flutter doctor
```
- ודא שכל הרכיבים מותקנים (Android SDK, VS Code extensions וכו')
- אם יש אזהרות, עקוב אחרי ההוראות

### 3. בדיקת נתיב Flutter
```bash
flutter --version
```
- ודא שהפקודה עובדת
- אם לא עובד, ראה שלב 1

## 🔧 הגדרת הפרויקט

### 4. יצירת מבנה Flutter (אם חסר)
```bash
flutter create .
```
- זה יוצר את התיקיות `android/`, `ios/` וכו'

### 5. העתקת google-services.json
אחרי שיצרת את המבנה, העתק את הקובץ:
```
google-services.json → android/app/google-services.json
```

### 6. התקנת תלויות
```bash
flutter pub get
```
- זה מוריד את כל החבילות מ-`pubspec.yaml`

### 7. הגדרת Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
- בחר את הפרויקט `shimur`
- בחר פלטפורמות: **Android** (חובה), **iOS** (אם צריך)
- זה יוצר את `lib/firebase_options.dart` אוטומטית

### 8. עדכון main.dart
אחרי ש-`firebase_options.dart` נוצר, עדכן את `lib/main.dart`:
- הוסף: `import 'firebase_options.dart';`
- שנה את השורה ל: `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`

## 🚀 הרצת האפליקציה

### 9. בדיקת מכשירים זמינים
```bash
flutter devices
```
- רשימת מכשירים/אמולטורים זמינים

### 10. הרצת האפליקציה
```bash
flutter run
```
- או בחר מכשיר ספציפי: `flutter run -d <device-id>`

## 📝 הערות חשובות

- **firebase_options.dart** - הקובץ נוצר אוטומטית על ידי `flutterfire configure`
- **google-services.json** - צריך להיות ב-`android/app/`
- **Security Rules** - ודא שהעתקת את `firestore.rules` ל-Firebase Console

## 🔍 פתרון בעיות

### Flutter לא מזוהה ב-PowerShell:
1. **הפעל מחדש את VS Code** (זה הפתרון הכי פשוט!)
2. או הרץ: `.\fix_flutter_path.ps1`
3. או הוסף ידנית: `$env:PATH += ";T:\CURSOR2\Programs\flutter\bin"`

### שגיאות אחרות:
1. בדוק את `flutter doctor`
2. בדוק שהכל מותקן נכון
3. הפעל מחדש את VS Code ואת הטרמינל
4. בדוק את הלוגים בטרמינל

### Android SDK לא מזוהה:
- פתח את Android Studio
- Settings → Appearance & Behavior → System Settings → Android SDK
- העתק את הנתיב (למשל: `C:\Users\YourName\AppData\Local\Android\Sdk`)
- הרץ: `flutter config --android-sdk <נתיב>`
