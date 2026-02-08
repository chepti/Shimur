import 'package:flutter/material.dart';
import '../models/recommended_action.dart';
import '../models/recommended_action_comment.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// מסך מאגר פעולות מומלצות – צפייה, הוספה, דירוג, תגובות (למידה הדדית).
/// [pickerMode] – כשמופעל, בחירה בפעולה סוגרת את המסך ומחזירה את סוג הפעולה (למסך הוספת פעולה למורה).
class RecommendedActionsScreen extends StatefulWidget {
  final bool pickerMode;

  const RecommendedActionsScreen({
    Key? key,
    this.pickerMode = false,
  }) : super(key: key);

  @override
  State<RecommendedActionsScreen> createState() =>
      _RecommendedActionsScreenState();
}

class _RecommendedActionsScreenState extends State<RecommendedActionsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String? get _currentUserId => _authService.currentUserId;

  void _openAddRecommendedAction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const _AddRecommendedActionPage(),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPicker = widget.pickerMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isPicker ? 'בחר ממאגר פעולות מומלצות' : 'מאגר פעולות מומלצות',
          ),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<List<RecommendedAction>>(
          stream: _firestoreService.getRecommendedActionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'אין עדיין פעולות במאגר.\nהוסף פעולה ראשונה ותשתף עם מנהלים אחרים.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _openAddRecommendedAction,
                        icon: const Icon(Icons.add),
                        label: const Text('הוסף פעולה מומלצת'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF11a0db),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final rec = list[index];
                return _RecommendedActionCard(
                  recommendedAction: rec,
                  currentUserId: _currentUserId,
                  firestoreService: _firestoreService,
                  isPicker: isPicker,
                );
              },
            );
          },
        ),
        floatingActionButton: !widget.pickerMode
            ? FloatingActionButton(
                onPressed: _openAddRecommendedAction,
                backgroundColor: const Color(0xFF11a0db),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}

class _RecommendedActionCard extends StatefulWidget {
  final RecommendedAction recommendedAction;
  final String? currentUserId;
  final FirestoreService firestoreService;
  final bool isPicker;

  const _RecommendedActionCard({
    required this.recommendedAction,
    required this.currentUserId,
    required this.firestoreService,
    required this.isPicker,
  });

  @override
  State<_RecommendedActionCard> createState() => _RecommendedActionCardState();
}

class _RecommendedActionCardState extends State<_RecommendedActionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendedAction;
    final myRating = rec.ratingByUserId[widget.currentUserId];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (widget.isPicker) {
            Navigator.pop(context, widget.recommendedAction.type);
          } else {
            setState(() => _expanded = !_expanded);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rec.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (rec.ratingCount > 0) ...[
                    Icon(Icons.star, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      rec.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      ' (${rec.ratingCount})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (!widget.isPicker)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                ],
              ),
              if (rec.isAnonymous)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'שותף באנונימיות',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (_expanded && !widget.isPicker) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'דרג את הפעולה',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    final selected = myRating != null && myRating >= star;
                    return IconButton(
                      icon: Icon(
                        selected ? Icons.star : Icons.star_border,
                        color: Colors.amber[700],
                        size: 28,
                      ),
                      onPressed: () async {
                        await widget.firestoreService.setRecommendedActionRating(
                          rec.id,
                          star,
                        );
                        if (mounted) setState(() {});
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                const Text(
                  'תגובות מנהלים',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<RecommendedActionComment>>(
                  stream: widget.firestoreService
                      .getRecommendedActionCommentsStream(rec.id),
                  builder: (context, commentSnapshot) {
                    final comments = commentSnapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...comments.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.isAnonymous
                                        ? 'מנהל/ת (אנונימי/ת)'
                                        : 'מנהל/ת',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.text),
                                ],
                              ),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddCommentDialog(rec.id),
                          icon: const Icon(Icons.add_comment, size: 20),
                          label: const Text('הוסף תגובה (למשל: עזר לי מאוד עם מורים מתמחים)'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCommentDialog(String recommendedActionId) async {
    final controller = TextEditingController();
    var isAnonymous = true;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('הוסף תגובה'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'למשל: "עזר לי מאוד עם מורים מתמחים"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'התגובה שלך',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('שתף באנונימיות'),
                      value: isAnonymous,
                      onChanged: (v) {
                        setDialogState(() => isAnonymous = v ?? true);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(context);
                    await widget.firestoreService.addRecommendedActionComment(
                      recommendedActionId: recommendedActionId,
                      text: text,
                      isAnonymous: isAnonymous,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('התגובה נשמרה')),
                      );
                    }
                  },
                  child: const Text('שמור'),
                ),
              ],
            ),
          );
        },
      ),
    );
    controller.dispose();
  }
}

class _AddRecommendedActionPage extends StatefulWidget {
  const _AddRecommendedActionPage();

  @override
  State<_AddRecommendedActionPage> createState() =>
      _AddRecommendedActionPageState();
}

class _AddRecommendedActionPageState extends State<_AddRecommendedActionPage> {
  final _firestoreService = FirestoreService();
  final _typeController = TextEditingController();
  bool _isAnonymous = true;
  bool _saving = false;

  static const List<String> _suggestedTypes = [
    'שיחה אישית - הקשבה ותמיכה',
    'פגישת משוב מעצים',
    'הודעת הוקרה (וואטסאפ/טלפון)',
    'מכתב הערכה רשמי',
    'הצעת תפקיד חדש/אחריות',
    'המלצה להשתלמות/פיתוח מקצועי',
    'ביקור בשיעור (למידת עמיתים)',
    'מתנה קטנה/סימן תשומת לב',
    'עזרה בבעיה אישית/מקצועית',
    'שיתוף בקבלת החלטות',
    'ציון יום הולדת/אירוע אישי',
    'אחר',
  ];

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final type = _typeController.text.trim();
    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להזין סוג פעולה')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _firestoreService.addRecommendedAction(
        type: type,
        isAnonymous: _isAnonymous,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הפעולה נוספה למאגר')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הוסף פעולה למאגר מומלצות'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'סוג הפעולה שאת/ה ממליץ/ה (ניתן לבחור מהרשימה או להקליד)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                hint: const Text('בחר או השאר והקלד למטה'),
                items: _suggestedTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _typeController.text = v;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'סוג פעולה (או הקלד מותאם)',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('שתף באנונימיות'),
                subtitle: const Text(
                  'שם המשתמש לא יוצג למנהלים אחרים',
                ),
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11a0db),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('הוסף למאגר'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
