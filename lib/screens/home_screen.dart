import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'invoice_list_screen.dart';
import 'settings_screen.dart';

/// Top-level shell: a bottom navigation bar switching between the three
/// main sections of the app. Uses [IndexedStack] so each tab keeps its
/// scroll position and state when switching away and back.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // GlobalKeys let us tell a tab to refresh itself (e.g. after an
  // invoice is created) without rebuilding the whole IndexedStack.
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<InvoiceListScreenState> _invoiceListKey =
      GlobalKey<InvoiceListScreenState>();

  void _onTabSelected(int index) {
    setState(() => _index = index);
    if (index == 0) {
      _dashboardKey.currentState?.refresh();
    } else if (index == 1) {
      _invoiceListKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(key: _dashboardKey),
          InvoiceListScreen(key: _invoiceListKey),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
