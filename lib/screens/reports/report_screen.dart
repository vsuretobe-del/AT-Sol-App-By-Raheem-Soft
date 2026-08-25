import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

enum ReportType {
  accountLedger,
  partyBalances,
  partyStatus,
  stockPosition,
  incomeExpense,
  profitLoss,
  trialBalance,
  receiptsRegister,
  paymentsRegister,
  saleRegister,
  purchaseRegister,
}

extension ReportTypeX on ReportType {
  String get title => switch (this) {
        ReportType.accountLedger => 'Account Ledger',
        ReportType.partyBalances => 'Party Balances',
        ReportType.partyStatus => 'Party Status',
        ReportType.stockPosition => 'Stock Position',
        ReportType.incomeExpense => 'Income / Expenses',
        ReportType.profitLoss => 'Profit & Loss',
        ReportType.trialBalance => 'Trial Balance',
        ReportType.receiptsRegister => 'Receipts Register',
        ReportType.paymentsRegister => 'Payments Register',
        ReportType.saleRegister => 'Sale Register',
        ReportType.purchaseRegister => 'Purchase Register',
      };

  String get endpoint => switch (this) {
        ReportType.stockPosition => AppConfig.epReportStock,
        ReportType.saleRegister || ReportType.purchaseRegister => AppConfig.epReportRegisters,
        _ => AppConfig.epReportAccounting,
      };

  String get typeParam => switch (this) {
        ReportType.accountLedger => 'account_ledger',
        ReportType.partyBalances => 'party_balances',
        ReportType.partyStatus => 'party_status',
        ReportType.stockPosition => 'stock_position',
        ReportType.incomeExpense => 'income_expenses',
        ReportType.profitLoss => 'profit_loss',
        ReportType.trialBalance => 'trial_balance',
        ReportType.receiptsRegister => 'receipts_register',
        ReportType.paymentsRegister => 'payments_register',
        ReportType.saleRegister => 'sale_invoice_register',
        ReportType.purchaseRegister => 'purchase_register',
      };
}

/// Generic report viewer with optional date range + account filter.
class ReportScreen extends StatefulWidget {
  final ReportType report;
  const ReportScreen({super.key, required this.report});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _from = DateTime(DateTime.now().year, 1, 1);
  DateTime _to = DateTime.now();
  String? _accountCode;
  List<dynamic> accounts = [];
  List<dynamic> rows = [];
  bool loading = false;
  String? error;

  bool get needsDates => widget.report != ReportType.stockPosition;

  @override
  void initState() {
    super.initState();
    if (widget.report == ReportType.accountLedger) _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final r = await ApiService.instance.get(AppConfig.epReportAccounting, {'type': 'accounts_list'});
    if (r.ok && r.data is List) setState(() => accounts = r.data as List);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _run() async {
    if (widget.report == ReportType.accountLedger && _accountCode == null) {
      showSnack(context, 'Please select an account first', error: true);
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final q = <String, String>{'type': widget.report.typeParam};
    if (needsDates) {
      q['from_date'] = _fmt(_from);
      q['to_date'] = _fmt(_to);
    }
    if (_accountCode != null) q['account_code'] = _accountCode!;
    final r = await ApiService.instance.get(widget.report.endpoint, q);
    if (!mounted) return;
    if (r.ok && r.data is List) {
      setState(() => rows = r.data as List);
    } else {
      setState(() {
        rows = [];
        error = r.message ?? 'Could not load report';
      });
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _pickDate(bool isFrom) async {
    final cur = isFrom ? _from : _to;
    final d = await showDatePicker(
        context: context, initialDate: cur, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (d == null) return;
    setState(() => isFrom ? _from = d : _to = d);
  }

  /// Numeric-looking values are right-aligned and formatted.
  Widget _valueCell(String k, String v) {
    final isNum = double.tryParse(v.replaceAll(',', '')) != null && RegExp(r'^[\d,.\-]+$').hasMatch(v);
    return Align(
      alignment: isNum ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(v,
          style: TextStyle(
              fontSize: 13.5,
              fontWeight: isNum ? FontWeight.w600 : FontWeight.w500,
              color: v.startsWith('-') ? AppTheme.danger : Colors.black87)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.report.title)),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Expanded(child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'From', isDense: true),
                        child: Text(fmtDate(_fmt(_from)))))),
                const SizedBox(width: 8),
                Expanded(child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'To', isDense: true),
                        child: Text(fmtDate(_fmt(_to)))))),
              ]),
              if (widget.report == ReportType.accountLedger) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _accountCode,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Account', isDense: true),
                  items: [
                    for (final a in accounts)
                      DropdownMenuItem(
                          value: '${a['account_code']}',
                          child: Text('${a['account_name']}', overflow: TextOverflow.ellipsis))
                  ],
                  onChanged: (v) => setState(() => _accountCode = v),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: loading ? null : _run,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Report')),
              ),
            ]),
          ),
        ),
        Expanded(
          child: loading
              ? const LoadingView()
              : error != null
                  ? ErrorRetry(message: error!, onRetry: _run)
                  : rows.isEmpty
                      ? const EmptyView(message: 'No data — run the report', icon: Icons.assessment_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: rows.length,
                          itemBuilder: (c, i) {
                            final row = (rows[i] as Map).cast<String, dynamic>();
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  for (final e in row.entries)
                                    if ('${e.value}'.isNotEmpty && e.key != 'id')
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(children: [
                                          Expanded(flex: 2, child: Text(
                                              e.key.replaceAll('_', ' ').toUpperCase(),
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
                                          Expanded(flex: 3, child: _valueCell(e.key, '${e.value}')),
                                        ]),
                                      ),
                                ]),
                              ),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}
