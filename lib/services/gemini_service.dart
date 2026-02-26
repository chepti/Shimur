import 'package:firebase_ai/firebase_ai.dart';
import '../models/teacher.dart';

/// שירות ליצירת תוכן חכם באמצעות Firebase AI Logic (Gemini).
/// משתמש בחשבון Firebase – אין צורך במפתח API בקוד.
class GeminiService {
  static const String _modelId = 'gemini-2.5-flash-lite';
  static const int _maxOutputTokens = 300;

  static GenerativeModel get _model => FirebaseAI.googleAI().generativeModel(
        model: _modelId,
        generationConfig: GenerationConfig(
          maxOutputTokens: _maxOutputTokens,
          temperature: 0.8,
        ),
      );

  /// מייצר 2–3 משפטי הודעה מותאמים למורה (לשליחה בוואטסאפ/טלפון).
  /// מחזיר רשימת משפטים קצרים, או null אם נכשל.
  static Future<List<String>?> generateMessageDrafts({
    required Teacher teacher,
  }) async {
    final prompt = _buildMessagePrompt(teacher);
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;

      final lines = text
          .split(RegExp(r'[\n•\-]'))
          .map((s) => s.trim())
          .where((s) => s.length > 10)
          .take(4)
          .toList();
      return lines.isEmpty ? [text] : lines;
    } catch (_) {
      return null;
    }
  }

  /// מייצר 2–4 המלצות לפעולות מותאמות למורה.
  static Future<List<String>?> generateActionSuggestions({
    required Teacher teacher,
  }) async {
    final prompt = _buildActionPrompt(teacher);
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: _modelId,
        generationConfig: GenerationConfig(
          maxOutputTokens: 200,
          temperature: 0.7,
        ),
      );
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return null;

      final lines = text
          .split(RegExp(r'[\n•\-]'))
          .map((s) => s.trim())
          .where((s) => s.length > 5)
          .take(5)
          .toList();
      return lines.isEmpty ? [text] : lines;
    } catch (_) {
      return null;
    }
  }

  static String _buildMessagePrompt(Teacher t) {
    final parts = <String>[
      'אתה עוזר למנהל בית ספר לנסח הודעת הוקרה/מילה טובה למורה.',
      'המורה: ${t.name}.',
    ];

    if (t.motivationStyles.isNotEmpty) {
      final labels = t.motivationStyles.map(_motivationLabel).join(', ');
      parts.add('סגנון מוטיבציה: $labels.');
    }
    if (t.moodStatus != null) {
      parts.add('סטטוס רגשי: ${_moodLabel(t.moodStatus!)}.');
    }
    if (t.status.isNotEmpty) {
      parts.add('סטטוס כללי: ${_statusLabel(t.status)}.');
    }
    if (t.busyWeekdays.isNotEmpty || t.busySeason != null || t.busyReason != null) {
      final busy = [
        if (t.busyWeekdays.isNotEmpty) 'ימים עמוסים: ${t.busyWeekdays.join(", ")}',
        if (t.busySeason != null) 'תקופת עומס: ${t.busySeason}',
        if (t.busyReason != null) 'סיבה: ${t.busyReason}',
      ].join('. ');
      parts.add('עומס: $busy.');
    }
    if (t.engagementSignals.isNotEmpty) {
      parts.add('תובנות מעורבות: ${t.engagementSignals.join(", ")}.');
    }
    if (t.roles.isNotEmpty) {
      parts.add('תפקידים: ${t.roles.join(", ")}.');
    }
    if (t.notes != null && t.notes!.isNotEmpty) {
      parts.add('הערה: ${t.notes}.');
    }

    parts.add('');
    parts.add('החזר 2–3 משפטים קצרים (עד 2 שורות כל אחד) להודעה אישית, חמה ומקצועית. ללא כותרת. רק הטקסט לשליחה.');

    return parts.join('\n');
  }

  static String _buildActionPrompt(Teacher t) {
    final parts = <String>[
      'אתה עוזר למנהל בית ספר להמליץ על פעולות שימור למורה.',
      'המורה: ${t.name}.',
    ];

    if (t.motivationStyles.isNotEmpty) {
      parts.add('סגנון מוטיבציה: ${t.motivationStyles.map(_motivationLabel).join(", ")}.');
    }
    if (t.moodStatus != null) {
      parts.add('סטטוס: ${_moodLabel(t.moodStatus!)}.');
    }
    parts.add('סטטוס: ${_statusLabel(t.status)}.');
    if (t.engagementSignals.isNotEmpty) {
      parts.add('מעורבות: ${t.engagementSignals.join(", ")}.');
    }
    if (t.roles.isNotEmpty) parts.add('תפקידים: ${t.roles.join(", ")}.');

    parts.add('');
    parts.add('החזר 2–4 המלצות ספציפיות לפעולות (שיחה, הודעה, פגישה וכו\') – כל שורה פעולה אחת. קצר ומדויק.');

    return parts.join('\n');
  }

  static String _motivationLabel(String key) {
    const m = {
      'gregariousness': 'חברותיות',
      'autonomy': 'אוטונומיה',
      'status': 'סטטוס',
      'inquisitiveness': 'סקרנות',
      'power': 'כוח',
      'affiliation': 'שייכות אישית',
    };
    return m[key] ?? key;
  }

  static String _moodLabel(String key) {
    const m = {
      'bloom': 'פורח',
      'flow': 'זורם',
      'tense': 'מתוח',
      'disconnected': 'מנותק',
      'burned_out': 'שחוק',
    };
    return m[key] ?? key;
  }

  static String _statusLabel(String s) {
    const m = {'green': 'טוב', 'yellow': 'דורש תשומת לב', 'red': 'דורש טיפול'};
    return m[s] ?? s;
  }
}
