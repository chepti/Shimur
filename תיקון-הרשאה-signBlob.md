# תיקון שגיאת "Permission iam.serviceAccounts.signBlob denied"

## צעדים (כ־2 דקות)

### 1. פתיחת IAM
פתחי בדפדפן:
**https://console.cloud.google.com/iam-admin/iam?project=shimur**

### 2. מציאת החשבון
בטבלה, חפשי אחד מהחשבונות הבאים:
- `shimur@appspot.gserviceaccount.com` (App Engine default)
- או חשבון שמסתיים ב־`@developer.gserviceaccount.com` (Compute Engine)

### 3. עריכה
לחצי על **עיפרון** (Edit) ליד החשבון.

### 4. הוספת תפקיד
1. לחצי **ADD ANOTHER ROLE**
2. חפשי: **Service Account Token Creator**
3. בחרי את התפקיד
4. לחצי **Save**

### 5. המתנה
חכי כ־1–2 דקות ונסי שוב את "Login as...".

---

**אם לא מוצאים את החשבון:** לחצי **GRANT ACCESS**, בשדה Principals הזיני `shimur@appspot.gserviceaccount.com`, ב־Role בחרי **Service Account Token Creator**, ולחצי Save.
