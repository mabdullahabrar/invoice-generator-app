import 'package:flutter/material.dart';
import '../models/invoice_item.dart';
import '../utils/currency_utils.dart';
import '../utils/validators.dart';

/// A single editable line-item row inside the invoice form.
///
/// Owns its own [TextEditingController]s (keyed by the item's stable id
/// via the parent's [ValueKey]) so editing one row never disturbs the
/// text/cursor state of the others.
class InvoiceItemFormRow extends StatefulWidget {
  final InvoiceItem item;
  final String currencySymbol;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  const InvoiceItemFormRow({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  State<InvoiceItemFormRow> createState() => _InvoiceItemFormRowState();
}

class _InvoiceItemFormRowState extends State<InvoiceItemFormRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _qtyController =
        TextEditingController(text: _trim(widget.item.quantity));
    _priceController =
        TextEditingController(text: _trim(widget.item.unitPrice));
    _discountController =
        TextEditingController(text: _trim(widget.item.discountPercent));
  }

  String _trim(double value) {
    if (value == 0) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  void _emitChange() {
    final updated = widget.item.copyWith(
      name: _nameController.text,
      quantity: double.tryParse(_qtyController.text.trim()) ?? 0,
      unitPrice: double.tryParse(_priceController.text.trim()) ?? 0,
      discountPercent:
          double.tryParse(_discountController.text.trim()) ?? 0,
    );
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineTotal = (double.tryParse(_qtyController.text.trim()) ?? 0) *
        (double.tryParse(_priceController.text.trim()) ?? 0) *
        (1 - (double.tryParse(_discountController.text.trim()) ?? 0) / 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product / Service Name',
                      isDense: true,
                    ),
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Item name'),
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onRemove,
                    tooltip: 'Remove item',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                    ),
                    validator: (v) =>
                        Validators.positiveNumber(v, fieldName: 'Qty'),
                    onChanged: (_) => setState(_emitChange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      isDense: true,
                    ),
                    validator: (v) => Validators.nonNegativeNumber(v,
                        fieldName: 'Price'),
                    onChanged: (_) => setState(_emitChange),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Disc. %',
                      isDense: true,
                    ),
                    validator: Validators.percentage,
                    onChanged: (_) => setState(_emitChange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Line total: ${formatCurrency(lineTotal, widget.currencySymbol)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
