import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';
import '../models/invoice.dart';

/// Handles data portability: exporting all invoices as a JSON backup,
/// restoring from a previously-saved backup file, and exporting the
/// invoice list as a CSV spreadsheet.
///
/// Everything here is byte-based (never writes to a fixed filesystem
/// path), so it works the same way on Web as it does on mobile:
/// exports go out through the OS/browser share-or-download flow, and
/// restore lets the user pick any backup file back in.
class BackupService {
  final DBHelper _db = DBHelper.instance;

  Future<void> backupAndShare() async {
    final invoices = await _db.getAllInvoices();
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'invoices': invoices.map((inv) => inv.toJson()).toList(),
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final fileName =
        'invoice_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'application/json', name: fileName)],
      text: 'Invoice Generator backup',
      subject: 'Invoice Generator backup',
    );
  }

  /// Lets the user pick a previously-saved backup JSON file (from
  /// Downloads, Drive, an email attachment, etc.) and restores its
  /// invoices as new records. Existing invoices are left untouched.
  Future<int> restoreFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final fileBytes = result.files.single.bytes;
    if (fileBytes == null) {
      throw Exception('Could not read the selected file');
    }

    final payload = jsonDecode(utf8.decode(fileBytes)) as Map<String, dynamic>;
    final list = payload['invoices'] as List<dynamic>? ?? [];

    int restored = 0;
    for (final raw in list) {
      final invoice = Invoice.fromJson(Map<String, dynamic>.from(raw as Map));
      invoice.id = null; // insert as a brand-new record
      await _db.insertInvoice(invoice);
      restored++;
    }
    return restored;
  }

  /// Builds a CSV of all invoices (one row per invoice) and shares it.
  /// Built manually with basic escaping — no extra CSV package needed
  /// for a flat export like this.
  Future<void> exportCsvAndShare() async {
    final invoices = await _db.getAllInvoices();
    final buffer = StringBuffer();
    buffer.writeln(
      'Invoice Number,Invoice Date,Due Date,Customer Name,Customer Email,'
      'Subtotal,Tax %,Grand Total,Status',
    );

    for (final inv in invoices) {
      buffer.writeln([
        _csvEscape(inv.invoiceNumber),
        _csvEscape(inv.invoiceDate.toIso8601String().split('T').first),
        _csvEscape(inv.dueDate.toIso8601String().split('T').first),
        _csvEscape(inv.customerName),
        _csvEscape(inv.customerEmail),
        inv.subtotal.toStringAsFixed(2),
        inv.taxPercent.toStringAsFixed(2),
        inv.grandTotal.toStringAsFixed(2),
        _csvEscape(inv.status),
      ].join(','));
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv', name: 'invoices_export.csv')],
      text: 'Invoice list export',
      subject: 'Invoice list export (CSV)',
    );
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
