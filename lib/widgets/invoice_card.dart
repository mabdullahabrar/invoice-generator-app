import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import 'status_badge.dart';

enum InvoiceCardAction { edit, duplicate, delete, markPaid, markUnpaid, markOverdue }

/// A single invoice row in the invoice list, with a quick-actions menu.
class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String currencySymbol;
  final VoidCallback onTap;
  final void Function(InvoiceCardAction action) onAction;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.currencySymbol,
    required this.onTap,
    required this.onAction,
  });

  String get _initials {
    final name = invoice.customerName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final statusColor = AppTheme.statusColor(invoice.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            invoice.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: invoice.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      invoice.customerName.isEmpty
                          ? 'No customer name'
                          : invoice.customerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Due ${dateFormat.format(invoice.dueDate)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(invoice.grandTotal, currencySymbol),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  PopupMenuButton<InvoiceCardAction>(
                    onSelected: onAction,
                    icon: const Icon(Icons.more_vert, size: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: InvoiceCardAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: InvoiceCardAction.duplicate,
                        child: Text('Duplicate'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: InvoiceCardAction.markPaid,
                        child: Text('Mark as Paid'),
                      ),
                      PopupMenuItem(
                        value: InvoiceCardAction.markUnpaid,
                        child: Text('Mark as Unpaid'),
                      ),
                      PopupMenuItem(
                        value: InvoiceCardAction.markOverdue,
                        child: Text('Mark as Overdue'),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: InvoiceCardAction.delete,
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
