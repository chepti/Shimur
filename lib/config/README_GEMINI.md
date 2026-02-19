# הגדרת Firebase AI Logic (Gemini)

## איך זה עובד

האפליקציה משתמשת ב-**Firebase AI Logic** – אין צורך במפתח API בקוד.
האימות והחיוב עוברים דרך חשבון ה-Firebase/Google של הפרויקט.

## הפעלה

1. היכנסי ל־[Firebase Console](https://console.firebase.google.com)
2. בחרי את הפרויקט
3. עברי ל־[Firebase AI Logic](https://console.firebase.google.com/project/_/ailogic)
4. לחצי **Get started**
5. בחרי **Gemini Developer API** (מומלץ להתחלה)
6. Firebase יאפשר את ה-API הנדרש – **אין צורך להדביק מפתח בקוד**

## הגבלת תקציב

1. **Firebase Console** → **Usage and billing** → **Billing**
2. או: **Google Cloud Console** → **Billing** → **Budgets & alerts**
3. צרי תקציב והגדרי התראות (50%, 90%, 100%)

**חשוב:** התקציב שולח התראות – לא עוצר אוטומטית את החיוב.

## מכסה באפליקציה

במסך **הגדרות** → **בינה מלאכותית** ניתן להגדיר מכסה חודשית (מספר בקשות).
ברירת מחדל: 50 בקשות לחודש.
