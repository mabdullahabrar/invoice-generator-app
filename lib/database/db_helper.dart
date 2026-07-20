import 'package:hive_flutter/hive_flutter.dart';
import '../models/invoice.dart';

/// Local storage layer, backed by Hive.
///
/// Hive was chosen over sqflite specifically because it's pure Dart and
/// has a real Web implementation (via IndexedDB) in addition to mobile/
/// desktop — sqflite only works on Android/iOS/desktop and would fail
/// to run at all in a browser.
///
/// Hive's `box.add()` assigns sequential integer keys automatically,
/// which we use as the invoice's `id` — the same role SQLite's
/// AUTOINCREMENT primary key would have played.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static const String boxName = 'invoices_box';
  Box? _box;

  Future<Box> _openBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  Future<int> insertInvoice(Invoice invoice) async {
    final box = await _openBox();
    final int key = await box.add(invoice.toJson());
    // Keep the stored record's id in sync with the assigned key.
    final map = invoice.toJson();
    map['id'] = key;
    await box.put(key, map);
    return key;
  }

  Future<int> updateInvoice(Invoice invoice) async {
    if (invoice.id == null) return 0;
    final box = await _openBox();
    await box.put(invoice.id, invoice.toJson());
    return 1;
  }

  Future<int> deleteInvoice(int id) async {
    final box = await _openBox();
    await box.delete(id);
    return 1;
  }

  Future<List<Invoice>> getAllInvoices() async {
    final box = await _openBox();
    final invoices = box.keys.map((key) {
      final raw = box.get(key);
      final map = Map<String, dynamic>.from(raw as Map);
      map['id'] = key;
      return Invoice.fromJson(map);
    }).toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw as Map);
    map['id'] = id;
    return Invoice.fromJson(map);
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final all = await getAllInvoices();
    final lower = query.toLowerCase();
    return all
        .where((inv) =>
            inv.invoiceNumber.toLowerCase().contains(lower) ||
            inv.customerName.toLowerCase().contains(lower))
        .toList();
  }

  Future<int> countInvoices() async {
    final box = await _openBox();
    return box.length;
  }
}
