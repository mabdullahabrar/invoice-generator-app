import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_utils.dart';
import '../utils/validators.dart';
import '../widgets/invoice_item_form_row.dart';

/// Create/edit form for an invoice. Pass [invoiceToEdit] to edit an
/// existing invoice; leave it null to create a new one.
class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;

  const InvoiceFormScreen({super.key, this.invoiceToEdit});

  bool get isEditing => invoiceToEdit != null;

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final InvoiceService _invoiceService = InvoiceService();
  final Uuid _uuid = const Uuid();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  late String _invoiceNumberPreview;
  late DateTime _invoiceDate;
  late DateTime _dueDate;

  final _businessNameCtrl = TextEditingController();
  final _businessAddressCtrl = TextEditingController();
  final _businessEmailCtrl = TextEditingController();
  final _businessPhoneCtrl = TextEditingController();

  final _customerNameCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();

  final _taxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late List<InvoiceItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    final existing = widget.invoiceToEdit;

    if (existing != null) {
      _invoiceNumberPreview = existing.invoiceNumber;
      _invoiceDate = existing.invoiceDate;
      _dueDate = existing.dueDate;

      _businessNameCtrl.text = existing.businessName;
      _businessAddressCtrl.text = existing.businessAddress;
      _businessEmailCtrl.text = existing.businessEmail;
      _businessPhoneCtrl.text = existing.businessPhone;

      _customerNameCtrl.text = existing.customerName;
      _customerAddressCtrl.text = existing.customerAddress;
      _customerEmailCtrl.text = existing.customerEmail;
      _customerPhoneCtrl.text = existing.customerPhone;

      _taxCtrl.text = _trimZeros(existing.taxPercent);
      _notesCtrl.text = existing.notes;

      _items = existing.items.map((e) => e.copyWith()).toList();
    } else {
      _invoiceNumberPreview = settings.previewNextInvoiceNumber();
      _invoiceDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 30));

      _businessNameCtrl.text = settings.companyName;
      _businessAddressCtrl.text = settings.companyAddress;
      _businessEmailCtrl.text = settings.companyEmail;
      _businessPhoneCtrl.text = settings.companyPhone;

      _taxCtrl.text = _trimZeros(settings.defaultTaxPercent);

      _items = [
        InvoiceItem(id: _uuid.v4(), name: '', quantity: 1, unitPrice: 0),
      ];
    }
  }

  String _trimZeros(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    _businessEmailCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _customerEmailCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get _taxPercent => double.tryParse(_taxCtrl.text.trim()) ?? 0;
  double get _taxAmount => _subtotal * (_taxPercent / 100);
  double get _grandTotal => _subtotal + _taxAmount;

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(id: _uuid.v4(), name: '', quantity: 1, unitPrice: 0));
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  void _updateItem(InvoiceItem updated) {
    final index = _items.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      setState(() => _items[index] = updated);
    }
  }

  Future<void> _pickDate({required bool isInvoiceDate}) async {
    final initial = isInvoiceDate ? _invoiceDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product or service')),
      );
      return;
    }
    if (!formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors above')),
      );
      return;
    }

    setState(() => _saving = true);
    final settings = context.read<SettingsService>();

    try {
      if (widget.isEditing) {
        final updated = widget.invoiceToEdit!.copyWith(
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          businessName: _businessNameCtrl.text.trim(),
          businessAddress: _businessAddressCtrl.text.trim(),
          businessEmail: _businessEmailCtrl.text.trim(),
          businessPhone: _businessPhoneCtrl.text.trim(),
          customerName: _customerNameCtrl.text.trim(),
          customerAddress: _customerAddressCtrl.text.trim(),
          customerEmail: _customerEmailCtrl.text.trim(),
          customerPhone: _customerPhoneCtrl.text.trim(),
          items: _items,
          taxPercent: _taxPercent,
          notes: _notesCtrl.text.trim(),
        );
        await _invoiceService.updateInvoice(updated);
      } else {
        final invoiceNumber = await settings.commitNextInvoiceNumber();
        final newInvoice = Invoice(
          invoiceNumber: invoiceNumber,
          invoiceDate: _invoiceDate,
          dueDate: _dueDate,
          businessName: _businessNameCtrl.text.trim(),
          businessAddress: _businessAddressCtrl.text.trim(),
          businessEmail: _businessEmailCtrl.text.trim(),
          businessPhone: _businessPhoneCtrl.text.trim(),
          customerName: _customerNameCtrl.text.trim(),
          customerAddress: _customerAddressCtrl.text.trim(),
          customerEmail: _customerEmailCtrl.text.trim(),
          customerPhone: _customerPhoneCtrl.text.trim(),
          items: _items,
          taxPercent: _taxPercent,
          notes: _notesCtrl.text.trim(),
          status: 'Unpaid',
        );
        await _invoiceService.createInvoice(newInvoice);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final symbol = settings.currency.symbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _SectionCard(
              title: 'Invoice Details',
              children: [
                _ReadOnlyField(
                  label: 'Invoice Number',
                  value: _invoiceNumberPreview,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'Invoice Date',
                        value: _dateFormat.format(_invoiceDate),
                        onTap: () => _pickDate(isInvoiceDate: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'Due Date',
                        value: _dateFormat.format(_dueDate),
                        onTap: () => _pickDate(isInvoiceDate: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Business Information',
              children: [
                TextFormField(
                  controller: _businessNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Company Name'),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Company name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessAddressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _businessPhoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Customer Information',
              children: [
                TextFormField(
                  controller: _customerNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Customer Name'),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Customer name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerAddressCtrl,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (v) =>
                      Validators.required(v, fieldName: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerEmailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerPhoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Products / Services',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in _items)
              InvoiceItemFormRow(
                key: ValueKey(item.id),
                item: item,
                currencySymbol: symbol,
                onChanged: _updateItem,
                onRemove: () => _removeItem(item.id),
                canRemove: _items.length > 1,
              ),
            const SizedBox(height: 8),
            _SectionCard(
              title: 'Tax',
              children: [
                TextFormField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Percentage (%)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.percentage,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TotalsCard(
              subtotal: _subtotal,
              taxPercent: _taxPercent,
              taxAmount: _taxAmount,
              grandTotal: _grandTotal,
              symbol: symbol,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Notes / Payment Instructions',
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'e.g. Bank details, payment terms...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.isEditing ? 'Update Invoice' : 'Save Invoice'),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double grandTotal;
  final String symbol;

  const _TotalsCard({
    required this.subtotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.grandTotal,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, 'Subtotal', formatCurrency(subtotal, symbol)),
            const SizedBox(height: 8),
            _row(
              context,
              'Tax (${taxPercent.toStringAsFixed(taxPercent == taxPercent.roundToDouble() ? 0 : 2)}%)',
              formatCurrency(taxAmount, symbol),
            ),
            const Divider(height: 24),
            _row(
              context,
              'Grand Total',
              formatCurrency(grandTotal, symbol),
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
