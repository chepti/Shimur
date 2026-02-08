# 🚀 הוראות פרסום האפליקציה לאינטרנט

---

## 🌐 פריסה בלי Flutter מקומי (מחשב בלי Flutter / Android Studio)

**כן, אפשר.** אם את במחשב שאין בו Flutter או Android Studio, אפשר לעדכן את https://shimur.web.app/ כך:

1. **דחיפה ל-GitHub** – אחרי ששינית קוד, תבצעי `git push` ל־repository (לענף `main`).
2. **GitHub Actions** – בענן של GitHub ירוץ workflow שיבנה את האפליקציה (Flutter web) ויעלה אותה ל-Firebase Hosting. אחרי כמה דקות האתר יתעדכן.

### הגדרה חד־פעמית (פעם אחת)

צריך להוסיף ל-GitHub **סוד** בשם `FIREBASE_TOKEN`, כדי ש-GitHub יוכל לפרסם ל-Firebase בשמך.

**איך משיגים את הטוקן?**

- צריך להריץ **פעם אחת** את הפקודה `firebase login:ci` במחשב שיש בו **Node.js** (לא חובה Flutter).  
  אם יש לך Node במחשב הנוכחי – התקיני רק את Firebase CLI והרצי:

```powershell
npm install -g firebase-tools
firebase login:ci
```

- הפקודה תפתח דפדפן להתחברות עם חשבון Google (chepti@gmail.com). אחרי ההתחברות יופיע **טוקן ארוך** בטרמינל.  
- **העתיקי את הטוקן** (כולו, בלי רווחים מיותרים).

**איפה שמים את הטוקן ב-GitHub?**

1. פתחי את ה-repository ב-GitHub (chepti/shimur או השם האמיתי של הפרויקט).
2. **Settings** → **Secrets and variables** → **Actions**.
3. **New repository secret**.
4. **Name:** `FIREBASE_TOKEN`  
   **Value:** הדבקי את הטוקן שהעתקת.
5. **Add secret**.

מעכשיו, בכל **דחיפה ל־main** (או הרצה ידנית של ה-workflow "Deploy Web to Firebase Hosting"), GitHub יבנה את האפליקציה ויעלה אותה ל־https://shimur.web.app/.

**הרצה ידנית:** ב-GitHub: לשונית **Actions** → בחרי "Deploy Web to Firebase Hosting" → **Run workflow**.

---

## 📋 דרישות מוקדמות (לפריסה מהמחשב עם Flutter)

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

---

# 📱 פריסת האפליקציה לאנדרואיד

אחרי שפרסתם ל־Web (דמוי-אתר), אפשר גם להפוך את האפליקציה לאפליקציית אנדרואיד – להתקנה ישירה (APK) או לפרסום ב־Google Play.

## דרישות מוקדמות לאנדרואיד

1. **Flutter** – מותקן ועובד (כמו ב־SETUP.md).
2. **Android SDK** – דרך Android Studio:  
   [הורדת Android Studio](https://developer.android.com/studio) → התקנה → SDK Manager → וידוא ש־Android SDK מותקן.
3. **Firebase לאנדרואיד** – כבר מוגדר (יש `google-services` ב־`android/app/build.gradle.kts`).  
   אם עדיין לא הרצתם: `flutterfire configure` ובחרו גם Android.

בדיקה:

```powershell
flutter doctor
```

וודאו שיש סימון ל־Android toolchain (או תקנו לפי ההודעות).

---

## אפשרות א': בניית APK – להתקנה ישירה (בלי חנות)

מתאים לבדיקות, לחלוקה פנימית, או להתקנה ידנית במכשירים.

### שלב 1: בניית APK

```powershell
cd c:\CURSOR\SHIMUR
flutter build apk --release
```

הקובץ ייווצר ב:  
`build\app\outputs\flutter-apk\app-release.apk`

### שלב 2: התקנה במכשיר

- **מחובר USB:**  
  ```powershell
  flutter install --release
  ```
- **ידנית:** העתקו את `app-release.apk` לטלפון (דוא"ל, Google Drive, וכו') ופתחו את הקובץ במכשיר. ייתכן שיהיה צורך לאפשר "התקנה ממקורות לא ידועים" בהגדרות.

**הערה:** ב־release כרגע משתמשים ב־debug signing (ב־build.gradle.kts). זה מספיק לבדיקות; לפרסום ב־Play Store צריך חתימה ייעודית (ראה למטה).

---

## אפשרות ב': פרסום ב־Google Play Store

### שלב 1: יצירת Keystore (מפתח חתימה) – פעם אחת

זה המפתח שחותם את האפליקציה. **שמרו את הקובץ והסיסמה במקום בטוח – אי אפשר לשחזר.**

ב־PowerShell (או CMD):

```powershell
cd c:\CURSOR\SHIMUR\android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

ממלאים: סיסמה ל־keystore, פרטים (שם, ארגון, וכו').  
נוצר קובץ `upload-keystore.jks` – **אל תשתפו ולא תעלו ל־Git.**

### שלב 2: הגדרת חתימה ב־Flutter/Android

1. צרו קובץ `android/key.properties` (הקובץ לא נשמר ב־Git):

```properties
storePassword=הסיסמה_שהזנת
keyPassword=הסיסמה_שהזנת
keyAlias=upload
storeFile=upload-keystore.jks
```

2. **הפרויקט כבר מוגדר לחתימה:** ב־`android/app/build.gradle.kts` יש קריאה ל־`key.properties`. אם הקובץ קיים – ה־release ייחתם עם ה־keystore; אם לא – ייעשה שימוש ב־debug (לבדיקות).

### שלב 3: בניית App Bundle (AAB) ל־Play

Google Play דורש קובץ **Android App Bundle** (.aab), לא רק APK:

```powershell
cd c:\CURSOR\SHIMUR
flutter build appbundle --release
```

הקובץ:  
`build\app\outputs\bundle\release\app-release.aab`

### שלב 4: חשבון מפתח ב־Google Play

1. היכנסו ל־[Google Play Console](https://play.google.com/console).
2. שילמו דמי רישום חד־פעמיים (כ־25$).
3. צרו "אפליקציה חדשה", מלאו שם ופרטים בסיסיים.

### שלב 5: העלאת האפליקציה

1. ב־Play Console: **Production** (או **Testing** → Internal/Closed testing).
2. **Create new release** → העלו את `app-release.aab`.
3. מלאו **Store listing**: תיאור, צילומי מסך, אייקון, מדיניות פרטיות (אם נדרש).
4. מלאו **Content rating**, **Target audience**, **News app** (אם רלוונטי) וכו'.
5. אחרי שכל החובות ירוקים – **Submit for review**.

האישור יכול לקחת כמה שעות עד כמה ימים.

---

## סיכום קצר – אנדרואיד

| מטרה | פקודה / פעולה |
|------|----------------|
| **APK לבדיקות / התקנה ישירה** | `flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk` |
| **התקנה ממחשב עם USB** | `flutter install --release` |
| **הכנה ל־Play Store** | יצירת keystore, הגדרת `key.properties` ו־signing ב־build.gradle, אז `flutter build appbundle --release` |
| **פרסום ב־Play** | העלאת ה־.aab ב־Play Console + מילוי Store listing ואישורים |

`key.properties` ו־`*.jks` כבר ממוקמים ב־`.gitignore` של `android/`, כך שלא יעלו ל־Git.
