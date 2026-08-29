/// Formats monetary amounts with the DH suffix (Moroccan Dirhams).
/// Always uses Western Arabic digits (0-9), never Eastern Arabic (٠-٩).
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Returns formatted price like "100.50 DH" or "250 DH"
  static String format(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} DH';
    }
    return '${amount.toStringAsFixed(2)} DH';
  }

  /// Always shows two decimal places: "100.00 DH"
  static String formatFixed(double amount) {
    return '${amount.toStringAsFixed(2)} DH';
  }

  /// Parses a DH string back to a double
  static double parse(String value) {
    final cleaned = value.replaceAll(' DH', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
}
