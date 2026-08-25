import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'voucher_form_screen.dart';

/// All accounting vouchers with type filter.
class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});
  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  List<dynamic> all = [];
  List<dynamic> shown = [];
  String? filterType;
  bool loading = true;
  final search = TextEditingController();

  static const types = [
    'Journal General',
    'Cash Payment',
    'Cash Receipt',
    'Bank Payment',
    'Bank Receipt',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      all = await ApiService.instance.transactions();
      _apply();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  void _apply() {
    Iterable<dynamic> it = all;
    if (filterType != null) it = it.where((t) => '${t['type']}'.contains(filterType!));
    final q = search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      it = it.where((row) =>
          row is Map<String, dynamic> && row.values.any((v) => '$v'.toLowerCase().contains(q)));
    }
    setState(() => shown = it.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vouchers')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Voucher'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const VoucherFormScreen()));
          _load();
        },
      ),
      body: Column(children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: filterType == null,
                onSelected: (_) { filterType = null; _apply(); },
              ),
              for (final t in types)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: filterType == t,
                    onSelected: (_) { filterType = t; _apply(); },
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: search,
            onChanged: (_) => _apply(),
            decoration: InputDecoration(hintText: 'Search…', prefixIcon: const Icon(Icons.search), isDense: true),
          ),
        ),
        Expanded(
          child: loading
              ? const LoadingView()
              : shown.isEmpty
                  ? const EmptyView(message: 'No vouchers found')
                  : RefreshIndicator(
                      color: AppTheme.brand,
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: shown.length,
                        itemBuilder: (c, i) {
                          final t = (shown[i] as Map).cast<String, dynamic>();
                          final items = (t['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                          return Card(
                            child: ListTile(
                              onTap: () => showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (_) => _VoucherDetail(t: t, items: items),
                              ),
                              title: Text('#${t['voucher_no'] ?? ''} • ${t['type'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${fmtDate(t['date']?.toString())} • ${items.length} entries'),
                              trailing: Text('Rs ${fmtMoney(t['total_dr'])}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _VoucherDetail extends StatelessWidget {
  final Map<String, dynamic> t;
  final List<Map<String, dynamic>> items;
  const _VoucherDetail({required this.t, required this.items});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      builder: (c, controller) => ListView(controller: controller, padding: const EdgeInsets.all(18), children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Text('Voucher #${t['voucher_no'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${t['type'] ?? ''} • ${fmtDate(t['date']?.toString())}', style: TextStyle(color: Colors.grey.shade600)),
        if ('${t['description'] ?? ''}'.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('${t['description']}'),
        ],
        const Divider(height: 26),
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
          children: [
            TableRow(decoration: BoxDecoration(color: Colors.grey.shade100), children: [
              padded('Account', bold: true), padded('Dr', bold: true), padded('Cr', bold: true)]),
            ...items.map((it) => TableRow(children: [
                  padded('${it['account_name'] ?? ''}'),
                  padded(it['amount_dr'].toString() == '0' || it['amount_dr'] == null ? '' : fmtMoney(it['amount_dr'])),
                  padded(it['amount_cr'].toString() == '0' || it['amount_cr'] == null ? '' : fmtMoney(it['amount_cr'])),
                ])),
            TableRow(children: [
              padded('Total', bold: true),
              padded(fmtMoney(t['total_dr']), bold: true),
              padded(fmtMoney(t['total_cr']), bold: true),
            ]),
          ],
        ),
      ]),
    );
  }

  Widget padded(String s, {bool bold = false}) => Padding(
      padding: const EdgeInsets.all(8),
      child: Text(s, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)));
}
