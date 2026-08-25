import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'sales/sales_list_screen.dart';
import 'sales/sale_form_screen.dart';
import 'sales/sale_return_screen.dart';
import 'purchases/doc_list_screen.dart';
import 'transactions/voucher_list_screen.dart';
import 'definitions/party_screen.dart';
import 'definitions/simple_def_screen.dart';
import 'definitions/item_screen.dart';
import 'reports/report_screen.dart';
import 'admin/admin_screens.dart';
import 'login_screen.dart';

class _Module {
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _Module(this.title, this.icon, this.color, this.builder);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final r = await ApiService.instance.dashboardSummary();
    if (r.ok && r.data is Map) setState(() => summary = (r.data as Map).cast<String, dynamic>());
  }

  List<_Module> _modules(BuildContext c) => [
        // ---- MAIN / TRANSACTIONS ----
        _Module('New Sale', Icons.point_of_sale, const Color(0xFF1565C0),
            (_) => const SaleFormScreen()),
        _Module('Sales', Icons.receipt_long, const Color(0xFF2E7D32),
            (_) => const SalesListScreen()),
        _Module('Sales Returns', Icons.assignment_return, const Color(0xFF6A1B9A),
            (_) => const SaleReturnScreen()),
        _Module('Purchases', Icons.shopping_cart, const Color(0xFFE65100),
            (_) => const DocListScreen(doc: DocType.purchase)),
        _Module('Purchase Orders', Icons.pending_actions, const Color(0xFF00838F),
            (_) => const DocListScreen(doc: DocType.order)),
        _Module('Purchase Returns', Icons.assignment_return_outlined, const Color(0xFFAD1457),
            (_) => const DocListScreen(doc: DocType.purReturn)),
        _Module('Vouchers', Icons.account_balance_wallet, const Color(0xFF4527A0),
            (_) => const VoucherListScreen()),
        // ---- DEFINITIONS ----
        _Module('Customers', Icons.people_alt, const Color(0xFF283593),
            (_) => const PartyScreen(kind: PartyKind.customer)),
        _Module('Suppliers', Icons.local_shipping, const Color(0xFF37474F),
            (_) => const PartyScreen(kind: PartyKind.supplier)),
        _Module('Dealers', Icons.storefront, const Color(0xFF00695C),
            (_) => const PartyScreen(kind: PartyKind.dealer)),
        _Module('Items', Icons.inventory_2, const Color(0xFF9E9D24), (_) => const ItemsScreen()),
        _Module('Item Groups', Icons.category, const Color(0xFF8D6E63),
            (_) => SimpleDefScreen(cfg: DefConfig.itemGroups)),
        _Module('Godowns', Icons.warehouse, const Color(0xFF4E342E),
            (_) => SimpleDefScreen(cfg: DefConfig.godowns)),
        _Module('Transporters', Icons.local_taxi, const Color(0xFF455A64),
            (_) => SimpleDefScreen(cfg: DefConfig.transporters)),
        _Module('Areas', Icons.location_on, const Color(0xFF2E7D32),
            (_) => SimpleDefScreen(cfg: DefConfig.areas)),
        _Module('Zones', Icons.map, const Color(0xFF558B2F),
            (_) => SimpleDefScreen(cfg: DefConfig.zones)),
        _Module('Measurements', Icons.straighten, const Color(0xFF6D4C41),
            (_) => SimpleDefScreen(cfg: DefConfig.measurements)),
        _Module('Sale Types', Icons.sell, const Color(0xFFBF360C),
            (_) => SimpleDefScreen(cfg: DefConfig.saleTypes)),
        _Module('Bank Accounts', Icons.account_balance, const Color(0xFF0277BD),
            (_) => SimpleDefScreen(cfg: DefConfig.bankAccounts)),
        _Module('Cash Accounts', Icons.payments, const Color(0xFF2E7D32),
            (_) => SimpleDefScreen(cfg: DefConfig.cashAccounts)),
        // ---- REPORTS ----
        _Module('Account Ledger', Icons.menu_book, const Color(0xFF4527A0),
            (_) => const ReportScreen(report: ReportType.accountLedger)),
        _Module('Party Balances', Icons.balance, const Color(0xFF00695C),
            (_) => const ReportScreen(report: ReportType.partyBalances)),
        _Module('Stock Position', Icons.inventory, const Color(0xFFEF6C00),
            (_) => const ReportScreen(report: ReportType.stockPosition)),
        _Module('Income/Expenses', Icons.trending_up, const Color(0xFF2E7D32),
            (_) => const ReportScreen(report: ReportType.incomeExpense)),
        _Module('Receipts Register', Icons.receipt, const Color(0xFF1565C0),
            (_) => const ReportScreen(report: ReportType.receiptsRegister)),
        _Module('Payments Register', Icons.payment, const Color(0xFFC62828),
            (_) => const ReportScreen(report: ReportType.paymentsRegister)),
      ];

  @override
  Widget build(BuildContext context) {
    final api = ApiService.instance;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(summary?['company_name'] ?? 'AT Sol',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          Text('${api.currentUser?['full_name'] ?? ''} • ${api.currentUser?['role'] ?? ''}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400, color: Colors.white70)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Change Password',
            icon: const Icon(Icons.password),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          if (api.isAdmin)
            IconButton(
              tooltip: 'User Management',
              icon: const Icon(Icons.manage_accounts),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const UsersScreen())),
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.instance.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.brand,
        onRefresh: _loadSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _statsGrid(),
            SectionHeader('Transactions'),
            _moduleGrid(_modules(context).sublist(0, 7)),
            SectionHeader('Definitions'),
            _moduleGrid(_modules(context).sublist(7, 19)),
            SectionHeader('Reports'),
            _moduleGrid(_modules(context).sublist(19)),
            const SizedBox(height: 10),
            Center(child: Text('AT Sol Mobile v1.0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 5),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        FittedBox(child: Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  Widget _statsGrid() {
    final s = summary ?? {};
    String n(String k) => '${s[k] ?? 0}';
    String m(String k) => fmtMoney(s[k] ?? 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.75,
        children: [
          _statCard('Today\'s Sales', m('today_sales'), Icons.today, const Color(0xFF2E7D32)),
          _statCard('Month Sales', m('month_sales'), Icons.calendar_month, const Color(0xFF1565C0)),
          _statCard('Month Purchases', m('month_purchases'), Icons.local_mall, const Color(0xFFE65100)),
          _statCard('Invoices', n('sales_count'), Icons.receipt_long, const Color(0xFF6A1B9A)),
          _statCard('Vouchers', n('vouchers_count'), Icons.account_balance_wallet, const Color(0xFF4527A0)),
          _statCard('Customers', n('customers'), Icons.people, const Color(0xFF00838F)),
          _statCard('Suppliers', n('suppliers'), Icons.local_shipping, const Color(0xFF37474F)),
          _statCard('Items', n('items'), Icons.inventory_2, const Color(0xFF9E9D24)),
        ],
      ),
    );
  }

  Widget _moduleGrid(List<_Module> mods) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        padding: EdgeInsets.zero,
        children: [
          for (final m in mods)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: m.builder)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: m.color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(m.icon, color: m.color, size: 26),
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(m.title, textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
