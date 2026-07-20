import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../utils/app_theme.dart';
import '../utils/currency_utils.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_badge.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => _loading = true);
    final stats = await _invoiceService.getDashboardStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _newInvoice() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
    );
    if (created == true) refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final symbol = settings.currency.symbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Invoice',
            onPressed: _newInvoice,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _HeroCard(
                    revenue: _stats?.totalRevenue ?? 0,
                    symbol: symbol,
                    onNewInvoice: _newInvoice,
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        label: 'Total Invoices',
                        value: '${_stats?.totalInvoices ?? 0}',
                        icon: Icons.receipt_long,
                        color: AppTheme.primaryColor,
                      ),
                      StatCard(
                        label: 'Paid Invoices',
                        value: '${_stats?.paidCount ?? 0}',
                        icon: Icons.check_circle,
                        color: AppTheme.paidColor,
                      ),
                      StatCard(
                        label: 'Unpaid Invoices',
                        value: '${_stats?.unpaidCount ?? 0}',
                        icon: Icons.hourglass_bottom,
                        color: AppTheme.unpaidColor,
                      ),
                      StatCard(
                        label: 'Overdue',
                        value: '${_stats?.overdueCount ?? 0}',
                        icon: Icons.error_outline,
                        color: AppTheme.overdueColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(
                    icon: Icons.show_chart_rounded,
                    title: 'Monthly Income Summary',
                  ),
                  const SizedBox(height: 12),
                  _MonthlySummaryCard(
                    points: _stats?.monthlySummary ?? const [],
                    symbol: symbol,
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(
                    icon: Icons.history_rounded,
                    title: 'Recent Invoices',
                  ),
                  const SizedBox(height: 12),
                  if ((_stats?.recentInvoices ?? []).isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'No invoices yet. Tap + to create your first one.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._stats!.recentInvoices.map(
                      (inv) => _RecentInvoiceTile(
                        invoice: inv,
                        symbol: symbol,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvoiceDetailScreen(invoiceId: inv.id!),
                            ),
                          );
                          refresh();
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final double revenue;
  final String symbol;
  final VoidCallback onNewInvoice;

  const _HeroCard({
    required this.revenue,
    required this.symbol,
    required this.onNewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Revenue',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(revenue, symbol),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'From all paid invoices',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNewInvoice,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 17, color: primary),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RecentInvoiceTile extends StatelessWidget {
  final Invoice invoice;
  final String symbol;
  final VoidCallback onTap;

  const _RecentInvoiceTile({
    required this.invoice,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(invoice.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_outlined, color: statusColor, size: 19),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Text(
          invoice.customerName.isEmpty ? 'No customer name' : invoice.customerName,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(invoice.grandTotal, symbol),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 4),
            StatusBadge(status: invoice.status, compact: true),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final List<MonthlyRevenuePoint> points;
  final String symbol;

  const _MonthlySummaryCard({required this.points, required this.symbol});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty || points.every((p) => p.amount == 0)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No paid invoices yet — revenue will appear here once\ninvoices are marked as Paid.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
      );
    }

    final maxAmount =
        points.map((p) => p.amount).fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: Column(
          children: points.map((point) {
            final ratio = maxAmount == 0 ? 0.0 : (point.amount / maxAmount);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      point.label,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 16,
                        backgroundColor:
                            Theme.of(context).dividerColor.withOpacity(0.4),
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 74,
                    child: Text(
                      formatCurrency(point.amount, symbol),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
