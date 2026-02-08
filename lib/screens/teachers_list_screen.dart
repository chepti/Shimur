import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../models/manager_settings.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/teacher_card.dart';
import '../widgets/hebrew_gregorian_date.dart';
import 'add_teacher_screen.dart';
import 'teacher_details_screen.dart';
import '../models/action.dart' as teacher_action;

class TeachersListScreen extends StatefulWidget {
  const TeachersListScreen({Key? key}) : super(key: key);

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
                        'דורשים טיפול',
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTeacherScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF11a0db),
          child: const Icon(Icons.add, color: Colors.white),
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

  /// מורים שדורשים טיפול: סטטוס אדום/צהוב, או ללא אינטראקציה ממושכת. ממוין לפי עדיפות.
  List<Teacher> _teachersNeedingAttention(List<Teacher> teachers) {
    final now = DateTime.now();
    final list = List<Teacher>.from(teachers);
    list.sort((a, b) {
      final scoreA = _needAttentionScore(a, now);
      final scoreB = _needAttentionScore(b, now);
      return scoreB.compareTo(scoreA); // גבוה יותר = קודם
    });
    return list;
  }

  int _needAttentionScore(Teacher t, DateTime now) {
    int score = 0;
    if (t.status == 'red') {
      score += 100;
    } else if (t.status == 'yellow') {
      score += 50;
    }
    final last = t.lastInteractionDate;
    if (last == null) {
      score += 30;
    } else {
      final days = now.difference(last).inDays;
      if (days > 14) {
        score += 20;
      } else if (days > 7) {
        score += 10;
      }
    }
    return score;
  }

  /// אזור \"מילה טובה\" – טקסט + כפתור עגול דרמטי ללא קונטיינר מסביב
  Widget _buildGoodWordArea({
    required BuildContext context,
    required List<Teacher> teachers,
    required int dailyGoal,
  }) {
    final firestoreService = _firestoreService;

    return FutureBuilder<int>(
      future: firestoreService.getTodayCompletedActionsCount(),
      builder: (context, snapshot) {
        final completedToday = snapshot.data ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.favorite_border, color: Color(0xFF11a0db)),
                SizedBox(width: 8),
                Text(
                  'היום אמרתי מילה טובה',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'טאפּ אחד על הכפתור העגול – בחירת מורה מהירה ושמירת האינטראקציה.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _openGoodWordTeacherPicker(context, teachers),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFFF3EB), // רקע בהיר
                      Colors.white,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF36F21).withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF11a0db).withOpacity(0.25),
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 40,
                      color: Color(0xFFF36F21),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'אמרתי מילה טובה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'נגיעה קטנה. השפעה גדולה.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
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

  /// Bottom sheet לבחירת מורה מהירה ויצירת פעולה מסוג "מילה טובה קטנה"
  void _openGoodWordTeacherPicker(
    BuildContext context,
    List<Teacher> teachers,
  ) {
    final firestoreService = _firestoreService;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
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
                  const Text(
                    'למי אמרת מילה טובה?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'בחר מורה אחד או כמה, והמערכת תשמור את האינטראקציה הקטנה.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: teachers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        final statusColor =
                            _statusColor(teacher.moodStatus ?? teacher.status);
                        final now = DateTime.now();
                        String daysText;
                        if (teacher.lastInteractionDate == null) {
                          daysText = 'עדיין לא נוצר יחס';
                        } else {
                          final diffDays =
                              now.difference(teacher.lastInteractionDate!).inDays;
                          if (diffDays == 0) {
                            daysText = 'היום היתה אינטראקציה אחרונה';
                          } else if (diffDays == 1) {
                            daysText = 'אתמול היתה אינטראקציה אחרונה';
                          } else {
                            daysText = '$diffDays ימים מהיחס האחרון';
                          }
                        }
                        final roleText = teacher.roles.isNotEmpty
                            ? teacher.roles.join(', ')
                            : null;
                        final subtitleText = roleText != null
                            ? '$roleText · $daysText'
                            : daysText;
                        return ListTile(
                          leading: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF11a0db),
                          ),
                          title: Text(
                            teacher.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          onTap: () async {
                            final action = teacher_action.Action(
                              id: '',
                              type: 'מילה טובה קטנה',
                              date: DateTime.now(),
                              notes: null,
                              completed: true,
                              createdAt: DateTime.now(),
                            );

                            try {
                              await firestoreService.addAction(
                                teacher.id,
                                action,
                              );
                              if (Navigator.of(sheetContext).canPop()) {
                                Navigator.of(sheetContext).pop();
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'נשמרה מילה טובה למורה ${teacher.name}',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('שגיאה בשמירת מילה טובה: $e'),
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

