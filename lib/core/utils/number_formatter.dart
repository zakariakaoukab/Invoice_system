/// Utility to ensure Western Arabic numerals are used everywhere.
/// Replaces Eastern Arabic digits (٠١٢٣٤٥٦٧٨٩) with (0123456789).
class NumberFormatter {
  NumberFormatter._();

  static const Map<String, String> _easternToWestern = {
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  };

  /// Converts any Eastern Arabic digits in [text] to Western digits.
  static String toWestern(String text) {
    String result = text;
    for (final entry in _easternToWestern.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Formats an integer as a Western digit string.
  static String formatInt(int value) => value.toString();

  /// Formats a double to [decimals] places using Western digits.
  static String formatDouble(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }
}
