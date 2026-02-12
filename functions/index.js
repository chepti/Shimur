const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();

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
