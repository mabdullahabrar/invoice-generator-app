import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/currency_utils.dart';

/// Holds all app/company configuration (Settings screen) and is
/// responsible for auto-generating sequential invoice numbers.
///
/// Extends [ChangeNotifier] so screens (dashboard, invoice form, dark
/// mode toggle) update live via [Provider] the moment a setting changes,
/// without needing to manually refresh each other.
///
/// The company logo is stored as base64-encoded bytes (not a file
/// path) — Web has no filesystem to point a path at, so bytes are the
/// only representation that works identically everywhere.
class SettingsService extends ChangeNotifier {
  SharedPreferences? _prefs;

  String companyName = '';
  String companyAddress = '';
  String companyEmail = '';
  String companyPhone = '';
  String? _logoBase64;
  String currencyCode = 'USD';
  double defaultTaxPercent = 0;
  String invoicePrefix = 'INV-';
  int nextSequence = 1;
  bool darkMode = false;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Uint8List? get logoBytes =>
      _logoBase64 == null ? null : base64Decode(_logoBase64!);

  CurrencyOption get currency => currencyFromCode(currencyCode);

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    companyName = prefs.getString(AppConstants.prefsCompanyName) ?? '';
    companyAddress = prefs.getString(AppConstants.prefsCompanyAddress) ?? '';
    companyEmail = prefs.getString(AppConstants.prefsCompanyEmail) ?? '';
    companyPhone = prefs.getString(AppConstants.prefsCompanyPhone) ?? '';
    _logoBase64 = prefs.getString(AppConstants.prefsLogoBase64);
    currencyCode = prefs.getString(AppConstants.prefsCurrencyCode) ?? 'USD';
    defaultTaxPercent =
        prefs.getDouble(AppConstants.prefsDefaultTaxPercent) ?? 0;
    invoicePrefix =
        prefs.getString(AppConstants.prefsInvoicePrefix) ?? 'INV-';
    nextSequence = prefs.getInt(AppConstants.prefsNextSequence) ?? 1;
    darkMode = prefs.getBool(AppConstants.prefsDarkMode) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> saveCompanyDetails({
    required String companyName,
    required String companyAddress,
    required String companyEmail,
    required String companyPhone,
    Uint8List? logoBytes,
    required String currencyCode,
    required double defaultTaxPercent,
    required String invoicePrefix,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    this.companyName = companyName;
    this.companyAddress = companyAddress;
    this.companyEmail = companyEmail;
    this.companyPhone = companyPhone;
    this.currencyCode = currencyCode;
    this.defaultTaxPercent = defaultTaxPercent;
    this.invoicePrefix = invoicePrefix;

    await prefs.setString(AppConstants.prefsCompanyName, companyName);
    await prefs.setString(AppConstants.prefsCompanyAddress, companyAddress);
    await prefs.setString(AppConstants.prefsCompanyEmail, companyEmail);
    await prefs.setString(AppConstants.prefsCompanyPhone, companyPhone);

    if (logoBytes != null) {
      _logoBase64 = base64Encode(logoBytes);
      await prefs.setString(AppConstants.prefsLogoBase64, _logoBase64!);
    }

    await prefs.setString(AppConstants.prefsCurrencyCode, currencyCode);
    await prefs.setDouble(
        AppConstants.prefsDefaultTaxPercent, defaultTaxPercent);
    await prefs.setString(AppConstants.prefsInvoicePrefix, invoicePrefix);

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(AppConstants.prefsDarkMode, value);
    notifyListeners();
  }

  /// Preview of what the next invoice number would be, WITHOUT
  /// reserving/incrementing it. Safe to call every time the create-
  /// invoice form rebuilds.
  String previewNextInvoiceNumber() {
    final padded = nextSequence.toString().padLeft(3, '0');
    return '$invoicePrefix$padded';
  }

  /// Reserves the current sequence number and increments the stored
  /// counter. Call this only when an invoice is actually saved, so
  /// cancelled/abandoned forms don't burn a number and leave a gap.
  Future<String> commitNextInvoiceNumber() async {
    final number = previewNextInvoiceNumber();
    nextSequence += 1;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setInt(AppConstants.prefsNextSequence, nextSequence);
    notifyListeners();
    return number;
  }
}
