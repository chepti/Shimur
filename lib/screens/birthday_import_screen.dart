import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/teacher.dart';
import '../services/firestore_service.dart';
import '../utils/birthday_utils.dart';

/// מסך ייבוא ימי הולדת – העלאת קובץ או הדבקת רשימה (שם, תאריך).
/// פורמט: שם\tתאריך או שם,תאריך. תאריך: dd.MM או dd.MM.yyyy (לועזי) או עברי בפורמט חופשי (נזהה לפי חודש עברי).
class BirthdayImportScreen extends StatefulWidget {
  const BirthdayImportScreen({super.key});

  @override
  State<BirthdayImportScreen> createState() => _BirthdayImportScreenState();
}

class _BirthdayImportScreenState extends State<BirthdayImportScreen> {
  final _firestoreService = FirestoreService();
  final _pasteController = TextEditingController();
  bool _useHebrew = false;
  bool _isLoading = false;
  String _resultMessage = '';

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickAndParseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        setState(() {
          _isLoading = false;
          _resultMessage = 'לא ניתן לקרוא את הקובץ (Web: העלאה מוגבלת)';
        });
        return;
      }

      final text = utf8.decode(bytes);
      final rows = _parseText(text);
      await _applyBirthdays(rows);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resultMessage = 'שגיאה: $e';
        });
      }
    }
  }

  Future<void> _applyFromPaste() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() => _resultMessage = 'הדביקי רשימה (שם, תאריך)');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final rows = _parseText(text);
      await _applyBirthdays(rows);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resultMessage = 'שגיאה: $e';
        });
      }
    }
  }

  List<({String name, String birthday})> _parseText(String text) {
    final rows = <({String name, String birthday})>[];
    final lines = text.split(RegExp(r'[\r\n]+'));

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      String? name;
      String? dateStr;

      final commaParts = trimmed.split(RegExp(r'[\t,;]+'));
      if (commaParts.length >= 2) {
        name = commaParts[0].trim();
        dateStr = commaParts.sublist(1).join(' ').trim();
      } else {
        final dateAtEnd = RegExp(r'^(.+)\s+(\d+[./]\d+([./]\d+)?|\d+\s*-\s*\d+)\s*$');
        final m = dateAtEnd.firstMatch(trimmed);
        if (m != null) {
          name = m.group(1)!.trim();
          dateStr = m.group(2)!.replaceAll(' ', '');
        }
      }

      if (name == null || dateStr == null || name.isEmpty || dateStr.isEmpty) continue;

      final birthday = _parseDateString(dateStr);
      if (birthday != null) {
        rows.add((name: name, birthday: birthday));
      }
    }
    return rows;
  }

  String? _parseDateString(String s) {
    if (_useHebrew) {
      return _parseHebrewDate(s);
    }
    return _parseGregorianDate(s);
  }

  String? _parseGregorianDate(String s) {
    final parts = s.split(RegExp(r'[./\-]'));
    if (parts.length < 2) return null;
    final day = int.tryParse(parts[0].trim());
    final month = int.tryParse(parts[1].trim());
    if (day == null || month == null || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    return BirthdayUtils.fromGregorian(DateTime(2000, month, day));
  }

  String? _parseHebrewDate(String s) {
    final hebrewMonths = {
      'ניסן': 1, 'אייר': 2, 'סיוון': 3, 'סיון': 3, 'תמוז': 4, 'אב': 5,
      'אלול': 6, 'תשרי': 7, 'חשון': 8, 'חשוון': 8, 'כסלו': 9, 'טבת': 10,
      'שבט': 11, 'אדר': 12, 'אדר א': 12, 'אדר ב': 13, 'אדר ב\'': 13,
    };
    for (final entry in hebrewMonths.entries) {
      if (s.contains(entry.key)) {
        final dayMatch = RegExp(r'\d+').firstMatch(s);
        final day = dayMatch != null ? int.tryParse(dayMatch.group(0)!) : null;
        if (day != null && day >= 1 && day <= 30) {
          return BirthdayUtils.fromHebrew(entry.value, day);
        }
      }
    }
    final parts = s.split(RegExp(r'[.\-]'));
    if (parts.length >= 2) {
      final day = int.tryParse(parts[0].trim());
      final month = int.tryParse(parts[1].trim());
      if (day != null && month != null && month >= 1 && month <= 13 && day >= 1 && day <= 30) {
        return BirthdayUtils.fromHebrew(month, day);
      }
    }
    return null;
  }

  List<Teacher> _findMatchingTeachers(
    List<Teacher> teachers,
    String inputName,
  ) {
    final inputNorm = _normalizeName(inputName);
    final exact = teachers.where((t) =>
        _normalizeName(t.name) == inputNorm).toList();
    if (exact.isNotEmpty) return exact;

    final inputWords = inputNorm.split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
    return teachers.where((t) {
      final teacherWords = _normalizeName(t.name).split(RegExp(r'\s+')).where((w) => w.length > 1).toSet();
      final common = inputWords.intersection(teacherWords).length;
      return common >= inputWords.length || common >= teacherWords.length;
    }).toList();
  }

  String _normalizeName(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _applyBirthdays(List<({String name, String birthday})> rows) async {
    final teachers = await _firestoreService.getTeachersStream().first;
    int updated = 0;
    int notFound = 0;
    final List<String> ambiguous = [];

    for (final row in rows) {
      final candidates = _findMatchingTeachers(teachers, row.name);

      if (candidates.isEmpty) {
        notFound++;
        ambiguous.add('${row.name} – לא נמצא מורה תואם');
        continue;
      }

      if (candidates.length == 1) {
        await _firestoreService.updateTeacher(
            candidates.single.copyWith(birthday: row.birthday));
        updated++;
        continue;
      }

      final exact = candidates.where((t) =>
          _normalizeName(t.name) == _normalizeName(row.name)).toList();
      if (exact.isNotEmpty) {
        for (final t in exact) {
          await _firestoreService.updateTeacher(t.copyWith(birthday: row.birthday));
          updated++;
        }
        continue;
      }

      if (!mounted) return;
      final chosen = await showDialog<Teacher>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('התאמת מורה'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'לא נמצאה התאמה מדויקת ל"${row.name}". האם התכוונת לאחד מהמורים הבאים?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...candidates.map((t) => ListTile(
                  dense: true,
                  title: Text(t.name),
                  onTap: () => Navigator.pop(ctx, t),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('דלג'),
              ),
            ],
          ),
        ),
      );
      if (chosen != null) {
        await _firestoreService.updateTeacher(
            chosen.copyWith(birthday: row.birthday));
        updated++;
      } else {
        notFound++;
        ambiguous.add('${row.name} – דולג');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        final msg = StringBuffer('עודכנו $updated מורים. לא נמצאו: $notFound.');
        if (ambiguous.isNotEmpty) {
          msg.write('\n\n');
          msg.write(ambiguous.join('\n'));
        }
        _resultMessage = msg.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ייבוא ימי הולדת'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'העלי טבלה או הדביקי רשימה – שם המורה ויום ההולדת.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'פורמט: שם תאריך או שם,תאריך (פסיק, טאב או רווח). תאריך לועזי: 9.3 או 15.03. תאריך עברי: ט"ו בניסן או 15-7.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('תאריך לועזי'),
                    selected: !_useHebrew,
                    onSelected: (s) => setState(() => _useHebrew = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('תאריך עברי'),
                    selected: _useHebrew,
                    onSelected: (s) => setState(() => _useHebrew = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickAndParseFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('העלה קובץ (Excel/CSV/TXT)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('או הדביקי רשימה:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pasteController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'רחל לוי, 15.3\nדוד כהן, ט"ו בניסן',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _applyFromPaste,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('החל ימי הולדת'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11a0db),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_resultMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_resultMessage, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
