/// A single supported currency: its ISO code, display symbol, and name.
class CurrencyOption {
  final String code;
  final String symbol;
  final String name;

  const CurrencyOption(this.code, this.symbol, this.name);
}

/// A short, practical list of currencies. Not exhaustive — but covers
/// the common ones a small business would need.
const List<CurrencyOption> kSupportedCurrencies = [
  CurrencyOption('USD', '\$', 'US Dollar'),
  CurrencyOption('EUR', '€', 'Euro'),
  CurrencyOption('GBP', '£', 'British Pound'),
  CurrencyOption('PKR', 'Rs ', 'Pakistani Rupee'),
  CurrencyOption('INR', '₹', 'Indian Rupee'),
  CurrencyOption('AED', 'AED ', 'UAE Dirham'),
  CurrencyOption('SAR', 'SAR ', 'Saudi Riyal'),
  CurrencyOption('CAD', 'CA\$', 'Canadian Dollar'),
  CurrencyOption('AUD', 'AU\$', 'Australian Dollar'),
];

CurrencyOption currencyFromCode(String code) {
  return kSupportedCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => kSupportedCurrencies.first,
  );
}

/// Formats [amount] with the given currency [symbol] and two decimal
/// places, using thousands separators (e.g. "$1,234.56").
String formatCurrency(double amount, String symbol) {
  final isNegative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final wholeDigits = parts[0];
  final decimals = parts[1];

  final buffer = StringBuffer();
  for (int i = 0; i < wholeDigits.length; i++) {
    final posFromRight = wholeDigits.length - i;
    buffer.write(wholeDigits[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) {
      buffer.write(',');
    }
  }

  final sign = isNegative ? '-' : '';
  return '$sign$symbol${buffer.toString()}.$decimals';
}
