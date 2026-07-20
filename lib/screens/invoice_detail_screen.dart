import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_utils.dart';
import '../widgets/status_badge.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final PdfService _pdfService = PdfService();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  Invoice? _invoice;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final invoice = await _invoiceService.getInvoiceById(widget.invoiceId);
    if (!mounted) return;
    setState(() {
      _invoice = invoice;
      _loading = false;
    });
  }

  Future<void> _changeStatus(String status) async {
    final invoice = _invoice;
    if (invoice == null) return;
    await _invoiceService.updateStatus(invoice, status);
    _load();
  }

  Future<void> _confirmDelete() async {
    final invoice = _invoice;
    if (invoice == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          'This will permanently delete invoice ${invoice.invoiceNumber}. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && invoice.id != null) {
      await _invoiceService.deleteInvoice(invoice.id!);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _duplicate() async {
    final invoice = _invoice;
    if (invoice == null) return;
    setState(() => _busy = true);
    final settings = context.read<SettingsService>();
    final duplicate =
        await _invoiceService.duplicateInvoice(invoice, settings);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated as ${duplicate.invoiceNumber}')),
    );
  }

  Future<void> _exportPdf() async {
    final invoice = _invoice;
    if (invoice == null) return;
    setState(() => _busy = true);
    try {
      final settings = context.read<SettingsService>();
      await _pdfService.savePdf(invoice, settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF ready — check your downloads or share sheet')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    final invoice = _invoice;
    if (invoice == null) return;
    setState(() => _busy = true);
    try {
      final settings = context.read<SettingsService>();
      await _pdfService.sharePdf(invoice, settings);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _printPdf() async {
    final invoice = _invoice;
    if (invoice == null) return;
    setState(() => _busy = true);
    try {
      final settings = context.read<SettingsService>();
      await _pdfService.printPdf(invoice, settings);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not print: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final symbol = settings.currency.symbol;
    final invoice = _invoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice?.invoiceNumber ?? 'Invoice'),
        actions: [
          if (invoice != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.of(context)
                        .push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoiceFormScreen(invoiceToEdit: invoice),
                          ),
                        )
                        .then((updated) {
                      if (updated == true) _load();
                    });
                    break;
                  case 'duplicate':
                    _duplicate();
                    break;
                  case 'delete':
                    _confirmDelete();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : invoice == null
              ? const Center(child: Text('Invoice not found'))
              : AbsorbPointer(
                  absorbing: _busy,
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _StatusRow(
                            status: invoice.status,
                            onChanged: _changeStatus,
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice.businessName.isEmpty
                                                  ? 'Your Business'
                                                  : invoice.businessName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (invoice
                                                .businessAddress.isNotEmpty)
                                              Text(invoice.businessAddress,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            if (invoice
                                                .businessEmail.isNotEmpty)
                                              Text(invoice.businessEmail,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                            if (invoice
                                                .businessPhone.isNotEmpty)
                                              Text(invoice.businessPhone,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Invoice: ${_dateFormat.format(invoice.invoiceDate)}',
                                            style: const TextStyle(
                                                fontSize: 11.5),
                                          ),
                                          Text(
                                            'Due: ${_dateFormat.format(invoice.dueDate)}',
                                            style: const TextStyle(
                                                fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 28),
                                  const Text(
                                    'BILL TO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    invoice.customerName.isEmpty
                                        ? 'No customer name'
                                        : invoice.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (invoice.customerAddress.isNotEmpty)
                                    Text(invoice.customerAddress,
                                        style:
                                            const TextStyle(fontSize: 12)),
                                  if (invoice.customerEmail.isNotEmpty)
                                    Text(invoice.customerEmail,
                                        style:
                                            const TextStyle(fontSize: 12)),
                                  if (invoice.customerPhone.isNotEmpty)
                                    Text(invoice.customerPhone,
                                        style:
                                            const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Items',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 20,
                                      headingRowHeight: 36,
                                      dataRowMinHeight: 40,
                                      dataRowMaxHeight: 52,
                                      columns: const [
                                        DataColumn(label: Text('Item')),
                                        DataColumn(label: Text('Qty')),
                                        DataColumn(label: Text('Price')),
                                        DataColumn(label: Text('Disc.')),
                                        DataColumn(label: Text('Total')),
                                      ],
                                      rows: invoice.items.map((item) {
                                        return DataRow(cells: [
                                          DataCell(Text(item.name)),
                                          DataCell(Text(
                                              _trimZeros(item.quantity))),
                                          DataCell(Text(formatCurrency(
                                              item.unitPrice, symbol))),
                                          DataCell(Text(
                                            item.discountPercent > 0
                                                ? '${_trimZeros(item.discountPercent)}%'
                                                : '-',
                                          )),
                                          DataCell(Text(formatCurrency(
                                              item.lineTotal, symbol))),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                  const Divider(height: 28),
                                  _totalRow('Subtotal',
                                      formatCurrency(invoice.subtotal, symbol)),
                                  const SizedBox(height: 6),
                                  _totalRow(
                                    'Tax (${_trimZeros(invoice.taxPercent)}%)',
                                    formatCurrency(
                                        invoice.taxAmount, symbol),
                                  ),
                                  const Divider(height: 20),
                                  _totalRow(
                                    'Grand Total',
                                    formatCurrency(
                                        invoice.grandTotal, symbol),
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (invoice.notes.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Notes / Payment Instructions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(invoice.notes,
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _exportPdf,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Download PDF'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _sharePdf,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _printPdf,
                              icon: const Icon(Icons.print),
                              label: const Text('Print'),
                            ),
                          ),
                        ],
                      ),
                      if (_busy)
                        Container(
                          color: Colors.black.withOpacity(0.05),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _trimZeros(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final ValueChanged<String> onChanged;

  const _StatusRow({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            StatusBadge(status: status),
            const Spacer(),
            DropdownButton<String>(
              value: status,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
              ],
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
