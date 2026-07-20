/// App-wide constant values, kept in one place to avoid magic
/// strings/numbers scattered across screens.
class AppConstants {
  AppConstants._();

  static const String appName = 'Invoice Generator';

  static const List<String> statusOptions = ['Unpaid', 'Paid', 'Overdue'];

  static const String prefsCompanyName = 'companyName';
  static const String prefsCompanyAddress = 'companyAddress';
  static const String prefsCompanyEmail = 'companyEmail';
  static const String prefsCompanyPhone = 'companyPhone';

  // Stored as base64 text (not a file path) so it works identically on
  // Web, where there's no filesystem to point a path at.
  static const String prefsLogoBase64 = 'logoBase64';

  static const String prefsCurrencyCode = 'currencyCode';
  static const String prefsDefaultTaxPercent = 'defaultTaxPercent';
  static const String prefsInvoicePrefix = 'invoicePrefix';
  static const String prefsNextSequence = 'nextSequence';
  static const String prefsDarkMode = 'darkMode';
}
