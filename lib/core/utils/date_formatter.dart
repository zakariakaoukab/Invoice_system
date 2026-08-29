import 'package:intl/intl.dart';

/// Formats dates using Western Arabic digits (0-9) only.
/// Never produces Eastern Arabic numerals (٠١٢٣...).
class DateFormatter {
  DateFormatter._();

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'en_US');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'en_US');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');

  /// Returns date string like "28/07/2026"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Returns date+time string like "28/07/2026 22:45"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Returns month/year in French like "Juillet 2026" (for PDF headers)
  static String formatMonthYearFr(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Returns month/year abbreviated for chart labels like "Jul"
  static String formatMonthAbbr(DateTime date) {
    return DateFormat('MMM', 'en_US').format(date);
  }
}
