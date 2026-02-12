import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/manager_settings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// צבעי הדגשה למסך הגדרות
const Color _AccentRedDark = Color(0xFFAC2B31);
const Color _AccentRed = Color(0xFFED1C24);
const Color _AccentAmber = Color(0xFFFAA41A);
const Color _AccentLime = Color(0xFFB2D234);
const Color _AccentGreen = Color(0xFF40AE49);
const double _CardRadius = 20;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  ManagerSettings _settings = const ManagerSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<MapEntry<int, String>> _weekdayNames = [
    MapEntry(1, 'שני'),
    MapEntry(2, 'שלישי'),
    MapEntry(3, 'רביעי'),
    MapEntry(4, 'חמישי'),
    MapEntry(5, 'שישי'),
    MapEntry(6, 'שבת'),
    MapEntry(7, 'ראשון'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final s = await _firestoreService.getManagerSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(ManagerSettings next) async {
    setState(() => _isSaving = true);
    try {
      await _firestoreService.updateManagerSettings(next);
      if (!mounted) return;
      setState(() {
        _settings = next;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ההגדרות נשמרו')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירה: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הגדרות'),
          backgroundColor: _AccentRedDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(_CardRadius)),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('יעדים', _AccentGreen),
                  _buildGoalsCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('כללים', _AccentAmber),
                  _buildRulesCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('נוטיפיקציות', _AccentLime),
                  _buildNotificationsCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('דורשים טיפול', _AccentRed),
                  _buildNeedAttentionCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('שאלון מעורבות', _AccentGreen),
                  _buildFormLinkCard(),
                  const SizedBox(height: 24),
                  _buildSignOutCard(),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _AccentLime.withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: _AccentGreen),
        ),
        title: const Text('פרופיל', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_authService.currentUser?.email ?? 'לא מחובר'),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, color: _AccentRed, size: 22),
                SizedBox(width: 8),
                Text(
                  'כמה מילים טובות ברצונך לתת?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              key: ValueKey('goals_${_settings.goalsGoodWordsPerDay}_${_settings.goalsGoodWordsPerWeek}'),
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '${_settings.goalsGoodWordsPerDay}',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'ביום',
                      suffixText: 'מילים',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _AccentGreen, width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 0) {
                        _saveSettings(_settings.copyWith(goalsGoodWordsPerDay: n));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: '${_settings.goalsGoodWordsPerWeek}',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'בשבוע',
                      suffixText: 'מילים',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _AccentGreen, width: 2),
                      ),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n >= 0) {
                        _saveSettings(_settings.copyWith(goalsGoodWordsPerWeek: n));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.handshake, color: _AccentAmber, size: 22),
                SizedBox(width: 8),
                Text(
                  'תדירות פגישות',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.school, color: _AccentAmber, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('פגוש מחנכים')),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    initialValue: _settings.ruleMeetEducatorsMonths,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: [1, 2, 3, 4, 6].map((m) {
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(m == 1 ? 'פעם בחודש' : 'פעם ב־$m חודשים'),
                      );
                    }).toList(),
                    onChanged: _isSaving
                        ? null
                        : (v) {
                            if (v != null) {
                              _saveSettings(_settings.copyWith(ruleMeetEducatorsMonths: v));
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.badge, color: _AccentAmber, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('פגוש בעלי תפקידים')),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    initialValue: _settings.ruleMeetRoleHoldersMonths,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: [1, 2, 3, 4].map((m) {
                      return DropdownMenuItem<int>(
                        value: m,
                        child: Text(m == 1 ? 'פעם בחודש' : 'פעם ב־$m חודשים'),
                      );
                    }).toList(),
                    onChanged: _isSaving
                        ? null
                        : (v) {
                            if (v != null) {
                              _saveSettings(_settings.copyWith(ruleMeetRoleHoldersMonths: v));
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active, color: _AccentLime, size: 22),
                SizedBox(width: 8),
                Text(
                  'מתי לקבל התראות',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationRow(
              label: 'תחילת שבוע',
              weekday: _settings.notificationStartWeekWeekday,
              hour: _settings.notificationStartWeekHour,
              minute: _settings.notificationStartWeekMinute,
              onWeekdayChanged: (v) => _saveSettings(
                _settings.copyWith(notificationStartWeekWeekday: v),
              ),
              onTimeChanged: (h, m) => _saveSettings(
                _settings.copyWith(
                  notificationStartWeekHour: h,
                  notificationStartWeekMinute: m,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildNotificationRow(
              label: 'סוף שבוע',
              weekday: _settings.notificationEndWeekWeekday,
              hour: _settings.notificationEndWeekHour,
              minute: _settings.notificationEndWeekMinute,
              onWeekdayChanged: (v) => _saveSettings(
                _settings.copyWith(notificationEndWeekWeekday: v),
              ),
              onTimeChanged: (h, m) => _saveSettings(
                _settings.copyWith(
                  notificationEndWeekHour: h,
                  notificationEndWeekMinute: m,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRow({
    required String label,
    required int weekday,
    required int hour,
    required int minute,
    required ValueChanged<int> onWeekdayChanged,
    required void Function(int h, int m) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: _weekdayNames
                    .map((e) => DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: _isSaving ? null : (v) => v != null ? onWeekdayChanged(v) : null,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextFormField(
                initialValue: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                decoration: InputDecoration(
                  labelText: 'שעה',
                  hintText: '07:40',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _AccentLime, width: 2),
                  ),
                ),
                onChanged: (v) {
                  final parts = v.split(':');
                  if (parts.length >= 2) {
                    final h = int.tryParse(parts[0].trim());
                    final m = int.tryParse(parts[1].trim());
                    if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
                      onTimeChanged(h, m);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNeedAttentionCard() {
    const options = [
      MapEntry('all', 'כולם'),
      MapEntry('5', '5 הכי בולטים'),
      MapEntry('10', '10 הכי בולטים'),
    ];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_search, color: _AccentRed, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'כמה מורים להציג ברשימת "דורשים טיפול"',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...options.map((e) => RadioListTile<String>(
                  title: Text(e.value),
                  value: e.key,
                  groupValue: _settings.needAttentionLimit,
                  activeColor: _AccentRed,
                  onChanged: _isSaving
                      ? null
                      : (v) {
                          if (v != null) {
                            _saveSettings(_settings.copyWith(needAttentionLimit: v));
                          }
                        },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFormLinkCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.link, color: _AccentGreen, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'קישור לשאלון מעורבות – לשליחה לקבוצת הצוות',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'לקבלת קישור אישי למורה, היכנסי לכרטיס מורה ולחצי על כפתור השיתוף שם.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('פתחי כרטיס של מורה ספציפי ולחצי שם על כפתור השיתוף.'),
                    ),
                  );
                    if (mounted) {
                    // לא נדרש לבצע פעולה כאן – ההסבר בלבד.
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('העתק קישור ושתף'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AccentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _AccentRed.withValues(alpha: 0.15),
          child: const Icon(Icons.logout, color: _AccentRedDark),
        ),
        title: const Text(
          'התנתקות',
          style: TextStyle(color: _AccentRedDark, fontWeight: FontWeight.w600),
        ),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('התנתקות'),
              content: const Text('האם אתה בטוח שברצונך להתנתק?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ביטול'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('התנתק'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _authService.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        },
      ),
    );
  }
}
