import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';

/// ווידג'ט אחיד להצגת תאריך עברי ולידו תאריך לועזי קטן יותר.
///
/// ברירת מחדל: יום וחודש בלבד (ללא שנה), בהתאם לעבודה שוטפת.
class HebrewGregorianDateText extends StatelessWidget {
  final DateTime date;

  /// האם להציג גם שנה (בעברי ובלועזי).
  final bool showYear;

  /// אפשרות לעקוף סגנון טקסט עברי.
  final TextStyle? hebrewStyle;

  /// אפשרות לעקוף סגנון טקסט לועזי.
  final TextStyle? gregorianStyle;

  const HebrewGregorianDateText({
    super.key,
    required this.date,
    this.showYear = false,
    this.hebrewStyle,
    this.gregorianStyle,
  });

  @override
  Widget build(BuildContext context) {
    final jewishDate = JewishDate.fromDateTime(date);
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..useGershGershayim = true
      ..useLongHebrewYears = false;

    final pattern = showYear ? 'dd MM yy' : 'dd MM';
    final hebrew = formatter.format(jewishDate, pattern: pattern);

    final gregorianPattern = showYear ? 'd.M.yyyy' : 'd.M';
    final gregorian = DateFormat(gregorianPattern).format(date);

    final baseHebrewStyle = hebrewStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            );
    final baseGregStyle = gregorianStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          hebrew,
          style: baseHebrewStyle,
        ),
        const SizedBox(width: 6),
        Text(
          gregorian,
          style: baseGregStyle,
        ),
      ],
    );
  }
}

