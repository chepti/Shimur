# שימור - אפליקציה למנהלי בתי ספר בחמ"ד

אפליקציית Flutter + Firebase למעקב אחרי מצב המורים ופעולות שימור.

## 📋 תוכן עניינים

- [התקנה ראשונית](#התקנה-ראשונית)
- [הגדרת Firebase](#הגדרת-firebase)
- [הרצת הפרויקט](#הרצת-הפרויקט)
- [מבנה הפרויקט](#מבנה-הפרויקט)
- [תכונות](#תכונות)

## 🚀 התקנה ראשונית

### 1. התקנת Flutter

ראה קובץ `SETUP.md` להוראות מפורטות.

**בקצרה:**
1. הורד את Flutter מ: https://flutter.dev/docs/get-started/install/windows
2. חלץ את הקובץ ZIP לתיקייה (למשל `C:\src\flutter`)
3. הוסף את Flutter ל-PATH
4. הפעל מחדש את PowerShell ובדוק:
   ```bash
   flutter doctor
   ```

### 2. הגדרת Firebase

ראה קובץ `FIREBASE_SETUP.md` להוראות מפורטות.

**בקצרה:**
1. צור פרויקט ב-Firebase Console
2. הפעל Authentication (Email/Password)
3. הפעל Firestore Database
4. הגדר Security Rules (ראה `firestore.rules`)
5. התקן FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
6. הגדר את Firebase בפרויקט:
   ```bash
   flutterfire configure
   ```

### 3. הרצת הפרויקט

```bash
flutter pub get
flutter run
```

## 📁 מבנה הפרויקט

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

## ✨ תכונות

### MVP (גרסה ראשונה):

✅ **מסך התחברות והרשמה**
- התחברות עם אימייל וסיסמה
- הרשמה עם סמל מוסד ושם בית ספר

✅ **מסך הצוות שלי**
- רשימת כל המורים בבית הספר
- כרטיס מורה עם: שם, סטטוס (רמזור), וותק, פעולות
- הוספת מורה חדש

✅ **מסך פרטי מורה**
- כל הפרטים הבסיסיים
- רשימת פעולות שבוצעו
- הוספת פעולה חדשה
- תזכורת לפעולה מתוכננת

✅ **מסך הוספת פעולה**
- סוג פעולה (רשימה נפתחת)
- תאריך ביצוע (עברי + לועזי)
- הערות
- סטטוס ביצוע

✅ **מסך המשימות שלי**
- רשימת כל הפעולות המתוכננות
- מיון לפי תאריך
- סינון: שבוע הקרוב / הכל
- סימון כבוצע

✅ **מסך הגדרות**
- התנתקות

## 🎨 עיצוב

- צבע ראשי: תכלת חמ"ד `#11a0db`
- צבע משני: `#f36f21`
- צבעי רמזור:
  - ירוק: `#4CAF50` (יציב)
  - צהוב: `#FFC107` (מעקב)
  - אדום: `#F44336` (סיכון)

## 📝 הערות

- זהו MVP - גרסה ראשונה בסיסית
- הלוגו: https://imgur.com/9xCiffu (להוסיף ידנית)
- תאריך עברי - כרגע בסיסי, ניתן לשפר עם ספרייה מתאימה

## 🔒 אבטחה

- כל מנהל רואה ומעדכן רק את בית הספר שלו
- Security Rules מוגדרים ב-`firestore.rules`
- Authentication דרך Firebase

## 📚 קבצי עזרה

- `SETUP.md` - הוראות התקנה מפורטות
- `FIREBASE_SETUP.md` - הוראות הגדרת Firebase מפורטות
- `firestore.rules` - כללי אבטחה ל-Firestore

