import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../pdf/invoice_pdf_generator.dart';
import 'settings_service.dart';

/// Handles what happens to a generated PDF: downloading/saving it,
/// sharing it through the OS share sheet, or sending it to a printer.
///
/// Deliberately built entirely on byte arrays (never a file path) so
/// every operation here works identically on Web — where there is no
/// filesystem — and on Android/iOS/desktop.
class PdfService {
  Future<Uint8List> buildPdfBytes(Invoice invoice, SettingsService settings) {
    return InvoicePdfGenerator.generate(invoice, settings);
  }

  String _fileNameFor(Invoice invoice) {
    final safeNumber = invoice.invoiceNumber.replaceAll(
      RegExp(r'[^A-Za-z0-9\-_]'),
      '_',
    );
    return '$safeNumber.pdf';
  }

  /// Cross-platform "save/download": on Web this triggers a normal
  /// browser file download; on Android/iOS it opens the native
  /// save/share sheet. There's no single "silently write to disk" API
  /// that exists on both platforms, so this is the standard equivalent
  /// (provided directly by the `printing` package).
  Future<void> savePdf(Invoice invoice, SettingsService settings) async {
    final bytes = await buildPdfBytes(invoice, settings);
    await Printing.sharePdf(bytes: bytes, filename: _fileNameFor(invoice));
  }

  /// Cross-platform share via the OS share sheet (WhatsApp, Email,
  /// etc. on mobile; the browser's native share dialog on Web where
  /// supported). Built from raw bytes via `XFile.fromData` rather than
  /// a file path.
  Future<void> sharePdf(Invoice invoice, SettingsService settings) async {
    final bytes = await buildPdfBytes(invoice, settings);
    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: _fileNameFor(invoice),
        ),
      ],
      text: 'Invoice ${invoice.invoiceNumber}',
      subject: 'Invoice ${invoice.invoiceNumber}',
    );
  }

  Future<void> printPdf(Invoice invoice, SettingsService settings) async {
    final bytes = await buildPdfBytes(invoice, settings);
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: _fileNameFor(invoice),
    );
  }
}
