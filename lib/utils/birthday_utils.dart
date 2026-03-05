import 'package:kosher_dart/kosher_dart.dart';

/// פורמט: "gregorian:MM-dd" או "hebrew:M-dd" (M=חודש עברי 1-13, dd=יום)
/// דוגמאות: "gregorian:03-15", "hebrew:7-15" (ט"ו בתשרי)
class BirthdayUtils {
  static const String _prefixGregorian = 'gregorian:';
  static const String _prefixHebrew = 'hebrew:';

  /// בודק אם יום ההולדת חל היום
  static bool isBirthdayToday(String? birthday) {
    if (birthday == null || birthday.isEmpty) return false;
    final now = DateTime.now();
    if (birthday.startsWith(_prefixGregorian)) {
      final part = birthday.substring(_prefixGregorian.length);
      final parts = part.split('-');
      if (parts.length != 2) return false;
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      if (month == null || day == null) return false;
      return now.month == month && now.day == day;
    }
    if (birthday.startsWith(_prefixHebrew)) {
      final part = birthday.substring(_prefixHebrew.length);
      final parts = part.split('-');
      if (parts.length != 2) return false;
      final hebrewMonth = int.tryParse(parts[0]);
      final hebrewDay = int.tryParse(parts[1]);
      if (hebrewMonth == null || hebrewDay == null) return false;
      final todayJewish = JewishDate.fromDateTime(now);
      return todayJewish.getJewishMonth() == hebrewMonth &&
          todayJewish.getJewishDayOfMonth() == hebrewDay;
    }
    return false;
  }

  /// מחזיר מספר הימים עד יום ההולדת הבא (0 = היום, שלילי = כבר עבר השנה)
  static int? daysUntilBirthday(String? birthday) {
    if (birthday == null || birthday.isEmpty) return null;
    final now = DateTime.now();
    if (birthday.startsWith(_prefixGregorian)) {
      final part = birthday.substring(_prefixGregorian.length);
      final parts = part.split('-');
      if (parts.length != 2) return null;
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      if (month == null || day == null) return null;
      var next = DateTime(now.year, month, day);
      if (next.isBefore(DateTime(now.year, now.month, now.day))) {
        next = DateTime(now.year + 1, month, day);
      }
      return next.difference(DateTime(now.year, now.month, now.day)).inDays;
    }
    if (birthday.startsWith(_prefixHebrew)) {
      final part = birthday.substring(_prefixHebrew.length);
      final parts = part.split('-');
      if (parts.length != 2) return null;
      final hebrewMonth = int.tryParse(parts[0]);
      final hebrewDay = int.tryParse(parts[1]);
      if (hebrewMonth == null || hebrewDay == null) return null;
      final todayJewish = JewishDate.fromDateTime(now);
      if (todayJewish.getJewishMonth() == hebrewMonth &&
          todayJewish.getJewishDayOfMonth() == hebrewDay) {
        return 0;
      }
      // חישוב ימים עד התאריך העברי הבא – נעבור יום־יום
      var jd = JewishDate.fromDateTime(now);
      int days = 0;
      while (days < 400) {
        if (jd.getJewishMonth() == hebrewMonth && jd.getJewishDayOfMonth() == hebrewDay) {
          return days;
        }
        jd.forward();
        days++;
      }
      return null;
    }
    return null;
  }

  /// מחזיר מחרוזת להצגה (עברי או לועזי)
  static String formatForDisplay(String? birthday) {
    if (birthday == null || birthday.isEmpty) return '';
    if (birthday.startsWith(_prefixGregorian)) {
      final part = birthday.substring(_prefixGregorian.length);
      final parts = part.split('-');
      if (parts.length != 2) return birthday;
      return '${parts[1]}.${parts[0]}'; // dd.MM
    }
    if (birthday.startsWith(_prefixHebrew)) {
      final part = birthday.substring(_prefixHebrew.length);
      final parts = part.split('-');
      if (parts.length != 2) return birthday;
      final hebrewMonth = int.tryParse(parts[0]);
      final hebrewDay = int.tryParse(parts[1]);
      if (hebrewMonth == null || hebrewDay == null) return birthday;
      final jd = JewishDate.initDate(
        jewishYear: 5785,
        jewishMonth: hebrewMonth,
        jewishDayOfMonth: hebrewDay,
      );
      final formatter = HebrewDateFormatter()
        ..hebrewFormat = true
        ..useGershGershayim = true
        ..useLongHebrewYears = false;
      return formatter.format(jd, pattern: 'dd MM');
    }
    return birthday;
  }

  /// יוצר מחרוזת מתאריך לועזי
  static String fromGregorian(DateTime date) {
    return '$_prefixGregorian${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// יוצר מחרוזת מתאריך עברי (חודש 1-13, יום)
  static String fromHebrew(int month, int day) {
    return '$_prefixHebrew$month-${day.toString().padLeft(2, '0')}';
  }

  /// בודק אם יום ההולדת חל בתוך X הימים הקרובים (כולל היום)
  static bool isBirthdayWithinDays(String? birthday, int days) {
    if (birthday == null || birthday.isEmpty) return false;
    final d = daysUntilBirthday(birthday);
    return d != null && d >= 0 && d <= days;
  }

  /// בודק אם הפורמט תקין
  static bool isValid(String? birthday) {
    if (birthday == null || birthday.isEmpty) return false;
    if (birthday.startsWith(_prefixGregorian)) {
      final part = birthday.substring(_prefixGregorian.length);
      final parts = part.split('-');
      if (parts.length != 2) return false;
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      return month != null && day != null && month >= 1 && month <= 12 && day >= 1 && day <= 31;
    }
    if (birthday.startsWith(_prefixHebrew)) {
      final part = birthday.substring(_prefixHebrew.length);
      final parts = part.split('-');
      if (parts.length != 2) return false;
      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      return month != null && day != null && month >= 1 && month <= 13 && day >= 1 && day <= 30;
    }
    return false;
  }
}
