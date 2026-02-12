import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../models/manager_settings.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/teacher_card.dart';
import '../widgets/hebrew_gregorian_date.dart';
import 'teacher_details_screen.dart';
import '../models/action.dart' as teacher_action;

class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({super.key});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  final _firestoreService = FirestoreService();
  ManagerSettings _settings = const ManagerSettings();

  @override
  void initState() {
    super.initState();
    _firestoreService.getManagerSettings().then((s) {
      if (mounted) {
        setState(() => _settings = s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          surfaceTintColor: Colors.white,
          title: SizedBox(
            height: 40,
            child: Image.network(
              'https://i.imgur.com/9xCiffu.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        body: StreamBuilder<List<Teacher>>(
              stream: _firestoreService.getTeachersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('שגיאה: ${snapshot.error}'),
                  );
                }

                final teachers = snapshot.data ?? [];

                if (teachers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'עדיין אין מורים במערכת',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'הוסף מורה ראשון כדי להתחיל להגיד מילה טובה',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final needAttentionList = _teachersNeedingAttention(teachers);
                final limit = _settings.needAttentionCount;
                final displayedNeedAttention = limit == null
                    ? needAttentionList
                    : needAttentionList.take(limit).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: 16),
                _buildGoodWordArea(
                  context: context,
                  teachers: teachers,
                  dailyGoal: _settings.goalsGoodWordsPerDay > 0
                      ? _settings.goalsGoodWordsPerDay
                      : 10,
                ),
                if (displayedNeedAttention.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'המורים שלי',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...displayedNeedAttention.map(
                    (teacher) => TeacherCard(
                      teacher: teacher,
                      actionsCount: 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherDetailsScreen(
                              teacherId: teacher.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'הצוות שלי',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                ...teachers.map(
                  (teacher) => TeacherCard(
                    teacher: teacher,
                    actionsCount: 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherDetailsScreen(
                            teacherId: teacher.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            );
              },
            ),
      ),
    );
  }

  /// כותרת פתיחה אישית למנהל/ת
  Widget _buildWelcomeHeader(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final rawName = user?.displayName ?? user?.email?.split('@').first;
    final managerName =
        (rawName != null && rawName.isNotEmpty) ? rawName : 'מנהל/ת';

    final hour = DateTime.now().hour;
    final greetingTime =
        hour < 12 ? 'בוקר טוב' : (hour < 18 ? 'צהריים טובים' : 'ערב טוב');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ברוך הבא',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$greetingTime, $managerName',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        HebrewGregorianDateText(
          date: DateTime.now(),
        ),
      ],
    );
  }

  /// רשימת מורים ממוינת לפי כמה זמן עבר מהיחס האחרון (הכי מוזנח למעלה).
  List<Teacher> _teachersNeedingAttention(List<Teacher> teachers) {
    final now = DateTime.now();
    final list = List<Teacher>.from(teachers);
    list.sort((a, b) {
      final daysA = a.lastInteractionDate == null
          ? 10000
          : now.difference(a.lastInteractionDate!).inDays;
      final daysB = b.lastInteractionDate == null
          ? 10000
          : now.difference(b.lastInteractionDate!).inDays;
      return daysB.compareTo(daysA); // יותר ימים = קודם
    });
    return list;
  }

  /// אזור \"מילה טובה\" – טקסט + כפתור עגול דרמטי ללא קונטיינר מסביב
  Widget _buildGoodWordArea({
    required BuildContext context,
    required List<Teacher> teachers,
    required int dailyGoal,
  }) {
    return FutureBuilder<int>(
      future: _firestoreService.getTodayCompletedActionsCount(),
      builder: (context, snapshot) {
        final completedToday = snapshot.data ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _openInteractionTeacherPicker(
                context,
                teachers,
                interactionType: 'התייחסתי',
                sheetTitle: 'למי התייחסתי?',
                sheetSubtitle:
                    'בחר מורה אחד או כמה, והמערכת תשמור עבורך התייחסות קטנה.',
              ),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFF3EB),
                      Colors.white,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFED1C24).withOpacity(0.28),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFAC2B31).withOpacity(0.45),
                    width: 5,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.waves,
                      size: 44,
                      color: Color(0xFFED1C24),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'התייחסתי',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniInteractionCircle(
                  label: 'מילה טובה',
                  icon: Icons.favorite_border,
                  color: const Color(0xFFED1C24),
                  onTap: () => _openInteractionTeacherPicker(
                    context,
                    teachers,
                    interactionType: 'מילה טובה קטנה',
                    sheetTitle: 'למי אמרתי מילה טובה?',
                    sheetSubtitle:
                        'בחר מורה אחד או כמה, והמערכת תשמור מילה טובה קטנה.',
                  ),
                ),
                _buildMiniInteractionCircle(
                  label: 'דיבור קצר',
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFFFAA41A),
                  onTap: () => _openInteractionTeacherPicker(
                    context,
                    teachers,
                    interactionType: 'דיבור קצר',
                    sheetTitle: 'עם מי היה לי דיבור קצר?',
                    sheetSubtitle:
                        'בחר מורה אחד או כמה, והמערכת תשמור דיבור קצר.',
                  ),
                ),
                _buildMiniInteractionCircle(
                  label: 'נפגשתי',
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF40AE49),
                  onTap: () => _openInteractionTeacherPicker(
                    context,
                    teachers,
                    interactionType: 'נפגשתי',
                    sheetTitle: 'עם מי נפגשתי?',
                    sheetSubtitle:
                        'בחר מורה אחד או כמה, והמערכת תשמור פגישה שהתקיימה.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'התקדמות יומית',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$completedToday / $dailyGoal מילים טובות',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF11a0db),
                      ),
                    ),
                  )
                else
                  _buildGoalProgressBar(
                    completedToday,
                    dailyGoal,
                  ),
              ],
            )
          ],
        );
      },
    );
  }

  /// עיגול קטן לאינטראקציה מהירה (מילה טובה / דיבור קצר / נפגשתי)
  Widget _buildMiniInteractionCircle({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.18),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.7),
                width: 3,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet לבחירת מורה מהירה ויצירת פעולה מהירה מסוג התייחסות
  void _openInteractionTeacherPicker(
    BuildContext context,
    List<Teacher> teachers, {
    required String interactionType,
    required String sheetTitle,
    required String sheetSubtitle,
  }) {
    final firestoreService = _firestoreService;
    final nowForSort = DateTime.now();

    final sortedTeachers = List<Teacher>.from(teachers);
    sortedTeachers.sort((a, b) {
      int daysSinceA = a.lastInteractionDate == null
          ? 10000
          : nowForSort.difference(a.lastInteractionDate!).inDays;
      int daysSinceB = b.lastInteractionDate == null
          ? 10000
          : nowForSort.difference(b.lastInteractionDate!).inDays;
      return daysSinceB.compareTo(daysSinceA); // יותר ימים = קודם
    });

    String searchQuery = '';
    bool showSearchField = false;
    final selectedTeacherIds = <String>{};

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (modalContext, setModalState) {
              final query = searchQuery.trim().toLowerCase();
              final visibleTeachers = query.isEmpty
                  ? sortedTeachers
                  : sortedTeachers
                      .where((t) => t.name.toLowerCase().contains(query))
                      .toList();

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: 'חיפוש לפי שם',
                            onPressed: () {
                              setModalState(
                                  () => showSearchField = !showSearchField);
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                sheetTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sheetSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (showSearchField) ...[
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'חפש/י מורה לפי שם',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Flexible(
                        child: visibleTeachers.isEmpty
                            ? Center(
                                child: Text(
                                  'לא נמצאו מורים שמתאימים לחיפוש',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: visibleTeachers.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final teacher = visibleTeachers[index];
                                  final statusColor = _statusColor(
                                      teacher.moodStatus ?? teacher.status);
                                  final now = DateTime.now();
                                  String daysText;
                                  if (teacher.lastInteractionDate == null) {
                                    daysText = 'עדיין לא נוצר יחס';
                                  } else {
                                    final diffDays = now
                                        .difference(teacher.lastInteractionDate!)
                                        .inDays;
                                    if (diffDays == 0) {
                                      daysText = 'היום היתה אינטראקציה אחרונה';
                                    } else if (diffDays == 1) {
                                      daysText =
                                          'אתמול היתה אינטראקציה אחרונה';
                                    } else {
                                      daysText =
                                          '$diffDays ימים מהיחס האחרון';
                                    }
                                  }
                                  final roleText = teacher.roles.isNotEmpty
                                      ? teacher.roles.join(', ')
                                      : null;
                                  final infoParts = <String>[];
                                  if (roleText != null) {
                                    infoParts.add(roleText);
                                  }
                                  infoParts.add(daysText);
                                  final infoText = infoParts.join(' · ');
                                  final isSelected =
                                      selectedTeacherIds.contains(teacher.id);

                                  return ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(
                                      horizontal: 0,
                                      vertical: -2,
                                    ),
                                    leading: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF11a0db),
                                    ),
                                    title: Text(
                                      '${teacher.name} – $infoText',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                      ),
                                    ),
                                    tileColor: isSelected
                                        ? Colors.blue.withOpacity(0.06)
                                        : null,
                                    onTap: () async {
                                      if (selectedTeacherIds
                                          .contains(teacher.id)) {
                                        return;
                                      }

                                      setModalState(() {
                                        selectedTeacherIds.add(teacher.id);
                                      });

                                      final now = DateTime.now();
                                      final action = teacher_action.Action(
                                        id: '',
                                        type: interactionType,
                                        date: now,
                                        notes: null,
                                        completed: true,
                                        createdAt: now,
                                      );

                                      try {
                                        await firestoreService.addAction(
                                          teacher.id,
                                          action,
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'שגיאה בשמירת ההתייחסות: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Color _statusColor(String status) {
    switch (status) {
      case 'bloom':
        return const Color(0xFF40AE49);
      case 'flow':
        return const Color(0xFFB2D234);
      case 'tense':
        return const Color(0xFFFAA41A);
      case 'disconnected':
        return const Color(0xFFED1C24);
      case 'burned_out':
        return const Color(0xFFAC2B31);
      case 'green':
        return const Color(0xFF40AE49);
      case 'yellow':
        return const Color(0xFFFAA41A);
      case 'red':
        return const Color(0xFFED1C24);
      default:
        return Colors.grey;
    }
  }

  /// ציר התקדמות יומי – כאשר חוצים את היעד,
  /// החלק שמעבר ליעד מוצג בירוק.
  Widget _buildGoalProgressBar(int completedToday, int dailyGoal) {
    if (dailyGoal <= 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    if (completedToday <= 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    const primaryColor = Color(0xFF11a0db);
    const extraColor = Color(0xFF40AE49);

    if (completedToday <= dailyGoal) {
      final remaining = dailyGoal - completedToday;
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                flex: completedToday,
                child: Container(color: primaryColor),
              ),
              if (remaining > 0)
                Expanded(
                  flex: remaining,
                  child: Container(color: Colors.grey[200]),
                ),
            ],
          ),
        ),
      );
    } else {
      final extra = completedToday - dailyGoal;
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                flex: dailyGoal,
                child: Container(color: primaryColor),
              ),
              Expanded(
                flex: extra,
                child: Container(color: extraColor),
              ),
            ],
          ),
        ),
      );
    }
  }
}

