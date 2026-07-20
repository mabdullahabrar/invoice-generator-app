import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/settings_service.dart';
import '../utils/currency_utils.dart';

/// Builds the actual PDF bytes for an invoice. Kept separate from
/// [PdfService] (which handles saving/sharing/printing) so the document
/// layout logic can be tested/tweaked independently.
class InvoicePdfGenerator {
  static Future<Uint8List> generate(
      Invoice invoice, SettingsService settings) async {
    final doc = pw.Document();
    final currencySymbol = settings.currency.symbol;
    final dateFormat = DateFormat('MMM d, yyyy');

    pw.MemoryImage? logoImage;
    final logoBytes = settings.logoBytes;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    final primary = PdfColor.fromInt(0xFF1657C3);
    final grey = PdfColor.fromInt(0xFF6B7280);
    final lightGrey = PdfColor.fromInt(0xFFF1F3F7);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header: logo + business info on left, invoice title on right
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 56,
                        height: 56,
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                    pw.Text(
                      invoice.businessName.isEmpty
                          ? 'Your Business'
                          : invoice.businessName,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    if (invoice.businessAddress.isNotEmpty)
                      pw.Text(invoice.businessAddress,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                    if (invoice.businessEmail.isNotEmpty)
                      pw.Text(invoice.businessEmail,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                    if (invoice.businessPhone.isNotEmpty)
                      pw.Text(invoice.businessPhone,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(invoice.invoiceNumber,
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Invoice Date: ${dateFormat.format(invoice.invoiceDate)}',
                      style: pw.TextStyle(fontSize: 9, color: grey)),
                  pw.Text('Due Date: ${dateFormat.format(invoice.dueDate)}',
                      style: pw.TextStyle(fontSize: 9, color: grey)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _statusColor(invoice.status),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      invoice.status.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: lightGrey, thickness: 1.2),
          pw.SizedBox(height: 16),

          // Bill To
          pw.Text('BILL TO',
              style: pw.TextStyle(
                  fontSize: 9, color: grey, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            invoice.customerName.isEmpty ? 'Customer' : invoice.customerName,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (invoice.customerAddress.isNotEmpty)
            pw.Text(invoice.customerAddress,
                style: pw.TextStyle(fontSize: 9, color: grey)),
          if (invoice.customerEmail.isNotEmpty)
            pw.Text(invoice.customerEmail,
                style: pw.TextStyle(fontSize: 9, color: grey)),
          if (invoice.customerPhone.isNotEmpty)
            pw.Text(invoice.customerPhone,
                style: pw.TextStyle(fontSize: 9, color: grey)),

          pw.SizedBox(height: 20),

          // Items table
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(3.2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.3),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primary),
                children: [
                  _headerCell('Item'),
                  _headerCell('Qty'),
                  _headerCell('Unit Price'),
                  _headerCell('Disc.'),
                  _headerCell('Amount', align: pw.TextAlign.right),
                ],
              ),
              for (final item in invoice.items)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  children: [
                    _bodyCell(item.name),
                    _bodyCell(_trimZeros(item.quantity)),
                    _bodyCell(formatCurrency(item.unitPrice, currencySymbol)),
                    _bodyCell(item.discountPercent > 0
                        ? '${_trimZeros(item.discountPercent)}%'
                        : '-'),
                    _bodyCell(
                      formatCurrency(item.lineTotal, currencySymbol),
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 220,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal',
                        formatCurrency(invoice.subtotal, currencySymbol)),
                    _totalRow(
                      'Tax (${_trimZeros(invoice.taxPercent)}%)',
                      formatCurrency(invoice.taxAmount, currencySymbol),
                    ),
                    pw.Divider(color: PdfColors.grey400),
                    _totalRow(
                      'Grand Total',
                      formatCurrency(invoice.grandTotal, currencySymbol),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('NOTES / PAYMENT INSTRUCTIONS',
                style: pw.TextStyle(
                    fontSize: 9,
                    color: grey,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 10)),
          ],

          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(fontSize: 9, color: grey),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _headerCell(String text, {pw.TextAlign? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align ?? pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _bodyCell(String text, {pw.TextAlign? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      child: pw.Text(
        text,
        textAlign: align ?? pw.TextAlign.left,
        style: const pw.TextStyle(fontSize: 9.5),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColor.fromInt(0xFF1E8E5A);
      case 'overdue':
        return PdfColor.fromInt(0xFFD03A3A);
      case 'unpaid':
      default:
        return PdfColor.fromInt(0xFFE08A00);
    }
  }

  static String _trimZeros(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
