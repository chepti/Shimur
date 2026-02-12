const functions = require('firebase-functions');
const admin = require('firebase-admin');

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

exports.submitEngagementForm = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    const { token, itemScores, itemNotes, motivationStyles, roles, engagementNote } = req.body;

    if (!token || typeof token !== 'string') {
      res.status(400).json({ error: 'חסר טוקן' });
      return;
    }

    if (!itemScores || typeof itemScores !== 'object') {
      res.status(400).json({ error: 'חסרים ציוני השאלון' });
      return;
    }

    const db = admin.firestore();
    const snapshot = await db.collectionGroup('teachers')
      .where('formToken', '==', token.trim())
      .limit(1)
      .get();

    if (snapshot.empty) {
      res.status(404).json({ error: 'קישור לא תקין או שפג תוקפו' });
      return;
    }

    const doc = snapshot.docs[0];
    const pathParts = doc.ref.path.split('/');
    const schoolId = pathParts[1];
    const teacherId = pathParts[3];

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
    const rolesList = Array.isArray(roles) ? roles : (typeof roles === 'string' ? roles.split(',').map(s => s.trim()).filter(Boolean) : []);

    const updateData = {
      engagementItemScores: itemScoresInt,
      engagementItemNotes: itemNotesObj,
      engagementDomainScores: domainScores,
      motivationStyles: motivationList,
      roles: rolesList,
      engagementNote: engagementNote && typeof engagementNote === 'string' ? engagementNote.trim() || null : null,
    };

    await doc.ref.update(updateData);

    res.status(200).json({ success: true });
  } catch (err) {
    console.error('submitEngagementForm error:', err);
    res.status(500).json({ error: 'שגיאה בשמירת השאלון' });
  }
});
