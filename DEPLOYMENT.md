# 🚀 הוראות פרסום האפליקציה לאינטרנט

## 📋 דרישות מוקדמות

1. **Node.js** - אם אין לך, הורידי מ: https://nodejs.org/ (גרסה LTS)
2. **Firebase CLI** - נותן לך לפרסם ישירות מהטרמינל

---

## שלב 1: התקנת Firebase CLI

פתחי PowerShell והרצי:

```powershell
npm install -g firebase-tools
```

אם זה לא עובד, נסי:
```powershell
npm install -g firebase-tools --force
```

**אימות ההתקנה:**
```powershell
firebase --version
```

אם תראי מספר גרסה, הכל תקין! ✅

---

## שלב 2: התחברות ל-Firebase

```powershell
firebase login
```

זה יפתח דפדפן שבו תתחברי עם חשבון ה-Google שלך (chepti@gmail.com).

**אימות ההתחברות:**
```powershell
firebase projects:list
```

אם תראי את הפרויקט "shimur", הכל תקין! ✅

---

## שלב 3: בניית האפליקציה ל-Web

```powershell
cd t:\CURSOR2\Shimur
flutter build web --release
```

זה יבנה את האפליקציה לתיקייה `build/web/`.

**⏱ זמן הבנייה:** כ-2-5 דקות (בפעם הראשונה)

---

## שלב 4: פרסום ל-Firebase Hosting

```powershell
firebase deploy --only hosting
```

**מה זה עושה?**
- מעלה את הקבצים מ-`build/web/` ל-Firebase
- מפרסם את האפליקציה לאינטרנט
- נותן לך קישור ציבורי

**⏱ זמן הפרסום:** כ-1-2 דקות

---

## שלב 5: קבלת הקישור 🎉

לאחר הפרסום, תקבלי קישור כמו:

```
https://shimur.web.app
```

או

```
https://shimur.firebaseapp.com
```

**זה הקישור שתוכלי לשתף עם אחרים!** 🎊

כל מי שיש לו את הקישור יכול:
- להיכנס לאפליקציה
- להירשם/להתחבר
- להשתמש באפליקציה מכל מכשיר (טלפון, מחשב, טאבלט)

---

## 🔄 עדכונים עתידיים

### אפשרות 1: סקריפט אחד (GitHub + Web)
לעדכון GitHub **וגם** גרסת ה-Web בפעולה אחת:

- **ממשק גרפי:** לחיצה כפולה על `deploy_web.bat` בתיקיית הפרויקט
- **מ-PowerShell:** `.\deploy_web.ps1` מתוך `t:\CURSOR2\Shimur`

הסקריפט מבצע: commit + push ל-GitHub, בניית web, ופריסה ל-Firebase Hosting.

### אפשרות 2: פקודות ידניות
כשאת רוצה רק לעדכן את האתר (בלי Git):

```powershell
# 1. בנייה מחדש
flutter build web --release

# 2. פרסום
firebase deploy --only hosting
```

**⏱ זמן עדכון:** כ-3-5 דקות

---

## 🔒 אבטחה

האפליקציה מוגנת:
- ✅ רק משתמשים מחוברים יכולים לראות/לערוך נתונים
- ✅ כל משתמש רואה רק את הנתונים שלו (לפי userId)
- ✅ HTTPS אוטומטי (הקישור מתחיל ב-https)
- ✅ כללי אבטחה מוגדרים ב-Firestore

**לבדיקת כללי האבטחה:**
1. לכי ל-Firebase Console: https://console.firebase.google.com/
2. בחרי את הפרויקט "shimur"
3. Firestore Database → Rules

---

## 🌐 תחום מותאם אישית (אופציונלי)

אם תרצי תחום משלך (למשל: `shimur.co.il`):

1. לכי ל-Firebase Console → Hosting
2. לחצי על "Add custom domain"
3. עקבי אחר ההוראות

---

## ❓ פתרון בעיות

### שגיאה: "firebase: command not found"
**פתרון:** ודאי ש-Node.js מותקן ו-Firebase CLI הותקן נכון

### שגיאה: "Permission denied"
**פתרון:** ודאי שהתחברת עם `firebase login`

### שגיאה: "Project not found"
**פתרון:** ודאי שהפרויקט "shimur" קיים ב-Firebase Console

### האפליקציה לא נטענת אחרי הפרסום
**פתרון:** 
1. בדקי את הקונסול בדפדפן (F12) לשגיאות
2. ודאי ש-Firebase מוגדר נכון ב-`firebase_options.dart`
3. נסי לרענן את הדף (Ctrl+F5)

### לא רואים את העדכונים האחרונים ב-Web (גרסה ישנה נטענת)
זה קורה כי הדפדפן שומר גרסה ישנה ב-cache ו־Service Worker.

**צעד 1 – וודאי שהעלית גרסה חדשה:**
- הרצי **פעם אחת** את `deploy_web.bat` (לחיצה כפולה) או את הפקודות:
  - `flutter build web --release`
  - `firebase deploy --only hosting`
- חכי עד שהפקודות מסתיימות בהצלחה.

**צעד 2 – ריענון מלא בדפדפן (חובה אחרי כל deploy):**
- **Chrome / Edge:** פתחי את https://shimur.web.app → `Ctrl+Shift+R` (או `Ctrl+F5`).
- **או:** F12 → לשונית Application (או Storage) → משמאל "Storage" → "Clear site data" → רענני את הדף.
- **טלפון:** סגרי את הטאב לגמרי, פתחי מחדש את הקישור (או נקי נתונים של הדפדפן לאתר).

אחרי "Clear site data" או ריענון קשיח – תיטען הגרסה העדכנית מהשרת.

---

## 📱 גישה מהטלפון

האפליקציה עובדת גם מהטלפון! פשוט פתחי את הקישור בדפדפן בטלפון.

**טיפ:** אפשר להוסיף את האפליקציה למסך הבית (Add to Home Screen) כדי שתראה כמו אפליקציה רגילה.

---

## 🎯 סיכום - צעדים מהירים

```powershell
# 1. התקנה (פעם אחת)
npm install -g firebase-tools

# 2. התחברות (פעם אחת)
firebase login

# 3. בנייה ופרסום (בכל עדכון)
flutter build web --release
firebase deploy --only hosting
```

**זה הכל!** 🎉
