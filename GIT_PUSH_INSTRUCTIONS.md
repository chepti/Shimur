# הוראות דחיפה ל-GitHub

בגלל בעיה טכנית עם PowerShell, נא להריץ את הפקודות הבאות ידנית:

## פתחי PowerShell והרצי:

```powershell
cd t:\CURSOR2\Shimur

git status

git add .

git commit -m "Add dashboard screen, fix dropdown error, add deployment configuration"

git push origin main
```

---

## או השתמשי בסקריפט שיצרתי:

```powershell
cd t:\CURSOR2\Shimur
powershell -ExecutionPolicy Bypass -File push_to_github.ps1
```

---

## אם יש שגיאה של authentication:

1. ודאי שהתחברת ל-GitHub:
   ```powershell
   git config --global user.email "chepti@gmail.com"
   git config --global user.name "chepti"
   ```

2. אם צריך להתחבר מחדש:
   ```powershell
   git credential-manager-core configure
   ```

---

## קבצים חדשים שנוספו:

- `lib/screens/dashboard_screen.dart` - מסך דשבורד חדש
- `DEPLOYMENT.md` - הוראות פרסום
- `.firebaserc` - הגדרות Firebase
- `firebase.json` - עודכן עם הגדרות hosting
- `push_to_github.ps1` - סקריפט לדחיפה

## קבצים שעודכנו:

- `lib/main.dart` - הוספת דשבורד לניווט
- `lib/screens/add_action_screen.dart` - תיקון שגיאת dropdown
