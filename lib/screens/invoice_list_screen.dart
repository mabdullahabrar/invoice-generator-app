import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/invoice_card.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => InvoiceListScreenState();
}

class InvoiceListScreenState extends State<InvoiceListScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final TextEditingController _searchController = TextEditingController();

  List<Invoice> _invoices = [];
  bool _loading = true;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() => _loading = true);
    final query = _searchController.text.trim();
    List<Invoice> results;
    if (query.isNotEmpty) {
      results = await _invoiceService.search(query);
      if (_statusFilter != 'All') {
        results = results.where((i) => i.status == _statusFilter).toList();
      }
    } else {
      results = await _invoiceService.filterByStatus(_statusFilter);
    }
    if (!mounted) return;
    setState(() {
      _invoices = results;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(Invoice invoice) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${invoice.invoiceNumber} deleted')),
      );
      refresh();
    }
  }

  Future<void> _handleAction(
      InvoiceCardAction action, Invoice invoice) async {
    final settings = context.read<SettingsService>();
    switch (action) {
      case InvoiceCardAction.edit:
        final updated = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => InvoiceFormScreen(invoiceToEdit: invoice),
          ),
        );
        if (updated == true) refresh();
        break;
      case InvoiceCardAction.duplicate:
        await _invoiceService.duplicateInvoice(invoice, settings);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice duplicated')),
        );
        refresh();
        break;
      case InvoiceCardAction.delete:
        await _confirmDelete(invoice);
        break;
      case InvoiceCardAction.markPaid:
        await _invoiceService.updateStatus(invoice, 'Paid');
        refresh();
        break;
      case InvoiceCardAction.markUnpaid:
        await _invoiceService.updateStatus(invoice, 'Unpaid');
        refresh();
        break;
      case InvoiceCardAction.markOverdue:
        await _invoiceService.updateStatus(invoice, 'Overdue');
        refresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final symbol = settings.currency.symbol;
    final hasSearch = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
          );
          if (created == true) refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by invoice number or customer name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasSearch
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          refresh();
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => refresh(),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _statusFilter == 'All',
                  onSelected: () {
                    setState(() => _statusFilter = 'All');
                    refresh();
                  },
                ),
                _FilterChip(
                  label: 'Paid',
                  selected: _statusFilter == 'Paid',
                  onSelected: () {
                    setState(() => _statusFilter = 'Paid');
                    refresh();
                  },
                ),
                _FilterChip(
                  label: 'Unpaid',
                  selected: _statusFilter == 'Unpaid',
                  onSelected: () {
                    setState(() => _statusFilter = 'Unpaid');
                    refresh();
                  },
                ),
                _FilterChip(
                  label: 'Overdue',
                  selected: _statusFilter == 'Overdue',
                  onSelected: () {
                    setState(() => _statusFilter = 'Overdue');
                    refresh();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? EmptyState(
                        icon: hasSearch
                            ? Icons.search_off
                            : Icons.receipt_long_outlined,
                        title: hasSearch
                            ? 'No matching invoices'
                            : 'No invoices yet',
                        message: hasSearch
                            ? 'Try a different invoice number or customer name.'
                            : 'Create your first invoice to get started.',
                        actionLabel: hasSearch ? null : 'Create Invoice',
                        onAction: hasSearch
                            ? null
                            : () async {
                                final created =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const InvoiceFormScreen(),
                                  ),
                                );
                                if (created == true) refresh();
                              },
                      )
                    : RefreshIndicator(
                        onRefresh: refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _invoices[index];
                            return Dismissible(
                              key: ValueKey(invoice.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete invoice?'),
                                    content: Text(
                                      'This will permanently delete invoice '
                                      '${invoice.invoiceNumber}.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true && invoice.id != null) {
                                  await _invoiceService
                                      .deleteInvoice(invoice.id!);
                                  return true;
                                }
                                return false;
                              },
                              onDismissed: (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invoice ${invoice.invoiceNumber} deleted',
                                    ),
                                  ),
                                );
                                refresh();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InvoiceCard(
                                  invoice: invoice,
                                  currencySymbol: symbol,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => InvoiceDetailScreen(
                                          invoiceId: invoice.id!,
                                        ),
                                      ),
                                    );
                                    refresh();
                                  },
                                  onAction: (action) =>
                                      _handleAction(action, invoice),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
