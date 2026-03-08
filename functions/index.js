const functions = require('firebase-functions');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();

const adminLoginSecret = defineString('ADMIN_LOGIN_SECRET', {
  description: 'Secret for admin login as another user',
});

const DOMAIN_ITEMS = {
  basic_needs: ['q1', 'q2'],
  individual_contribution: ['q3', 'q4'],
  team_belonging: ['q5', 'q6', 'q7', 'q8', 'q9', 'q10'],
  personal_growth: ['q11', 'q12'],
};

function computeDomainScores(itemScores) {
  const domainScores = {};
  for (const [domain, keys] of Object.entries(DOMAIN_ITEMS)) {
    let sum = 0;
    let count = 0;
    for (const key of keys) {
      const s = itemScores[key];
      if (s != null) {
        sum += s;
        count++;
      }
    }
    if (count > 0) {
      domainScores[domain] = Math.round(sum / count);
      domainScores[domain] = Math.max(1, Math.min(6, domainScores[domain]));
    }
  }
  return domainScores;
}

async function getSchoolIdFromToken(db, token) {
  const snapshot = await db.collectionGroup('settings')
    .where('schoolFormToken', '==', token.trim())
    .limit(1)
    .get();
  if (snapshot.empty) return null;
  const pathParts = snapshot.docs[0].ref.path.split('/');
  return pathParts[1];
}

exports.getFormTeachers = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'GET' && req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
    const token = req.method === 'GET' ? req.query.t : (req.body?.token);
    if (!token) {
      res.status(400).json({ error: 'חסר טוקן' });
      return;
    }

    const db = admin.firestore();
    const schoolId = await getSchoolIdFromToken(db, token);
    if (!schoolId) {
      res.status(404).json({ error: 'קישור לא תקין' });
      return;
    }

    const teachersSnapshot = await db.collection('schools').doc(schoolId)
      .collection('teachers')
      .orderBy('createdAt', 'asc')
      .get();

    const teachers = teachersSnapshot.docs.map((d) => ({
      id: d.id,
      name: d.data().name || '',
    })).filter((t) => t.name);

    res.status(200).json({ teachers });
    } catch (err) {
      console.error('getFormTeachers error:', err);
      res.status(500).json({ error: 'שגיאה' });
    }
  });
});

/**
 * HTTP (v1) – מחזיר Custom Token. לשימוש מ-Flutter Web (נמנע מ-Int64 ב-dart2js).
 */
exports.getCustomTokenForUidHttp = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    try {
      let body = req.body || {};
      if (typeof body === 'string') {
        try { body = body ? JSON.parse(body) : {}; } catch (_) { body = {}; }
      }
      const { uid, secret } = body;
      let expectedSecret = process.env.ADMIN_LOGIN_SECRET
        || (typeof functions.config === 'function' && functions.config().admin?.login_secret);
      if (!expectedSecret && adminLoginSecret && typeof adminLoginSecret.value === 'function') {
        try { expectedSecret = adminLoginSecret.value(); } catch (_) {}
      }
      if (!expectedSecret) {
        res.status(500).json({ error: 'ADMIN_LOGIN_SECRET לא מוגדר. הרצי: firebase functions:config:set admin.login_secret="הסוד"' });
        return;
      }
      if (secret !== expectedSecret) {
        res.status(403).json({ error: 'סוד שגוי – וודאי ש-admin_login_secret.dart תואם ל-firebase functions:config' });
        return;
      }
      if (!uid || typeof uid !== 'string' || uid.trim().length === 0) {
        res.status(400).json({ error: 'UID required' });
        return;
      }
      const cleanUid = String(uid).trim();
      const token = await admin.auth().createCustomToken(cleanUid);
      res.status(200).json({ token });
    } catch (err) {
      console.error('getCustomTokenForUidHttp error:', err);
      const msg = err && err.message ? err.message : 'Error creating token';
      res.status(500).json({ error: msg });
    }
  });
});

/**
 * Callable – מחזיר Custom Token להתחברות כמשתמש לפי UID.
 * משתמש ב-params (ADMIN_LOGIN_SECRET) – מוגדר ב-.env.shimur
 */
exports.getCustomTokenForUid = onCall(async (request) => {
  const { uid, secret } = request.data || {};
  const expectedSecret = adminLoginSecret.value();
  if (!expectedSecret) {
    throw new HttpsError('failed-precondition', 'ADMIN_LOGIN_SECRET not set');
  }
  if (secret !== expectedSecret) {
    throw new HttpsError('permission-denied', 'Invalid secret');
  }
  if (!uid || typeof uid !== 'string' || uid.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'UID required');
  }
  const token = await admin.auth().createCustomToken(uid.trim());
  return { token };
});

/**
 * Callable – שולח התראת בדיקה למשתמש המחובר.
 */
exports.sendTestNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'יש להתחבר');
  }
  const uid = request.auth.uid;
  const db = admin.firestore();
  const settingsSnap = await db
    .collection('schools')
    .doc(uid)
    .collection('settings')
    .doc('manager')
    .get();
  if (!settingsSnap.exists) {
    throw new HttpsError('failed-precondition', 'אין טוקנים – הפעילי קודם התראות בהגדרות');
  }
  const data = settingsSnap.data();
  const fcmTokens = data?.fcmTokens;
  if (!Array.isArray(fcmTokens) || fcmTokens.length === 0) {
    throw new HttpsError('failed-precondition', 'אין טוקנים – הפעילי קודם התראות בהגדרות');
  }
  const tokens = fcmTokens.map((t) => (t && typeof t.token === 'string' ? t.token : null)).filter(Boolean);
  if (tokens.length === 0) {
    throw new HttpsError('failed-precondition', 'אין טוקנים – הפעילי קודם התראות בהגדרות');
  }

  const message = {
    notification: {
      title: 'בדיקה – שימור המורים',
      body: 'ההתראה עובדת! תוכלי לקבל התראות בתחילת וסוף השבוע.',
      imageUrl: 'https://shimur.web.app/icons/Icon-192.png',
    },
    data: { type: 'test' },
    android: {
      priority: 'high',
      notification: { channelId: 'shimur_weekly', color: '#0175C2' },
    },
    webpush: { fcmOptions: { link: 'https://shimur.web.app' } },
  };

  const messaging = admin.messaging();
  let sent = 0;
  for (const token of tokens) {
    try {
      await messaging.send({ ...message, token });
      sent++;
    } catch (_) {}
  }
  return { sent };
});

exports.submitEngagementForm = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    try {
    const {
      token,
      teacherId,
      teacherName,
      itemScores,
      itemNotes,
      motivationStyles,
      roles,
      engagementNote,
    } = req.body;

    if (!token || typeof token !== 'string') {
      res.status(400).json({ error: 'חסר טוקן' });
      return;
    }
    if (!itemScores || typeof itemScores !== 'object') {
      res.status(400).json({ error: 'חסרים ציוני השאלון' });
      return;
    }

    const db = admin.firestore();
    const schoolId = await getSchoolIdFromToken(db, token);
    if (!schoolId) {
      res.status(404).json({ error: 'קישור לא תקין או שפג תוקפו' });
      return;
    }

    const teachersRef = db.collection('schools').doc(schoolId).collection('teachers');
    let targetTeacherId = teacherId;

    if (!targetTeacherId && teacherName && typeof teacherName === 'string') {
      const name = teacherName.trim();
      if (!name) {
        res.status(400).json({ error: 'נא לבחור מורה או להזין את שמך' });
        return;
      }
      const newTeacher = {
        name,
        seniorityYears: 0,
        totalSeniorityYears: 0,
        status: 'green',
        createdAt: new Date().toISOString(),
        workloadPercent: 86,
        satisfactionRating: 3,
        belongingRating: 3,
        workloadRating: 3,
        absencesThisYear: 0,
        specialActivities: [],
        busyWeekdays: [],
        motivationStyles: [],
        engagementSignals: [],
      };
      const addRes = await teachersRef.add(newTeacher);
      targetTeacherId = addRes.id;
    } else if (!targetTeacherId) {
      res.status(400).json({ error: 'נא לבחור מורה או להזין את שמך' });
      return;
    }

    const teacherRef = teachersRef.doc(targetTeacherId);
    const teacherDoc = await teacherRef.get();
    if (!teacherDoc.exists) {
      res.status(404).json({ error: 'מורה לא נמצא' });
      return;
    }

    const itemScoresInt = {};
    for (let i = 1; i <= 12; i++) {
      const key = 'q' + i;
      const val = itemScores[key];
      if (val != null) {
        const n = parseInt(val, 10);
        if (!isNaN(n) && n >= 1 && n <= 6) {
          itemScoresInt[key] = n;
        }
      }
    }

    const domainScores = computeDomainScores(itemScoresInt);
    const itemNotesObj = itemNotes && typeof itemNotes === 'object' ? itemNotes : {};
    const motivationList = Array.isArray(motivationStyles) ? motivationStyles : [];
    const rolesList = Array.isArray(roles) ? roles : (typeof roles === 'string' ? roles.split(',').map((s) => s.trim()).filter(Boolean) : []);

    const updateData = {
      engagementItemScores: itemScoresInt,
      engagementItemNotes: itemNotesObj,
      engagementDomainScores: domainScores,
      motivationStyles: motivationList,
      roles: rolesList,
      engagementNote: engagementNote && typeof engagementNote === 'string' ? engagementNote.trim() || null : null,
    };

    await teacherRef.update(updateData);

    res.status(200).json({ success: true });
    } catch (err) {
      console.error('submitEngagementForm error:', err);
      res.status(500).json({ error: 'שגיאה בשמירת השאלון' });
    }
  });
});

/**
 * התראות Push מתוזמנות – תחילת שבוע וסוף שבוע.
 * רץ כל 15 דקות, בודק אם השעה והיום תואמים להגדרות המנהל.
 * Manager: 1=שני … 7=ראשון. JS: 0=ראשון, 1=שני … 6=שבת.
 */
exports.sendScheduledNotifications = onSchedule(
  { schedule: 'every 15 minutes', timeZone: 'Asia/Jerusalem' },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const jsDay = now.getDay(); // 0=Sun, 1=Mon, ...
    const hour = now.getHours();
    const minute = now.getMinutes();
    // חלון של 15 דקות – אם השעה הנוכחית בתוך הטווח
    const minuteSlot = Math.floor(minute / 15) * 15;

    const schoolsSnap = await db.collection('schools').get();
    const messaging = admin.messaging();

    for (const schoolDoc of schoolsSnap.docs) {
      const schoolId = schoolDoc.id;
      const settingsSnap = await db
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('manager')
        .get();
      if (!settingsSnap.exists) continue;

      const data = settingsSnap.data();
      const fcmTokens = data?.fcmTokens;
      if (!Array.isArray(fcmTokens) || fcmTokens.length === 0) continue;

      const tokens = fcmTokens.map((t) => (t && typeof t.token === 'string' ? t.token : null)).filter(Boolean);
      if (tokens.length === 0) continue;

      // Manager: 7=ראשון(0), 1=שני(1), ... 6=שבת(6)
      const managerDay = (d) => (d === 0 ? 7 : d);
      const targetDay = managerDay(jsDay);

      const nStart = {
        w: data.notificationStartWeekWeekday ?? 7,
        h: data.notificationStartWeekHour ?? 7,
        m: data.notificationStartWeekMinute ?? 40,
      };
      const nEnd = {
        w: data.notificationEndWeekWeekday ?? 4,
        h: data.notificationEndWeekHour ?? 16,
        m: data.notificationEndWeekMinute ?? 0,
      };

      let title = '';
      let body = '';

      if (targetDay === nStart.w && hour === nStart.h && minuteSlot === Math.floor(nStart.m / 15) * 15) {
        title = 'התחלת שבוע – שימור המורים';
        body = 'פגישות מומלצות, מילים טובות וימי הולדת – פתח את האפליקציה לעדכון';
      } else if (targetDay === nEnd.w && hour === nEnd.h && minuteSlot === Math.floor(nEnd.m / 15) * 15) {
        title = 'סוף שבוע – שימור המורים';
        body = 'סיכום השבוע והכנה לשבוע הבא – פתח את האפליקציה';
      }

      if (!title) continue;

      const message = {
        notification: {
          title,
          body,
          imageUrl: 'https://shimur.web.app/icons/Icon-192.png',
        },
        data: {
          type: targetDay === nStart.w ? 'weekly_start' : 'weekly_end',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'shimur_weekly',
            color: '#0175C2',
          },
        },
        webpush: {
          fcmOptions: {
            link: 'https://shimur.web.app',
          },
        },
      };

      for (const token of tokens) {
        try {
          await messaging.send({ ...message, token });
        } catch (err) {
          if (err.code === 'messaging/invalid-registration-token' ||
              err.code === 'messaging/registration-token-not-registered') {
            // טוקן לא תקף – אפשר להסיר מ־Firestore (לא מטפלים כאן)
          }
        }
      }
    }
  }
);
