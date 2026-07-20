import '../database/db_helper.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import 'settings_service.dart';

/// A quick month-by-month revenue point, used for the dashboard's
/// monthly income summary.
class MonthlyRevenuePoint {
  final String label; // e.g. "Jan 2026"
  final double amount;
  MonthlyRevenuePoint(this.label, this.amount);
}

/// Aggregate numbers shown on the Dashboard screen.
class DashboardStats {
  final int totalInvoices;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final double totalRevenue;
  final List<Invoice> recentInvoices;
  final List<MonthlyRevenuePoint> monthlySummary;

  DashboardStats({
    required this.totalInvoices,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.totalRevenue,
    required this.recentInvoices,
    required this.monthlySummary,
  });
}

/// Sits between the UI and [DBHelper]: this is where business rules
/// live (auto-numbering, duplication behavior, stats aggregation)
/// so screens stay focused on presentation.
class InvoiceService {
  final DBHelper _db = DBHelper.instance;

  Future<List<Invoice>> getAllInvoices() => _db.getAllInvoices();

  Future<Invoice?> getInvoiceById(int id) => _db.getInvoiceById(id);

  Future<List<Invoice>> search(String query) {
    if (query.trim().isEmpty) return _db.getAllInvoices();
    return _db.searchInvoices(query.trim());
  }

  Future<List<Invoice>> filterByStatus(String? status) async {
    final all = await _db.getAllInvoices();
    if (status == null || status == 'All') return all;
    return all.where((inv) => inv.status == status).toList();
  }

  Future<int> createInvoice(Invoice invoice) => _db.insertInvoice(invoice);

  Future<int> updateInvoice(Invoice invoice) => _db.updateInvoice(invoice);

  Future<int> deleteInvoice(int id) => _db.deleteInvoice(id);

  Future<int> updateStatus(Invoice invoice, String newStatus) {
    invoice.status = newStatus;
    return _db.updateInvoice(invoice);
  }

  /// Creates a copy of [source] as a brand-new invoice: fresh invoice
  /// number, fresh line-item IDs, dates reset to today (due in 30 days),
  /// and status reset to Unpaid — because a duplicate represents a new
  /// bill, not a copy of an already-settled one.
  Future<Invoice> duplicateInvoice(
      Invoice source, SettingsService settings) async {
    final newNumber = await settings.commitNextInvoiceNumber();
    final now = DateTime.now();

    final newItems = source.items
        .map((item) => InvoiceItem(
              id: _newItemId(),
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              discountPercent: item.discountPercent,
            ))
        .toList();

    // Built directly (not via copyWith) because copyWith's `value ?? this.x`
    // pattern can't express "explicitly clear id to null" — passing
    // id: null there would silently fall back to source's original id.
    final duplicate = Invoice(
      id: null,
      invoiceNumber: newNumber,
      invoiceDate: now,
      dueDate: now.add(const Duration(days: 30)),
      businessName: source.businessName,
      businessAddress: source.businessAddress,
      businessEmail: source.businessEmail,
      businessPhone: source.businessPhone,
      customerName: source.customerName,
      customerAddress: source.customerAddress,
      customerEmail: source.customerEmail,
      customerPhone: source.customerPhone,
      items: newItems,
      taxPercent: source.taxPercent,
      notes: source.notes,
      status: 'Unpaid',
      createdAt: now,
    );

    final newId = await _db.insertInvoice(duplicate);
    duplicate.id = newId;
    return duplicate;
  }

  String _newItemId() =>
      'item_${DateTime.now().microsecondsSinceEpoch}_${(DateTime.now().hashCode % 10000)}';

  Future<DashboardStats> getDashboardStats() async {
    final all = await _db.getAllInvoices();

    final paid = all.where((i) => i.status == 'Paid').toList();
    final unpaid = all.where((i) => i.status == 'Unpaid').toList();
    final overdue = all.where((i) => i.status == 'Overdue').toList();

    final totalRevenue =
        paid.fold(0.0, (sum, inv) => sum + inv.grandTotal);

    final recent = List<Invoice>.from(all)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final monthly = _buildMonthlySummary(paid);

    return DashboardStats(
      totalInvoices: all.length,
      paidCount: paid.length,
      unpaidCount: unpaid.length,
      overdueCount: overdue.length,
      totalRevenue: totalRevenue,
      recentInvoices: recent.take(5).toList(),
      monthlySummary: monthly,
    );
  }

  /// Builds a revenue-by-month series for the last 6 months (oldest
  /// first), based on paid invoices' invoice date.
  List<MonthlyRevenuePoint> _buildMonthlySummary(List<Invoice> paidInvoices) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final now = DateTime.now();
    final buckets = <String, double>{};
    final orderedKeys = <String>[];

    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = '${d.year}-${d.month}';
      buckets[key] = 0;
      orderedKeys.add(key);
    }

    for (final inv in paidInvoices) {
      final key = '${inv.invoiceDate.year}-${inv.invoiceDate.month}';
      if (buckets.containsKey(key)) {
        buckets[key] = (buckets[key] ?? 0) + inv.grandTotal;
      }
    }

    return orderedKeys.map((key) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final label = '${monthNames[month - 1]} $year';
      return MonthlyRevenuePoint(label, buckets[key] ?? 0);
    }).toList();
  }
}
