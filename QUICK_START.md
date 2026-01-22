# 🚀 סיכום מהיר - מה צריך כדי שהכל יעבוד

## ✅ מה שכבר יש לך:
- ✅ **Flutter SDK** - מותקן ב-`T:\CURSOR2\Programs\flutter`
- ✅ **Android Studio** - מותקן
- ✅ **Android SDK** - ב-`T:\CURSOR2\Programs\AndroidStudioSDK`
- ✅ **קוד הפרויקט** - כל הקבצים בתיקייה

## ⚠️ מה שצריך לעשות:

### 1. **תיקון PATH** (אם Flutter לא מזוהה)
```powershell
$env:PATH += ";T:\CURSOR2\Programs\flutter\bin"
```
או הפעל מחדש את VS Code.

### 2. **הגדרת Android SDK ב-Flutter**
```powershell
flutter config --android-sdk "T:\CURSOR2\Programs\AndroidStudioSDK"
```

### 3. **התקנת cmdline-tools** (חסר!)
- פתח **Android Studio**
- **Settings** → **Appearance & Behavior** → **System Settings** → **Android SDK**
- טאב **SDK Tools**
- סמן **Android SDK Command-line Tools (latest)**
- **Apply** → **OK**

### 4. **התקנת תלויות**
```powershell
flutter pub get
```

### 5. **הגדרת Firebase**
```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```
- בחר פרויקט `shimur`
- בחר **Android**

### 6. **העתקת google-services.json**
```
google-services.json → android/app/google-services.json
```
(אחרי שרץ `flutter create .`)

### 7. **עדכון main.dart**
אחרי ש-`firebase_options.dart` נוצר:
- הוסף: `import 'firebase_options.dart';`
- שנה ל: `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`

## 🎯 סדר פעולות מומלץ:

1. ✅ תיקון PATH (אם צריך)
2. ✅ הגדרת Android SDK
3. ⏳ התקנת cmdline-tools (דרך Android Studio)
4. ⏳ `flutter create .` (אם אין תיקיית android/)
5. ⏳ `flutter pub get`
6. ⏳ העתקת google-services.json
7. ⏳ `flutterfire configure`
8. ⏳ עדכון main.dart
9. ⏳ `flutter run`

## 🔍 בדיקות:

```powershell
flutter doctor          # בדיקת כל המערכת
flutter --version       # בדיקת גרסת Flutter
flutter devices         # רשימת מכשירים זמינים
```

## 📝 הערות:

- **hebrew_date** - החבילה לא קיימת, הוסרה מ-pubspec.yaml (הקוד משתמש בפונקציה פשוטה)
- **Visual Studio** - לא קריטי אם מפתחים רק ל-Android
- **cmdline-tools** - **חובה!** בלי זה Flutter לא יכול לבנות לאנדרואיד
