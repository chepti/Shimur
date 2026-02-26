import 'dart:typed_data';

import 'package:excel/excel.dart';
import '../models/external_survey.dart';
import '../models/teacher.dart';

/// שירות לייצוא תוצאות שאלונים חיצוניים לאקסל
class ExternalSurveyExportService {
  /// מייצר קובץ Excel מתוצאות השאלון ומחזיר את הבייטים
  static Uint8List exportToExcel({
    required ExternalSurvey survey,
    required List<Teacher> teachersWithResponses,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'תוצאות');
    final sheet = excel['תוצאות'];

    // כותרת ראשית
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('תוצאות שאלון: ${survey.title}');
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('Z1'));

    // שורת כותרות: שם מורה + כל שאלה
    final headers = ['שם מורה', ...survey.questions.map((q) => q.text)];
    for (var col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1)).value = TextCellValue(headers[col]);
    }

    // שורות נתונים
    for (var rowIdx = 0; rowIdx < teachersWithResponses.length; rowIdx++) {
      final teacher = teachersWithResponses[rowIdx];
      final responses = teacher.externalSurveys[survey.id] ?? {};

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx + 2)).value = TextCellValue(teacher.name);

      for (var qIdx = 0; qIdx < survey.questions.length; qIdx++) {
        final question = survey.questions[qIdx];
        final response = responses[question.id];
        final cellValue = _formatResponseForExcel(response);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: qIdx + 1, rowIndex: rowIdx + 2)).value = cellValue;
      }
    }

    // התאמת רוחב עמודות
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 20);
    }

    sheet.isRTL = true;

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('שגיאה ביצירת קובץ Excel');
    }
    return Uint8List.fromList(bytes);
  }

  static CellValue _formatResponseForExcel(dynamic response) {
    if (response == null) return TextCellValue('');
    if (response is int) return IntCellValue(response);
    if (response is double) return DoubleCellValue(response);
    if (response is List) {
      return TextCellValue(response.map((e) => e.toString()).join(', '));
    }
    return TextCellValue(response.toString());
  }

  /// שם קובץ מוצע לפי כותרת השאלון
  static String suggestedFileName(ExternalSurvey survey) {
    final safeTitle = survey.title.replaceAll(RegExp(r'[^\w\s\u0590-\u05FF\-]'), '').trim();
    return 'תוצאות_$safeTitle.xlsx';
  }
}
