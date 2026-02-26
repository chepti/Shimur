# פריסה ל-WEB (Production)

## פקודות לפריסה

```bash
# 1. בניית האפליקציה ל-WEB
flutter build web

# 2. העתקת form.html לתיקיית הבנייה (אם נדרש)
# ה-form.html כבר ב-web/ ומשוכפל אוטומטית בבנייה

# 3. פריסה ל-Firebase Hosting
firebase deploy

# או רק Hosting (ללא Firestore, Storage, Functions):
firebase deploy --only hosting
```

## פריסה מלאה (כל השירותים)

```bash
flutter build web
firebase deploy
```

## הערות

- תיקיית ה-build: `build/web`
- ה-`form.html` (טופס השאלון) נמצא ב-`web/form.html` ומשוכפל אוטומטית ל-`build/web/form.html` בעת `flutter build web`
- וודא ש-Firebase CLI מותקן: `npm install -g firebase-tools`
- התחברות: `firebase login`
