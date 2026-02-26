/**
 * סקריפט ליצירת Custom Token עבור משתמש ספציפי לפי UID.
 *
 * שימוש:
 * 1. התקיני: npm install firebase-admin
 * 2. הורידי Service Account מ-Firebase Console: Project Settings > Service Accounts > Generate new private key
 * 3. שמרי את הקובץ JSON בתיקייה זו (או צייני נתיב)
 * 4. הרצי: node create_custom_token.js <UID>
 *
 * דוגמה: node create_custom_token.js abc123xyz456
 *
 * הטוקן יודפס למסך – העתיקי והדביקי בשדה "התחברות עם טוקן" במסך ההתחברות.
 */

const admin = require('firebase-admin');
const path = require('path');

const uid = process.argv[2];
if (!uid) {
  console.error('שימוש: node create_custom_token.js <UID>');
  console.error('דוגמה: node create_custom_token.js abc123xyz456');
  process.exit(1);
}

// נסה לטעון Service Account – אפשר מהנתיב הנוכחי או מ-Firebase default
let serviceAccount;
try {
  serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
} catch (e) {
  console.error('לא נמצא serviceAccountKey.json. הורידי מ-Firebase Console:');
  console.error('Project Settings > Service Accounts > Generate new private key');
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

admin
  .auth()
  .createCustomToken(uid)
  .then((token) => {
    console.log('\nהטוקן נוצר בהצלחה. העתיקי והדביקי באפליקציה:\n');
    console.log(token);
    console.log('\n');
    process.exit(0);
  })
  .catch((err) => {
    console.error('שגיאה:', err.message);
    process.exit(1);
  });
