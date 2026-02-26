import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/manager_settings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'add_teacher_screen.dart';
import 'external_surveys_screen.dart';

// צבעי הדגשה למסך הגדרות
const Color _AccentRedDark = Color(0xFFAC2B31);
const Color _AccentRed = Color(0xFFED1C24);
const Color _AccentAmber = Color(0xFFFAA41A);
const Color _AccentLime = Color(0xFFB2D234);
const Color _AccentGreen = Color(0xFF40AE49);
const double _CardRadius = 20;
const double _notificationFieldHeight = 48;

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
  String? _schoolLogoUrl;
  String? _managerName;
  bool _logoUploading = false;
  final _managerNameController = TextEditingController();
  final _managerNameFocusNode = FocusNode();

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
    _managerNameFocusNode.addListener(_onManagerNameFocusChange);
    _loadSettings();
  }

  void _onManagerNameFocusChange() {
    if (!_managerNameFocusNode.hasFocus) _saveManagerName();
  }

  @override
  void dispose() {
    _managerNameFocusNode.removeListener(_onManagerNameFocusChange);
    _managerNameFocusNode.dispose();
    _managerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final s = await _firestoreService.getManagerSettings();
    final school = await _firestoreService.getSchool();
    if (mounted) {
      _managerName = school?['managerName'] as String?;
      _managerNameController.text = _managerName ?? '';
      setState(() {
        _settings = s;
        _schoolLogoUrl = school?['logoUrl'] as String?;
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
                clipBehavior: Clip.none,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileCardWithLogo(),
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
                _buildSectionTitle('צוות המורים', _AccentRedDark),
                _buildTeachersManagementCard(),
                const SizedBox(height: 20),
                  _buildSectionTitle('שאלון מעורבות', _AccentGreen),
                  _buildFormLinkCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('שאלונים חיצוניים', _AccentGreen),
                  _buildExternalSurveysCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('בינה מלאכותית (Gemini)', _AccentLime),
                  _buildGeminiCard(),
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

  /// כרטיס פרופיל – לוגו משמאל עם עיפרון להעלאה, שם מנהל ואימייל מימין.
  Widget _buildProfileCardWithLogo() {
    return Card(
      clipBehavior: Clip.none,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // שם מנהל ואימייל מימין (ב-RTL: צד ימין של המסך)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _managerNameController,
                        focusNode: _managerNameFocusNode,
                        decoration: InputDecoration(
                          labelText: 'שם המנהל/ת',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _AccentGreen, width: 2),
                          ),
                        ),
                        onEditingComplete: _saveManagerName,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _authService.currentUser?.email ?? 'לא מחובר',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // לוגו מיושר שמאלה עם עיפרון להעלאת תמונה – יופיע גם בשאלון
                MouseRegion(
                  cursor: _logoUploading ? SystemMouseCursors.basic : SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _logoUploading ? null : _pickAndUploadLogo,
                    child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _schoolLogoUrl != null
                              ? Colors.transparent
                              : _AccentLime.withValues(alpha: 0.2),
                          border: Border.all(
                            color: _AccentGreen.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _schoolLogoUrl != null
                              ? Image.network(
                                  _schoolLogoUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 36,
                                    color: _AccentGreen,
                                  ),
                                )
                              : const Icon(Icons.school, size: 40, color: _AccentGreen),
                        ),
                      ),
                      if (_logoUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _logoUploading ? null : _pickAndUploadLogo,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AccentGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ],
            ),
            const SizedBox(height: 12),
            Tooltip(
              message: 'לוגו בית הספר – יופיע בראש טופס השאלון',
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
            ),
            if (_schoolLogoUrl != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _logoUploading ? null : _removeLogo,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('הסר לוגו'),
                style: TextButton.styleFrom(foregroundColor: _AccentRed),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadLogo() async {
    if (_logoUploading || !mounted) return;
    setState(() => _logoUploading = true);
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (xfile == null || !mounted) {
        setState(() => _logoUploading = false);
        return;
      }
      final bytes = await xfile.readAsBytes();
      final contentType = xfile.mimeType ?? 'image/jpeg';
      final url = await _firestoreService.uploadSchoolLogo(bytes, contentType);
      if (mounted) {
        setState(() {
          _schoolLogoUrl = url;
          _logoUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הלוגו עודכן בהצלחה – יופיע בראש השאלון')),
        );
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _logoUploading = false);
        debugPrint('שגיאה בהעלאת לוגו: $e');
        debugPrint('Stack trace: $st');
        final msg = e.toString().contains('BLOCKED') || e.toString().contains('blocked')
            ? 'לא ניתן לפתוח את גלריית התמונות. נסה לכבות חוסם פרסומות או להשתמש בדפדפן אחר.'
            : 'שגיאה בהעלאת לוגו: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveManagerName() async {
    FocusScope.of(context).unfocus();
    final trimmed = _managerNameController.text.trim();
    if (trimmed == _managerName) return;
    try {
      await _firestoreService.updateSchoolManagerName(trimmed);
      if (mounted) {
        setState(() => _managerName = trimmed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שם המנהל נשמר')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    try {
      await _firestoreService.clearSchoolLogo();
      if (mounted) {
        setState(() => _schoolLogoUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הלוגו הוסר')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildGoalsCard() {
    return Card(
      clipBehavior: Clip.none,
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
      clipBehavior: Clip.none,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_CardRadius)),
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                  width: 120,
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
                  width: 120,
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
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.person_add, color: _AccentAmber, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('פגוש מורים חדשים')),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    initialValue: _settings.ruleMeetNewTeachersMonths,
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
                              _saveSettings(_settings.copyWith(ruleMeetNewTeachersMonths: v));
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
      clipBehavior: Clip.none,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: _notificationFieldHeight,
              width: 110,
              child: DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              height: _notificationFieldHeight,
              width: 100,
              child: TextFormField(
                initialValue: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      clipBehavior: Clip.none,
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

  Widget _buildTeachersManagementCard() {
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
                Icon(Icons.group_add, color: _AccentRedDark, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ניהול צוות המורים',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'הוסף מורים חדשים/ות לצוות הבית ספרי.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const AddTeacherScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('הוסף מורה חדש/ה'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _AccentRedDark,
                  side: const BorderSide(color: _AccentRedDark),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
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
                    'קישור כללי לשאלון מעורבות – לשליחה לקבוצת הצוות',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'כל מורה נכנס, כותב את שמו המלא, ממלא ושולח – והנתונים נכנסים לאפליקציה.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final link = await _firestoreService.getOrCreateSchoolFormLink();
                    await Clipboard.setData(ClipboardData(text: link));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('הקישור הועתק ללוח. שלחי לקבוצת הצוות.')),
                      );
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

  Widget _buildExternalSurveysCard() {
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
                Icon(Icons.quiz, color: _AccentGreen, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'שאלונים חיצוניים',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'צרי שאלונים מותאמים אישית (אקלים, רווחה וכו\') והפיצי קישור לצוות. התשובות יישמרו בכרטיסי המורים.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExternalSurveysScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: const Text('נהל שאלונים חיצוניים'),
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

  Widget _buildGeminiCard() {
    final monthKey =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final usageCount = _settings.geminiUsageMonth == monthKey
        ? _settings.geminiUsageCount
        : 0;
    final limit = _settings.geminiUsageLimitPerMonth;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_CardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: _AccentLime, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ניסוח הודעות והמלצות מותאמות',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'משתמש ב-Firebase AI Logic – מחובר לחשבון Google של הפרויקט. המכסה החודשית מגבילה את השימוש.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.speed, color: _AccentLime, size: 20),
                const SizedBox(width: 8),
                Text(
                  'מכסה: $usageCount / $limit בקשות לחודש',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r'מכסה מומלצת: 50–100 בקשות לחודש (כ־$0.50–1 לחודש)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: '$limit',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'מכסה לחודש',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1 && n <= 500) {
                    _saveSettings(
                      _settings.copyWith(geminiUsageLimitPerMonth: n),
                    );
                  }
                },
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
